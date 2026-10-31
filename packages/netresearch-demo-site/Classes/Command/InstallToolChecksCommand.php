<?php

declare(strict_types=1);

namespace Netresearch\DemoSite\Command;

use GuzzleHttp\Client;
use GuzzleHttp\Exception\TransferException;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Process\ExecutableFinder;
use Symfony\Component\Process\Process;
use Symfony\Component\Yaml\Yaml;
use Throwable;
use TYPO3\CMS\Backend\Routing\UriBuilder;
use TYPO3\CMS\Core\Core\Environment;
use TYPO3\CMS\Core\Core\SystemEnvironmentBuilder;
use TYPO3\CMS\Core\Database\Schema\SchemaMigrator;
use TYPO3\CMS\Core\Database\Schema\SqlReader;
use TYPO3\CMS\Core\Http\NormalizedParams;
use TYPO3\CMS\Core\Http\ServerRequest;
use TYPO3\CMS\Core\Imaging\GraphicalFunctions;
use TYPO3\CMS\Core\Messaging\FlashMessage;
use TYPO3\CMS\Core\Middleware\VerifyHostHeader;
use TYPO3\CMS\Core\Type\ContextualFeedbackSeverity;
use TYPO3\CMS\Core\Utility\ExtensionManagementUtility;
use TYPO3\CMS\Core\Utility\GeneralUtility;
use TYPO3\CMS\Core\Utility\StringUtility;
use TYPO3\CMS\Install\FolderStructure\DefaultFactory;
use TYPO3\CMS\Install\FolderStructure\DefaultPermissionsCheck;
use TYPO3\CMS\Install\SystemEnvironment\Check;
use TYPO3\CMS\Install\SystemEnvironment\DatabaseCheck;
use TYPO3\CMS\Install\SystemEnvironment\SetupCheck;
use TYPO3\CMS\Install\WebserverType;

/**
 * Runs the checks behind four views of the Install Tool from the command line,
 * so that a deploy reports what the backend would show:
 *
 * - Environment > Environment Status: Check, SetupCheck, DatabaseCheck and
 *   ServerResponseCheck, as EnvironmentController::environmentCheckGetStatusAction
 * - Environment > Directory Status: the DefaultFactory folder structure and the
 *   two create-mask checks, as folderStructureGetStatusAction
 * - Maintenance > Analyze Database Structure: SchemaMigrator::getUpdateSuggestions
 *   with and without removals, as MaintenanceController::databaseAnalyzerAnalyzeAction
 * - Environment > Image Processing: the read/write/scale/convert tests of the
 *   controller, with the same input files and GraphicalFunctions calls
 *
 * Core ships no command for any of them (`database:updateschema` belongs to
 * typo3-console, which this project does not install), hence this one.
 *
 * Nothing is changed: the schema comparison never calls migrate() or
 * install(). Three checks write temporary files and remove them again, exactly
 * as they do in the backend: the server response probe (typo3temp/assets and
 * fileadmin), the directory check (an installToolTest_* file in every
 * directory it tests for writability) and the image tests
 * (typo3temp/assets/images).
 *
 * Image Processing covers the ImageMagick read, write, scale and convert tests.
 * The view's TrueType, combine-mask and GDlib tests are not run: they produce
 * images that only a person comparing them with the reference can judge, and
 * Environment Status already checks GD and FreeType.
 *
 * The backend runs these checks under php-fpm, this command under the CLI SAPI.
 * Core skips the trusted-hosts comparison on the CLI and treats the CLI's
 * forced max_execution_time=0 as fine, so both are evaluated here for the FPM
 * side, and every php.ini directive the checks read is compared between the
 * two SAPIs. A difference is reported, because then this output and the
 * backend can disagree. `php-fpm -i` does not show pool-level php_value or
 * php_admin_value settings; docker/web/php-fpm.conf sets none.
 *
 * A finding at or above the severity floor that the allowlist does not cover
 * makes the command exit 1. The allowlist documents each expected finding.
 */
#[AsCommand(
    name: 'demo:install-tool:check',
    description: 'Report the findings of the Install Tool environment, directory, database and image checks.',
)]
final class InstallToolChecksCommand extends Command
{
    /** Same list as EnvironmentController::IMAGE_FILE_EXT. */
    private const IMAGE_FILE_EXT = ['gif', 'jpg', 'png', 'tif', 'ai', 'pdf', 'webp', 'avif'];

    /** The php.ini directives Check, SetupCheck and OpcodeCacheService read. */
    private const SAPI_DIRECTIVES = [
        'allow_url_fopen', 'disable_functions', 'doc_root', 'file_uploads', 'include_path',
        'max_input_vars', 'memory_limit', 'opcache.enable', 'open_basedir', 'post_max_size',
        'upload_max_filesize', 'xdebug.max_nesting_level',
    ];

    /** In the order of ContextualFeedbackSeverity's values: NOTICE -2 … ERROR 2. */
    private const FLOORS = [
        'notice' => ContextualFeedbackSeverity::NOTICE,
        'info' => ContextualFeedbackSeverity::INFO,
        'warning' => ContextualFeedbackSeverity::WARNING,
        'error' => ContextualFeedbackSeverity::ERROR,
    ];

    private const SEVERITIES = [
        'ok' => ContextualFeedbackSeverity::OK,
        'info' => ContextualFeedbackSeverity::INFO,
        'notice' => ContextualFeedbackSeverity::NOTICE,
        'warning' => ContextualFeedbackSeverity::WARNING,
        'error' => ContextualFeedbackSeverity::ERROR,
    ];

    /** @var list<array{check: string, severity: ContextualFeedbackSeverity, title: string, message: string}> */
    private array $findings = [];

    public function __construct(
        private readonly SchemaMigrator $schemaMigrator,
        private readonly SqlReader $sqlReader,
        private readonly UriBuilder $uriBuilder,
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addOption(
                'allowlist',
                null,
                InputOption::VALUE_REQUIRED,
                'YAML file with the documented, expected findings',
                'EXT:netresearch_demo_site/Configuration/InstallTool/expected-findings.yaml',
            )
            ->addOption(
                'floor',
                null,
                InputOption::VALUE_REQUIRED,
                'Lowest severity that fails the run unless allowlisted (notice, info, warning, error); OK never does',
                'warning',
            )
            ->addOption(
                'base-url',
                null,
                InputOption::VALUE_REQUIRED,
                'Where the server response probe sends its requests. The default is the nginx of this container, '
                . 'which sets every header the probe evaluates; Caddy in front adds none of them.',
                'http://127.0.0.1',
            )
            ->addOption('show-ok', null, InputOption::VALUE_NONE, 'Also print the checks that passed');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $floor = self::FLOORS[strtolower((string)$input->getOption('floor'))] ?? null;
        if ($floor === null) {
            $output->writeln('<error>--floor must be one of: ' . implode(', ', array_keys(self::FLOORS)) . '</error>');
            return Command::INVALID;
        }
        try {
            $allowlist = $this->loadAllowlist((string)$input->getOption('allowlist'));
        } catch (Throwable $e) {
            $output->writeln('<error>Cannot read the allowlist: ' . $e->getMessage() . '</error>');
            return Command::INVALID;
        }

        $sections = [
            'environment' => fn() => $this->runEnvironmentChecks(),
            'sapi' => fn() => $this->compareSapis(),
            'server-response' => fn() => $this->runServerResponseCheck((string)$input->getOption('base-url')),
            'directory' => fn() => $this->runDirectoryChecks(),
            'database' => fn() => $this->runSchemaComparison(),
            'image' => fn() => $this->runImageTests(),
        ];
        foreach ($sections as $check => $run) {
            try {
                $run();
            } catch (Throwable $e) {
                // A check that cannot run is a finding of its own, never a pass.
                $this->add($check, ContextualFeedbackSeverity::ERROR, 'Check could not run', $e::class . ': ' . $e->getMessage());
            }
        }

        $matchedEntries = [];
        $unexpected = 0;
        $counts = [];
        foreach ($this->findings as $finding) {
            $isOk = $finding['severity'] === ContextualFeedbackSeverity::OK;
            $entry = $this->matchAllowlist($allowlist, $finding);
            if ($entry !== null) {
                $matchedEntries[$entry] = true;
            }
            // OK (0) sits between INFO (-1) and WARNING (1), so it needs its own case.
            $belowFloor = !$isOk && $finding['severity']->value < $floor->value;
            $status = match (true) {
                $isOk => 'ok',
                $entry !== null => 'expected',
                $belowFloor => 'below floor',
                default => 'UNEXPECTED',
            };
            if ($status === 'UNEXPECTED') {
                $unexpected++;
            }
            $counts[$finding['check']][$finding['severity']->name] = ($counts[$finding['check']][$finding['severity']->name] ?? 0) + 1;
            if ($isOk && !$input->getOption('show-ok')) {
                continue;
            }
            $output->writeln(sprintf(
                '%-7s %-15s %-11s %s%s',
                strtoupper($finding['severity']->name),
                $finding['check'],
                $status,
                $finding['title'],
                $finding['message'] === '' ? '' : ' -- ' . $finding['message'],
            ));
        }

        foreach ($allowlist as $index => $entry) {
            if (!isset($matchedEntries[$index])) {
                $output->writeln(sprintf(
                    'NOTICE  allowlist       stale       entry %d (%s, %s, "%s") matched no finding; remove it if the cause is gone',
                    $index + 1,
                    $entry['check'],
                    $entry['severity']->name,
                    $entry['title'],
                ));
            }
        }

        $output->writeln('');
        foreach ($counts as $check => $bySeverity) {
            ksort($bySeverity);
            $output->writeln(sprintf('%-15s %s', $check, implode(', ', array_map(
                static fn(string $severity, int $count): string => $count . ' ' . strtolower($severity),
                array_keys($bySeverity),
                $bySeverity,
            ))));
        }
        $output->writeln(sprintf(
            '%d finding(s) at or above %s that the allowlist does not cover.',
            $unexpected,
            strtolower($floor->name),
        ));
        return $unexpected === 0 ? Command::SUCCESS : Command::FAILURE;
    }

    private function runEnvironmentChecks(): void
    {
        foreach ([new Check(), new SetupCheck(), new DatabaseCheck()] as $provider) {
            foreach ($provider->getStatus()->getAllMessages() as $message) {
                $this->addMessage('environment', $message);
            }
        }

        // SetupCheck::checkTrustedHostPattern returns early on the CLI. In the
        // backend the request arrives through Caddy with the site's domain as
        // its Host header, so evaluate the pattern for that host.
        $pattern = (string)($GLOBALS['TYPO3_CONF_VARS']['SYS']['trustedHostsPattern'] ?? '');
        if ($pattern !== VerifyHostHeader::ENV_TRUSTED_HOSTS_PATTERN_ALLOW_ALL) {
            $host = (string)(getenv('TYPO3_DOMAIN') ?: 'localhost');
            $allowed = (new VerifyHostHeader($pattern))->isAllowedHostHeaderValue($host, ['HTTP_HOST' => $host, 'SERVER_NAME' => $host, 'SERVER_PORT' => '443', 'HTTPS' => 'on']);
            $this->add(
                'environment',
                $allowed ? ContextualFeedbackSeverity::OK : ContextualFeedbackSeverity::ERROR,
                $allowed ? 'Trusted hosts pattern is configured to allow current host value.' : 'Trusted hosts pattern mismatch',
                $allowed ? '' : sprintf('trustedHostsPattern "%s" rejects the site host "%s" (evaluated by this command; core skips the check on the CLI)', $pattern, $host),
            );
        }
    }

    /**
     * The checks read php.ini through ini_get(), which in this process answers
     * for the CLI SAPI. The backend shows the php-fpm values.
     */
    private function compareSapis(): void
    {
        $fpm = (new ExecutableFinder())->find('php-fpm', null, ['/usr/local/sbin', '/usr/sbin']);
        if ($fpm === null) {
            $this->add('sapi', ContextualFeedbackSeverity::WARNING, 'php-fpm not found', 'The CLI values above cannot be compared with the ones the backend sees.');
            return;
        }
        $process = new Process([$fpm, '-i']);
        $process->mustRun();
        $fpmValues = [];
        foreach (explode("\n", $process->getOutput()) as $line) {
            if (preg_match('/^([a-z_.]+) => (.*) => .*$/', $line, $m) === 1) {
                $fpmValues[$m[1]] = $m[2] === 'no value' ? '' : $m[2];
            }
        }
        $modules = new Process([$fpm, '-m']);
        $modules->mustRun();

        $differences = [];
        foreach (self::SAPI_DIRECTIVES as $directive) {
            $cli = ini_get($directive);
            if ($cli === false && !isset($fpmValues[$directive])) {
                continue;
            }
            $cliValue = $this->normaliseIniValue($cli === false ? '' : $cli);
            $fpmValue = $this->normaliseIniValue($fpmValues[$directive] ?? '');
            if ($cliValue !== $fpmValue) {
                $differences[] = sprintf('%s: cli="%s" fpm="%s"', $directive, $cliValue, $fpmValue);
            }
        }
        // `php-fpm -m` lists the SAPI itself as a module; that is not a difference.
        $fpmModules = array_map('strtolower', array_filter(
            array_map('trim', explode("\n", $modules->getOutput())),
            static fn(string $l): bool => $l !== '' && !str_starts_with($l, '[') && $l !== 'cgi-fcgi',
        ));
        $cliModules = array_map('strtolower', get_loaded_extensions());
        foreach (array_diff($cliModules, $fpmModules) as $module) {
            $differences[] = sprintf('extension %s: loaded in cli only', $module);
        }
        foreach (array_diff($fpmModules, $cliModules) as $module) {
            $differences[] = sprintf('extension %s: loaded in fpm only', $module);
        }
        $this->add(
            'sapi',
            $differences === [] ? ContextualFeedbackSeverity::OK : ContextualFeedbackSeverity::WARNING,
            $differences === [] ? 'CLI and php-fpm agree on every setting the environment checks read' : 'CLI and php-fpm differ in a setting the environment checks read',
            implode('; ', $differences),
        );

        // Check::checkMaxExecutionTime reports the CLI's forced 0 as fine, so
        // apply its thresholds to the php-fpm value: below 30 s is an error,
        // below 240 s or unlimited a warning.
        $maxExecutionTime = (int)($fpmValues['max_execution_time'] ?? -1);
        $severity = match (true) {
            $maxExecutionTime < 0 => ContextualFeedbackSeverity::WARNING,
            $maxExecutionTime === 0 => ContextualFeedbackSeverity::WARNING,
            $maxExecutionTime < 30 => ContextualFeedbackSeverity::ERROR,
            $maxExecutionTime < 240 => ContextualFeedbackSeverity::WARNING,
            default => ContextualFeedbackSeverity::OK,
        };
        $this->add('sapi', $severity, 'php-fpm max_execution_time', 'max_execution_time=' . ($fpmValues['max_execution_time'] ?? 'unknown'));
    }

    private function normaliseIniValue(string $value): string
    {
        return match (strtolower(trim($value))) {
            'on', '1', 'true', 'yes' => '1',
            'off', '0', 'false', 'no', '' => '',
            default => trim($value),
        };
    }

    /**
     * ServerResponseCheck needs a request: it derives the probe URLs from its
     * normalizedParams and the host-header probe URL from the backend router.
     */
    private function runServerResponseCheck(string $baseUrl): void
    {
        $uri = rtrim($baseUrl, '/') . '/typo3/';
        $parts = parse_url($uri);
        $https = ($parts['scheme'] ?? 'http') === 'https';
        $serverParams = [
            'HTTP_HOST' => $parts['host'] . (isset($parts['port']) ? ':' . $parts['port'] : ''),
            'SERVER_NAME' => $parts['host'],
            'SERVER_PORT' => (string)($parts['port'] ?? ($https ? 443 : 80)),
            'HTTPS' => $https ? 'on' : 'off',
            'REQUEST_URI' => '/typo3/',
            'SCRIPT_NAME' => '/typo3/index.php',
            'SCRIPT_FILENAME' => Environment::getPublicPath() . '/typo3/index.php',
            'REMOTE_ADDR' => '127.0.0.1',
        ];
        // Built without the reverse-proxy settings: reverseProxySSL '*' would
        // otherwise turn this plain-http request into https.
        $request = (new ServerRequest($uri, 'GET', null, [], $serverParams))
            ->withAttribute('applicationType', SystemEnvironmentBuilder::REQUESTTYPE_BE)
            ->withAttribute('normalizedParams', new NormalizedParams($serverParams, [], Environment::getPublicPath() . '/typo3/index.php', Environment::getPublicPath()));

        // Core counts a probe that gets no response at all as passed, so make
        // sure the base answers before trusting an "OK".
        try {
            (new Client(['timeout' => 10, 'http_errors' => false]))->request('GET', rtrim($baseUrl, '/') . '/');
        } catch (TransferException $e) {
            $this->add('server-response', ContextualFeedbackSeverity::ERROR, 'Probe base not reachable', $baseUrl . ': ' . $e->getMessage());
            return;
        }

        $previousRequest = $GLOBALS['TYPO3_REQUEST'] ?? null;
        $GLOBALS['TYPO3_REQUEST'] = $request;
        try {
            $messages = (new CliServerResponseCheck($this->uriBuilder, false))->getStatus($request)->getAllMessages();
        } finally {
            $GLOBALS['TYPO3_REQUEST'] = $previousRequest;
        }
        foreach ($messages as $message) {
            $this->addMessage('server-response', $message);
        }
    }

    private function runDirectoryChecks(): void
    {
        // nginx serves this site, which the Install Tool maps to WebserverType::Other.
        $structure = GeneralUtility::makeInstance(DefaultFactory::class)->getStructure(WebserverType::Other);
        foreach ($structure->getStatus()->getAllMessages() as $message) {
            $this->addMessage('directory', $message);
        }
        $permissions = GeneralUtility::makeInstance(DefaultPermissionsCheck::class);
        foreach (['fileCreateMask', 'folderCreateMask'] as $mask) {
            $this->addMessage('directory', $permissions->getMaskStatus($mask));
        }
    }

    private function runSchemaComparison(): void
    {
        $statements = $this->sqlReader->getCreateTableStatementArray($this->sqlReader->getTablesDefinitionString());

        $addCreateChange = array_merge_recursive(...array_values($this->schemaMigrator->getUpdateSuggestions($statements)));
        $labels = [
            'create_table' => 'Add tables',
            'add' => 'Add fields to tables',
            'change' => 'Change fields',
        ];
        foreach ($labels as $key => $label) {
            foreach ($addCreateChange[$key] ?? [] as $hash => $statement) {
                $current = $addCreateChange['change_currentValue'][$hash] ?? null;
                $this->add('database', ContextualFeedbackSeverity::WARNING, $label, $statement . ($current !== null ? ' (current: ' . $current . ')' : ''));
            }
        }

        $dropRename = array_merge_recursive(...array_values($this->schemaMigrator->getUpdateSuggestions($statements, true)));
        $labels = [
            'change_table' => 'Remove tables (rename with prefix)',
            'change' => 'Remove unused fields (rename with prefix)',
            'drop' => 'Drop fields (really!)',
            'drop_table' => 'Drop tables (really!)',
        ];
        foreach ($labels as $key => $label) {
            foreach ($dropRename[$key] ?? [] as $hash => $statement) {
                $rows = $dropRename['tables_count'][$hash] ?? '';
                $this->add('database', ContextualFeedbackSeverity::WARNING, $label, $statement . ($rows !== '' ? ' (' . $rows . ')' : ''));
            }
        }
        if ($this->findingsFor('database') === []) {
            $this->add('database', ContextualFeedbackSeverity::OK, 'Database schema matches the definitions', '');
        }
    }

    /**
     * The read/write/scale/convert tests of EnvironmentController with the same
     * input files and calls. The backend shows the output next to a reference
     * image; here a test passes when the output exists and has the requested
     * format, which is the controller's own fallback-format check.
     */
    private function runImageTests(): void
    {
        $gfx = $GLOBALS['TYPO3_CONF_VARS']['GFX'];
        if (!$gfx['processor_enabled'] || !$gfx['processor_path']) {
            $this->add('image', ContextualFeedbackSeverity::ERROR, 'Tests not executed', 'ImageMagick / GraphicsMagick handling is disabled or not configured correctly.');
            return;
        }
        $input = ExtensionManagementUtility::extPath('install') . 'Resources/Public/Images/TestInput/';
        // [label, input file, target format, extra parameters, severity when no file is written]
        $tests = [];
        foreach (['jpg', 'webp', 'avif', 'gif', 'png', 'tif', 'pdf', 'ai'] as $format) {
            $tests[] = ['Read ' . $format, 'Test.' . $format, 'jpg', '', ContextualFeedbackSeverity::ERROR, $format];
        }
        $tests[] = ['Write gif', 'Test.gif', 'gif', '', ContextualFeedbackSeverity::ERROR, null];
        $tests[] = ['Write png', 'Test.png', 'png', '', ContextualFeedbackSeverity::ERROR, null];
        $tests[] = ['Write webp', 'Test.webp', 'webp', '', ContextualFeedbackSeverity::ERROR, null];
        $tests[] = ['Write avif', 'Test.avif', 'avif', '', ContextualFeedbackSeverity::INFO, null];
        $tests[] = ['Scale gif to gif', 'Transparent.gif', 'gif', '', ContextualFeedbackSeverity::ERROR, null];
        $tests[] = ['Scale png to png', 'Transparent.png', 'png', '', ContextualFeedbackSeverity::ERROR, null];
        $tests[] = ['Scale gif to jpg', 'Transparent.gif', 'jpg', '-opaque white -background white -flatten', ContextualFeedbackSeverity::ERROR, null];
        $tests[] = ['Convert svg to webp', 'Transparent.svg', 'webp', '', ContextualFeedbackSeverity::ERROR, null];
        $tests[] = ['Convert svg to png', 'Transparent.svg', 'png', '', ContextualFeedbackSeverity::ERROR, null];
        $tests[] = ['Convert jpg to webp', 'Test.jpg', 'webp', '', ContextualFeedbackSeverity::ERROR, null];
        $tests[] = ['Convert jpg to avif', 'Test.jpg', 'avif', '', ContextualFeedbackSeverity::INFO, null];
        $tests[] = ['Convert png to webp', 'Transparent.png', 'webp', '', ContextualFeedbackSeverity::ERROR, null];
        $tests[] = ['Convert png to avif', 'Transparent.png', 'avif', '', ContextualFeedbackSeverity::INFO, null];

        foreach ($tests as [$label, $file, $target, $parameters, $failureSeverity, $readFormat]) {
            if ($readFormat !== null && !GeneralUtility::inList($gfx['imagefile_ext'], $readFormat)) {
                $this->add('image', ContextualFeedbackSeverity::WARNING, $label . ': Skipped test', 'Handling format ' . $readFormat . ' must be enabled in TYPO3_CONF_VARS[\'GFX\'][\'imagefile_ext\']');
                continue;
            }
            $imageService = GeneralUtility::makeInstance(GraphicalFunctions::class);
            $imageService->dontCheckForExistingTempFile = true;
            $imageService->filenamePrefix = 'installTool-';
            $imageService->alternativeOutputKey = 'typo3InstallTest';
            $imageService->setImageFileExt(self::IMAGE_FILE_EXT);
            $imageService->imageMagickConvert_forceFileNameBody = StringUtility::getUniqueId('demo-check');
            $result = $imageService->resize($input . $file, $target, '300', '', $parameters, [], true);
            $outputFile = $result?->getRealPath();
            if ($result === null || !$result->isFile() || $outputFile === null || filesize($outputFile) === 0) {
                $this->add('image', $failureSeverity, $label . ': Image generation failed', implode(' | ', array_map(static fn(array $c): string => (string)($c[1] ?? ''), $imageService->IM_commands)));
            } elseif (strtolower(pathinfo($outputFile, PATHINFO_EXTENSION)) !== $target) {
                $this->add('image', ContextualFeedbackSeverity::WARNING, $label . ': Unexpected output file extension', 'expected ' . $target . ', got ' . basename($outputFile));
            } else {
                $this->add('image', ContextualFeedbackSeverity::OK, $label, basename($outputFile) . ', ' . filesize($outputFile) . ' bytes');
            }
            // Removes only files below typo3temp/ (or var/).
            if ($outputFile !== null && str_contains(basename($outputFile), 'demo-check')) {
                GeneralUtility::unlink_tempfile($outputFile);
            }
        }
    }

    private function addMessage(string $check, FlashMessage $message): void
    {
        $this->add($check, $message->getSeverity(), $message->getTitle(), $message->getMessage());
    }

    private function add(string $check, ContextualFeedbackSeverity $severity, string $title, string $message): void
    {
        $this->findings[] = [
            'check' => $check,
            'severity' => $severity,
            'title' => trim($title),
            'message' => trim((string)preg_replace('/\s+/', ' ', strip_tags($message))),
        ];
    }

    /** @return list<array{check: string, severity: ContextualFeedbackSeverity, title: string, message: string}> */
    private function findingsFor(string $check): array
    {
        return array_values(array_filter($this->findings, static fn(array $f): bool => $f['check'] === $check));
    }

    /**
     * @return list<array{check: string, severity: ContextualFeedbackSeverity, title: string, messagePattern: string}>
     */
    private function loadAllowlist(string $path): array
    {
        $file = str_starts_with($path, 'EXT:') ? GeneralUtility::getFileAbsFileName($path) : $path;
        if ($file === '' || !is_file($file)) {
            throw new \RuntimeException(sprintf('"%s" does not exist', $path), 1793452001);
        }
        $data = Yaml::parseFile($file);
        if (!is_array($data) || !is_array($data['expected'] ?? null)) {
            throw new \RuntimeException(sprintf('"%s" has no "expected" list', $path), 1793452004);
        }
        $entries = [];
        foreach (array_values($data['expected']) as $index => $entry) {
            $severity = is_array($entry) ? (self::SEVERITIES[strtolower((string)($entry['severity'] ?? ''))] ?? null) : null;
            if (!is_array($entry) || !isset($entry['check'], $entry['title'], $entry['class'], $entry['reason']) || $severity === null) {
                throw new \RuntimeException(sprintf('entry %d needs check, severity, title, class and reason', $index + 1), 1793452002);
            }
            $pattern = (string)($entry['messagePattern'] ?? '');
            if ($pattern !== '' && @preg_match($pattern, '') === false) {
                throw new \RuntimeException(sprintf('entry %d: messagePattern %s is not a valid regular expression', $index + 1, $pattern), 1793452003);
            }
            $entries[] = [
                'check' => (string)$entry['check'],
                'severity' => $severity,
                'title' => trim((string)$entry['title']),
                'messagePattern' => $pattern,
            ];
        }
        return $entries;
    }

    /**
     * An entry matches on check, severity and exact title, never on the whole
     * message, which embeds measured values. messagePattern (a regular
     * expression) narrows an entry where one title covers several findings,
     * such as the statements of the schema comparison.
     *
     * @param list<array{check: string, severity: ContextualFeedbackSeverity, title: string, messagePattern: string}> $allowlist
     * @param array{check: string, severity: ContextualFeedbackSeverity, title: string, message: string} $finding
     */
    private function matchAllowlist(array $allowlist, array $finding): ?int
    {
        foreach ($allowlist as $index => $entry) {
            if ($entry['check'] === $finding['check']
                && $entry['severity'] === $finding['severity']
                && $entry['title'] === $finding['title']
                && ($entry['messagePattern'] === '' || preg_match($entry['messagePattern'], $finding['message']) === 1)
            ) {
                return $index;
            }
        }
        return null;
    }
}
