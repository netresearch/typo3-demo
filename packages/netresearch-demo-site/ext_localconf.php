<?php

declare(strict_types=1);

defined('TYPO3') or die();

// Register demo site RTE preset (extends Bootstrap Package + rte_ckeditor_image + cowriter)
$GLOBALS['TYPO3_CONF_VARS']['RTE']['Presets']['default'] = 'EXT:netresearch_demo_site/Configuration/RTE/Default.yaml';

// Bootstrap Package's RTE set assigns `preset = bootstrap` to tt_content.bodytext,
// so content editing uses the 'bootstrap' preset — NOT 'default'. Override that
// preset too (our Default.yaml already imports Bootstrap Package's config and adds
// the Cowriter + rte_ckeditor_image plugins), so the Cowriter toolbar button
// actually appears when editing content, not only on fields pinned to 'default'.
$GLOBALS['TYPO3_CONF_VARS']['RTE']['Presets']['bootstrap'] = 'EXT:netresearch_demo_site/Configuration/RTE/Default.yaml';

// Route ERROR-level (and above) log records to the database log (sys_log) in
// addition to the default file writer, so runtime failures — e.g. nr-ai-search's
// swallowed RAG errors — are visible in the backend "System > Log" module and to
// diagnostic tooling, without shell access to var/log on the deployed instance.
$GLOBALS['TYPO3_CONF_VARS']['LOG']['writerConfiguration'][\TYPO3\CMS\Core\Log\LogLevel::ERROR][\TYPO3\CMS\Core\Log\Writer\DatabaseWriter::class] = [];
