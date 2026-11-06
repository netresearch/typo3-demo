<?php

/**
 * Writes data/seed-falkenquell.sql: every record of the Falkenquell site, moved
 * into the seed uid band 9000-9998 (see the band rules at the top of
 * data/seed-extensions.sql) and inserted with INSERT IGNORE.
 *
 * Run it in the web container against the database that holds the finished
 * site, with the uid of the Falkenquell root page:
 *
 *   docker compose exec -T web php -- <rootUid> < scripts/falkenquell-seed.php > data/seed-falkenquell.sql
 *
 * Records whose uid already lies in the band keep it, so the script can run
 * again after the local database has been switched to the seeded uids. Records
 * at 10000 and above (created locally later) get the next free band uid. Every
 * reference to a moved uid is rewritten: parent and translation pointers, file
 * references, plugin settings in FlexForms and t3:// links in text fields.
 * The uid map goes to stderr, because the site configuration
 * (config/sites/falkenquell) refers to page uids and has to follow it.
 *
 * The seed only ever inserts. Once a record exists on the live instance the
 * live instance owns it; the verification at the end reports a seeded uid
 * that is held by a foreign row (different crdate) as SEED-PROBLEM, which
 * makes `make seed-extensions` fail instead of skipping the record silently.
 */

declare(strict_types=1);

const BAND_START = 9300;
const BAND_END = 9998;
const CHUNK = 25;

$rootUid = (int)($argv[1] ?? 0);
if ($rootUid <= 0) {
    fwrite(STDERR, "usage: php -- <rootUid> < scripts/falkenquell-seed.php\n");
    exit(1);
}

$pdo = new PDO(
    'mysql:host=' . getenv('MARIADB_HOST') . ';dbname=' . getenv('MARIADB_DATABASE') . ';charset=utf8mb4',
    (string)getenv('MARIADB_USER'),
    (string)getenv('MARIADB_PASSWORD'),
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
);

function rows(PDO $pdo, string $sql): array
{
    return $pdo->query($sql)->fetchAll();
}

function uidList(array $rows): string
{
    $uids = array_map(static fn(array $row): int => (int)$row['uid'], $rows);
    return $uids === [] ? '0' : implode(',', $uids);
}

// Page tree below the root, default language first, then its translations.
$pageUids = [$rootUid];
$queue = [$rootUid];
while ($queue !== []) {
    $children = $pdo->query('SELECT uid FROM pages WHERE deleted = 0 AND sys_language_uid = 0 AND pid IN (' . implode(',', $queue) . ')')->fetchAll(PDO::FETCH_COLUMN);
    $queue = array_map('intval', $children);
    $pageUids = array_merge($pageUids, $queue);
}
$pageIn = implode(',', $pageUids);

$records = [];
$records['pages'] = rows($pdo, "SELECT * FROM pages WHERE deleted = 0 AND (uid IN ($pageIn) OR (sys_language_uid > 0 AND l10n_parent IN ($pageIn))) ORDER BY sys_language_uid, uid");
$allPages = uidList($records['pages']);
$records['tt_content'] = rows($pdo, "SELECT * FROM tt_content WHERE deleted = 0 AND pid IN ($allPages) ORDER BY sys_language_uid, uid");
$contentIn = uidList($records['tt_content']);
foreach (['tx_bootstrappackage_card_group_item', 'tx_bootstrappackage_icon_group_item', 'tx_bootstrappackage_accordion_item'] as $itemTable) {
    $records[$itemTable] = rows($pdo, "SELECT * FROM $itemTable WHERE deleted = 0 AND tt_content IN ($contentIn) ORDER BY sys_language_uid, uid");
}
foreach (['tx_news_domain_model_news', 'tx_sfeventmgt_domain_model_location', 'tx_sfeventmgt_domain_model_event'] as $recordTable) {
    $records[$recordTable] = rows($pdo, "SELECT * FROM $recordTable WHERE deleted = 0 AND pid IN ($allPages) ORDER BY sys_language_uid, uid");
}
$records['tx_nrlandingpage_domain_model_template'] = rows($pdo, "SELECT * FROM tx_nrlandingpage_domain_model_template WHERE deleted = 0 AND pid IN ($allPages) ORDER BY uid");
// Database forms (EXT:form since TYPO3 14.2) referenced by the form elements.
$formUids = [0];
foreach ($records['tt_content'] as $content) {
    if (preg_match('#index="settings\.persistenceIdentifier">\s*<value index="vDEF">(\d+)</value>#', (string)$content['pi_flexform'], $m)) {
        $formUids[] = (int)$m[1];
    }
}
$records['form_definition'] = rows($pdo, 'SELECT * FROM form_definition WHERE deleted = 0 AND uid IN (' . implode(',', $formUids) . ') ORDER BY uid');
$records['tx_nrllm_promptsnippet'] =rows($pdo, "SELECT * FROM tx_nrllm_promptsnippet WHERE deleted = 0 AND identifier LIKE 'falkenquell%' ORDER BY uid");
$records['tx_nrllm_configuration'] = rows($pdo, "SELECT * FROM tx_nrllm_configuration WHERE deleted = 0 AND identifier = 'falkenquell' ORDER BY uid");

// File references of the records above; the files and their metadata follow
// from the references, plus everything stored below /falkenquell/.
$referenceParts = [];
foreach (['pages', 'tt_content', 'tx_bootstrappackage_card_group_item', 'tx_bootstrappackage_icon_group_item', 'tx_bootstrappackage_accordion_item', 'tx_news_domain_model_news', 'tx_sfeventmgt_domain_model_event'] as $parentTable) {
    $referenceParts[] = "(tablenames = '$parentTable' AND uid_foreign IN (" . uidList($records[$parentTable]) . '))';
}
$records['sys_file_reference'] = rows($pdo, 'SELECT * FROM sys_file_reference WHERE deleted = 0 AND (' . implode(' OR ', $referenceParts) . ') ORDER BY sys_language_uid, uid');
$fileUids = array_map(static fn(array $row): int => (int)$row['uid_local'], $records['sys_file_reference']);
$fileUids = array_merge($fileUids, array_map('intval', $pdo->query("SELECT uid FROM sys_file WHERE storage = 1 AND identifier LIKE '/falkenquell/%'")->fetchAll(PDO::FETCH_COLUMN)));
$fileIn = implode(',', array_unique($fileUids)) ?: '0';
$records['sys_file'] = rows($pdo, "SELECT * FROM sys_file WHERE uid IN ($fileIn) ORDER BY uid");
$records['sys_file_metadata'] = rows($pdo, "SELECT * FROM sys_file_metadata WHERE file IN ($fileIn) ORDER BY sys_language_uid, uid");

foreach ($records['sys_file'] as $file) {
    if (!str_starts_with((string)$file['identifier'], '/falkenquell/')) {
        fwrite(STDERR, "A Falkenquell record references a file outside /falkenquell/: {$file['identifier']} (sys_file {$file['uid']}). Move it there first.\n");
        exit(1);
    }
}

// uid map: band uids are kept, everything else gets the next free band uid.
$map = [];
foreach ($records as $table => $tableRows) {
    $own = array_map(static fn(array $row): int => (int)$row['uid'], $tableRows);
    $taken = array_map('intval', $pdo->query("SELECT uid FROM $table WHERE uid BETWEEN " . BAND_START . ' AND ' . BAND_END)->fetchAll(PDO::FETCH_COLUMN));
    $taken = array_flip(array_diff($taken, $own));
    $next = BAND_START;
    $map[$table] = [];
    foreach ($own as $uid) {
        if ($uid >= BAND_START && $uid <= BAND_END) {
            $map[$table][$uid] = $uid;
            $taken[$uid] = true;
        }
    }
    foreach ($own as $uid) {
        if (isset($map[$table][$uid])) {
            continue;
        }
        while (isset($taken[$next])) {
            $next++;
        }
        if ($next > BAND_END) {
            fwrite(STDERR, "$table: the seed band is full\n");
            exit(1);
        }
        $map[$table][$uid] = $next;
        $taken[$next] = true;
    }
}

function mapUid(array $map, string $table, mixed $uid): mixed
{
    return $map[$table][(int)$uid] ?? $uid;
}

function mapLinks(array $map, ?string $text): ?string
{
    if ($text === null || $text === '') {
        return $text;
    }
    return preg_replace_callback(
        '#t3://(page|file)\?uid=(\d+)#',
        static fn(array $m): string => 't3://' . $m[1] . '?uid=' . mapUid($map, $m[1] === 'page' ? 'pages' : 'sys_file', $m[2]),
        $text
    );
}

function mapTypolink(array $map, ?string $link): ?string
{
    if ($link !== null && ctype_digit($link)) {
        return (string)mapUid($map, 'pages', $link);
    }
    return mapLinks($map, $link);
}

function mapFlexForm(array $map, ?string $xml): ?string
{
    if ($xml === null || $xml === '') {
        return $xml;
    }
    $xml = mapLinks($map, $xml);
    $xml = preg_replace_callback(
        '#(index="settings\.persistenceIdentifier">\s*<value index="vDEF">)(\d+)(</value>)#',
        static fn(array $m): string => $m[1] . '@form:' . mapUid($map, 'form_definition', $m[2]) . $m[3],
        $xml
    );
    // The form uid is marked so that the page mapping below leaves it alone.
    $xml = preg_replace_callback(
        '#(<value index="vDEF">)([0-9,]+)(</value>)#',
        static fn(array $m): string => $m[1] . implode(',', array_map(static fn(string $uid): string => (string)mapUid($map, 'pages', $uid), explode(',', $m[2]))) . $m[3],
        $xml
    );
    return str_replace('<value index="vDEF">@form:', '<value index="vDEF">', $xml);
}

$translationPointer = ['tt_content' => 'l18n_parent'];
$mapped = [];
foreach ($records as $table => $tableRows) {
    foreach ($tableRows as $row) {
        $row['uid'] = $map[$table][(int)$row['uid']];
        if (array_key_exists('pid', $row) && $table !== 'sys_file' && $table !== 'sys_file_metadata') {
            $row['pid'] = mapUid($map, 'pages', $row['pid']);
        }
        $pointer = $translationPointer[$table] ?? 'l10n_parent';
        if (isset($row[$pointer]) && (int)$row[$pointer] > 0) {
            $row[$pointer] = mapUid($map, $table, $row[$pointer]);
        }
        if (isset($row['l10n_source']) && (int)$row['l10n_source'] > 0) {
            $row['l10n_source'] = mapUid($map, $table, $row['l10n_source']);
        }
        // Snapshots of the source record taken at translation time, with the
        // old uids in them; TYPO3 only uses them to highlight changed fields.
        foreach (['l10n_diffsource', 'l18n_diffsource'] as $diffSource) {
            if (array_key_exists($diffSource, $row)) {
                $row[$diffSource] = '';
            }
        }
        switch ($table) {
            case 'pages':
                foreach (['shortcut', 'content_from_pid', 'mount_pid'] as $field) {
                    $row[$field] = mapUid($map, 'pages', $row[$field]);
                }
                $row['link'] = mapTypolink($map, $row['link']);
                break;
            case 'tt_content':
                $row['bodytext'] = mapLinks($map, $row['bodytext']);
                $row['teaser'] = mapLinks($map, $row['teaser'] ?? null);
                $row['header_link'] = mapTypolink($map, $row['header_link']);
                $row['pi_flexform'] = mapFlexForm($map, $row['pi_flexform']);
                $row['pages'] = $row['pages'] === null || $row['pages'] === '' ? $row['pages'] : implode(',', array_map(static fn(string $uid): string => (string)mapUid($map, 'pages', $uid), explode(',', $row['pages'])));
                break;
            case 'tx_bootstrappackage_card_group_item':
            case 'tx_bootstrappackage_icon_group_item':
            case 'tx_bootstrappackage_accordion_item':
                $row['tt_content'] = mapUid($map, 'tt_content', $row['tt_content']);
                $row['bodytext'] = mapLinks($map, $row['bodytext']);
                if (array_key_exists('link', $row)) {
                    $row['link'] = mapTypolink($map, $row['link']);
                }
                break;
            case 'tx_news_domain_model_news':
                $row['bodytext'] = mapLinks($map, $row['bodytext']);
                $row['teaser'] = mapLinks($map, $row['teaser']);
                break;
            case 'tx_sfeventmgt_domain_model_event':
                $row['description'] = mapLinks($map, $row['description']);
                $row['program'] = mapLinks($map, $row['program']);
                $row['location'] = mapUid($map, 'tx_sfeventmgt_domain_model_location', $row['location']);
                $row['link'] = mapTypolink($map, $row['link']);
                break;
            case 'sys_file_metadata':
                $row['file'] = mapUid($map, 'sys_file', $row['file']);
                break;
            case 'sys_file_reference':
                $row['uid_local'] = mapUid($map, 'sys_file', $row['uid_local']);
                $row['uid_foreign'] = mapUid($map, $row['tablenames'], $row['uid_foreign']);
                $row['link'] = mapTypolink($map, $row['link']);
                break;
        }
        $mapped[$table][] = $row;
    }
}

function sqlValue(PDO $pdo, mixed $value): string
{
    return $value === null ? 'NULL' : $pdo->quote((string)$value);
}

$identity = static fn(string $table): string => $table === 'sys_file' ? 'creation_date' : 'crdate';

$out = [];
$out[] = '-- Falkenquell site (NRMARKETING-1485): pages, content, news, events, files and the AI configuration.';
$out[] = '-- GENERATED by scripts/falkenquell-seed.php — do not edit by hand; change the site and generate again.';
$out[] = '--';
$out[] = '-- uids lie in the seed band 9000-9998 (rules at the top of data/seed-extensions.sql). Only INSERT IGNORE:';
$out[] = '-- after the first import the live instance owns these records, and a later deploy changes none of them.';
$out[] = '-- A record deleted for good on live (also from the recycler) is created again by the next deploy.';
$out[] = '-- The files come from data/fileadmin/falkenquell (entrypoint.sh copies them); the forms are form_definition records.';
$out[] = '';
$out[] = 'SET NAMES utf8mb4;';
foreach ($mapped as $table => $tableRows) {
    $out[] = '';
    $out[] = "-- $table: " . count($tableRows) . ' records';
    $columns = array_keys($tableRows[0]);
    $columnList = '`' . implode('`, `', $columns) . '`';
    foreach (array_chunk($tableRows, CHUNK) as $chunk) {
        $values = array_map(static fn(array $row): string => '(' . implode(', ', array_map(static fn(mixed $v): string => sqlValue($GLOBALS['pdo'], $v), $row)) . ')', $chunk);
        $out[] = "INSERT IGNORE INTO `$table` ($columnList) VALUES\n" . implode(",\n", $values) . ';';
    }
}
$out[] = '';
$out[] = '-- Keep new backend records above the band; InnoDB never sets the counter below MAX(uid) + 1.';
foreach (array_keys($mapped) as $table) {
    $out[] = "ALTER TABLE `$table` AUTO_INCREMENT = 10000;";
}
$out[] = '';
$out[] = '-- Verification: a seeded uid held by a row with a different ' . 'crdate is a foreign row, the record is missing.';
foreach ($mapped as $table => $tableRows) {
    $column = $identity($table);
    $expected = implode(",\n  ", array_map(static fn(array $row): string => '(' . (int)$row['uid'] . ', ' . (int)$row[$column] . ')', $tableRows));
    $out[] = "SELECT CONCAT('SEED-PROBLEM: falkenquell $table ', e.uid, ' missing or foreign') AS seed_verification\n"
        . "FROM (SELECT 0 AS uid, 0 AS ident UNION ALL VALUES\n  $expected\n) e\n"
        . "LEFT JOIN `$table` t ON t.uid = e.uid\n"
        . "WHERE e.uid > 0 AND (t.uid IS NULL OR t.`$column` <> e.ident);";
}

echo implode("\n", $out), "\n";

$summary = [];
foreach ($map as $table => $tableMap) {
    $summary[] = sprintf('%-40s %4d records', $table, count($tableMap));
}
fwrite(STDERR, implode("\n", $summary) . "\n\npages uid map:\n");
foreach ($map['pages'] as $old => $new) {
    fwrite(STDERR, "  $old => $new\n");
}
