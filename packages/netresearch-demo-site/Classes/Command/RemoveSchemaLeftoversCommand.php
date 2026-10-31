<?php

declare(strict_types=1);

namespace Netresearch\DemoSite\Command;

use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Yaml\Yaml;
use Throwable;
use TYPO3\CMS\Core\Database\ConnectionPool;
use TYPO3\CMS\Core\Database\Schema\SchemaMigrator;
use TYPO3\CMS\Core\Database\Schema\SqlReader;
use TYPO3\CMS\Core\Utility\GeneralUtility;

/**
 * Removes the tables, columns and indexes named in
 * Configuration/InstallTool/schema-leftovers.yaml, through the same statements
 * Maintenance > Analyze Database Structure offers for them.
 *
 * Core removes in two steps: a table or column is first renamed with the
 * zzz_deleted_ prefix, and a later comparison offers to drop the renamed
 * object. Indexes are dropped right away. This command runs both steps in
 * one go:
 *
 *  1. drop the listed indexes (first, because MariaDB removes an index on its
 *     own when the column it covers is dropped)
 *  2. rename the listed tables and columns
 *  3. drop the zzz_deleted_ copies of the listed tables and columns, and of
 *     nothing else
 *
 * Before each step the core schema comparison runs again, and a statement is
 * executed only when it is one of core's removal suggestions AND names an
 * object on the list. An object that is on the list but no longer suggested
 * for removal - because an installed package defines it again - is left alone
 * and reported. A second run finds nothing to do and says so.
 */
#[AsCommand(
    name: 'demo:schema:remove-leftovers',
    description: 'Remove the listed schema leftovers that Analyze Database Structure suggests removing.',
)]
final class RemoveSchemaLeftoversCommand extends Command
{
    private const PREFIX = 'zzz_deleted_';

    public function __construct(
        private readonly SchemaMigrator $schemaMigrator,
        private readonly SqlReader $sqlReader,
        private readonly ConnectionPool $connectionPool,
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addOption(
                'list',
                null,
                InputOption::VALUE_REQUIRED,
                'YAML file with the tables, columns and indexes to remove',
                'EXT:netresearch_demo_site/Configuration/InstallTool/schema-leftovers.yaml',
            )
            ->addOption('dry-run', null, InputOption::VALUE_NONE, 'Print the statements that would run now, without executing anything');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        try {
            $list = $this->loadList((string)$input->getOption('list'));
        } catch (Throwable $e) {
            $output->writeln('<error>Cannot read the list: ' . $e->getMessage() . '</error>');
            return Command::INVALID;
        }
        $dryRun = (bool)$input->getOption('dry-run');
        $statements = $this->sqlReader->getCreateTableStatementArray($this->sqlReader->getTablesDefinitionString());

        /** @var array<string, string> $removed object key => what happened */
        $removed = [];
        $failed = 0;
        $steps = [
            'drop index' => fn(array $p): bool => $p['kind'] === 'drop-index',
            'rename' => fn(array $p): bool => $p['kind'] === 'rename-table' || $p['kind'] === 'rename-column',
            'drop renamed' => fn(array $p): bool => $p['kind'] === 'drop-table' || $p['kind'] === 'drop-column',
        ];
        foreach ($steps as $step => $belongsToStep) {
            // In a dry run the third step lists only zzz_deleted_ copies that
            // exist already: the others appear once the rename has run.
            $selected = array_filter($this->listedSuggestions($statements, $list), $belongsToStep);
            foreach ($selected as $hash => $suggestion) {
                $output->writeln(sprintf(
                    '%s %s: %s%s',
                    $dryRun ? 'would run' : 'running',
                    $step,
                    $suggestion['statement'],
                    $suggestion['rows'] !== null ? ' (' . $suggestion['rows'] . ' rows)' : '',
                ));
            }
            if ($dryRun || $selected === []) {
                continue;
            }
            $errors = $this->schemaMigrator->migrate($statements, array_fill_keys(array_keys($selected), true));
            foreach ($selected as $hash => $suggestion) {
                if (isset($errors[$hash])) {
                    $failed++;
                    $output->writeln(sprintf('<error>FAILED %s: %s -- %s</error>', $step, $suggestion['statement'], $errors[$hash]));
                    continue;
                }
                $removed[$suggestion['object']] = $step;
            }
        }

        // Every listed object that is not acted on above is accounted for here:
        // gone already, or still there and no longer a removal suggestion.
        $remaining = $dryRun ? [] : $this->listedSuggestions($statements, $list);
        $stillSuggested = [];
        foreach ($remaining as $suggestion) {
            $stillSuggested[$suggestion['object']] = true;
        }
        $wouldRemove = [];
        if ($dryRun) {
            foreach ($this->listedSuggestions($statements, $list) as $suggestion) {
                $wouldRemove[$suggestion['object']] = true;
            }
        }
        $absent = 0;
        $kept = 0;
        foreach ($this->listedObjects($list) as $object => [$type, $table, $name]) {
            if (isset($removed[$object]) || isset($wouldRemove[$object])) {
                continue;
            }
            if (isset($stillSuggested[$object])) {
                $failed++;
                $output->writeln(sprintf('<error>FAILED %s is still a removal suggestion after the run</error>', $object));
                continue;
            }
            if ($this->exists($type, $table, $name)) {
                $kept++;
                $output->writeln(sprintf('WARNING kept %s: it is on the list, but the core schema comparison does not suggest removing it (an installed package defines it)', $object));
                continue;
            }
            $absent++;
        }

        $dropped = $dryRun ? count($wouldRemove) : count(array_filter($removed, static fn(string $step): bool => $step !== 'rename'));
        $output->writeln(sprintf(
            '%s: %d of %d listed objects %s, %d already absent, %d kept, %d failed.',
            $dryRun ? 'Dry run' : 'Schema leftovers',
            $dropped,
            count($this->listedObjects($list)),
            $dryRun ? 'would be removed' : 'removed',
            $absent,
            $kept,
            $failed,
        ));
        if (!$dryRun && $dropped === 0 && $failed === 0) {
            $output->writeln('Nothing to do: no listed object is a removal suggestion any more.');
        }
        return $failed === 0 ? Command::SUCCESS : Command::FAILURE;
    }

    /**
     * Core's current removal suggestions that name a listed object, keyed by
     * the statement hash migrate() selects by.
     *
     * @param list<string> $statements
     * @param array{tables: array<string, true>, columns: array<string, array<string, true>>, indexes: array<string, array<string, true>>} $list
     * @return array<string, array{kind: string, object: string, statement: string, rows: ?int}>
     */
    private function listedSuggestions(array $statements, array $list): array
    {
        $selected = [];
        foreach ($this->schemaMigrator->getUpdateSuggestions($statements, true) as $suggestions) {
            $rows = $suggestions['tables_count'] ?? [];
            foreach (['change', 'change_table', 'drop', 'drop_table'] as $category) {
                foreach ($suggestions[$category] ?? [] as $hash => $statement) {
                    $parsed = $this->parse((string)$statement);
                    if ($parsed === null || !$this->isListed($list, $parsed['type'], $parsed['table'], $parsed['name'])) {
                        continue;
                    }
                    $selected[$hash] = [
                        'kind' => $parsed['kind'],
                        'object' => $this->objectKey($parsed['type'], $parsed['table'], $parsed['name']),
                        'statement' => (string)$statement,
                        'rows' => isset($rows[$hash]) && $rows[$hash] !== '' ? (int)$rows[$hash] : null,
                    ];
                }
            }
        }
        return $selected;
    }

    /**
     * Reads the object a removal statement acts on. The statements come from
     * Doctrine's MySQL platform, which quotes every identifier with backticks;
     * a rename of a column also carries its type, so only the names are read.
     *
     * @return array{kind: string, type: string, table: string, name: string}|null
     */
    private function parse(string $statement): ?array
    {
        $p = preg_quote(self::PREFIX, '/');
        return match (true) {
            preg_match('/^DROP INDEX `([^`]+)` ON `([^`]+)`$/', $statement, $m) === 1
                => ['kind' => 'drop-index', 'type' => 'index', 'table' => $m[2], 'name' => $m[1]],
            preg_match('/^ALTER TABLE `([^`]+)` RENAME TO `' . $p . '\1`$/', $statement, $m) === 1
                => ['kind' => 'rename-table', 'type' => 'table', 'table' => $m[1], 'name' => $m[1]],
            preg_match('/^ALTER TABLE `([^`]+)` CHANGE `([^`]+)` `' . $p . '\2` /', $statement, $m) === 1
                => ['kind' => 'rename-column', 'type' => 'column', 'table' => $m[1], 'name' => $m[2]],
            preg_match('/^DROP TABLE `' . $p . '([^`]+)`$/', $statement, $m) === 1
                => ['kind' => 'drop-table', 'type' => 'table', 'table' => $m[1], 'name' => $m[1]],
            preg_match('/^ALTER TABLE `([^`]+)` DROP `' . $p . '([^`]+)`$/', $statement, $m) === 1
                => ['kind' => 'drop-column', 'type' => 'column', 'table' => $m[1], 'name' => $m[2]],
            default => null,
        };
    }

    /**
     * @param array{tables: array<string, true>, columns: array<string, array<string, true>>, indexes: array<string, array<string, true>>} $list
     */
    private function isListed(array $list, string $type, string $table, string $name): bool
    {
        // MariaDB compares column and index names case-insensitively.
        return match ($type) {
            'table' => isset($list['tables'][$table]),
            'column' => isset($list['columns'][$table][strtolower($name)]),
            'index' => isset($list['indexes'][$table][strtolower($name)]),
            default => false,
        };
    }

    /**
     * @param array{tables: array<string, true>, columns: array<string, array<string, true>>, indexes: array<string, array<string, true>>} $list
     * @return array<string, array{0: string, 1: string, 2: string}>
     */
    private function listedObjects(array $list): array
    {
        $objects = [];
        foreach (array_keys($list['tables']) as $table) {
            $objects[$this->objectKey('table', $table, $table)] = ['table', $table, $table];
        }
        foreach (['columns' => 'column', 'indexes' => 'index'] as $key => $type) {
            foreach ($list[$key] as $table => $names) {
                foreach (array_keys($names) as $name) {
                    $objects[$this->objectKey($type, $table, $name)] = [$type, $table, $name];
                }
            }
        }
        return $objects;
    }

    private function objectKey(string $type, string $table, string $name): string
    {
        return $type === 'table' ? 'table ' . $table : $type . ' ' . $table . '.' . strtolower($name);
    }

    /**
     * Whether the object, or its zzz_deleted_ copy, is still in the database.
     */
    private function exists(string $type, string $table, string $name): bool
    {
        $connection = $this->connectionPool->getConnectionForTable($table);
        $schemaManager = $connection->createSchemaManager();
        if ($type === 'table') {
            return $schemaManager->tablesExist([$table]) || $schemaManager->tablesExist([self::PREFIX . $table]);
        }
        if (!$schemaManager->tablesExist([$table])) {
            return false;
        }
        $names = array_map(
            'strtolower',
            $type === 'column'
                ? array_map(static fn($c): string => $c->getName(), $schemaManager->listTableColumns($table))
                : array_map(static fn($i): string => $i->getName(), $schemaManager->listTableIndexes($table)),
        );
        return in_array(strtolower($name), $names, true)
            || ($type === 'column' && in_array(strtolower(self::PREFIX . $name), $names, true));
    }

    /**
     * @return array{tables: array<string, true>, columns: array<string, array<string, true>>, indexes: array<string, array<string, true>>}
     */
    private function loadList(string $path): array
    {
        $file = str_starts_with($path, 'EXT:') ? GeneralUtility::getFileAbsFileName($path) : $path;
        if ($file === '' || !is_file($file)) {
            throw new \RuntimeException(sprintf('"%s" does not exist', $path), 1793530001);
        }
        $data = Yaml::parseFile($file);
        if (!is_array($data)) {
            throw new \RuntimeException(sprintf('"%s" is not a YAML mapping', $path), 1793530002);
        }
        $list = ['tables' => [], 'columns' => [], 'indexes' => []];
        foreach ((array)($data['tables'] ?? []) as $table) {
            if (!is_string($table) || preg_match('/^\w+$/', $table) !== 1) {
                throw new \RuntimeException(sprintf('tables: "%s" is not a table name', (string)json_encode($table)), 1793530003);
            }
            $list['tables'][$table] = true;
        }
        foreach (['columns', 'indexes'] as $key) {
            foreach ((array)($data[$key] ?? []) as $table => $names) {
                if (!is_string($table) || preg_match('/^\w+$/', $table) !== 1 || !is_array($names)) {
                    throw new \RuntimeException(sprintf('%s: entry "%s" needs a table name and a list of names', $key, (string)$table), 1793530004);
                }
                foreach ($names as $name) {
                    if (!is_string($name) || preg_match('/^\w+$/', $name) !== 1) {
                        throw new \RuntimeException(sprintf('%s.%s: "%s" is not a name', $key, $table, (string)json_encode($name)), 1793530005);
                    }
                    $list[$key][$table][strtolower($name)] = true;
                }
            }
        }
        if ($list['tables'] === [] && $list['columns'] === [] && $list['indexes'] === []) {
            throw new \RuntimeException(sprintf('"%s" lists nothing', $path), 1793530006);
        }
        return $list;
    }
}
