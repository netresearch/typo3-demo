<?php

declare(strict_types=1);

defined('TYPO3') or die();

// Register demo site RTE preset (extends Bootstrap Package + rte_ckeditor_image + cowriter)
$GLOBALS['TYPO3_CONF_VARS']['RTE']['Presets']['default'] = 'EXT:netresearch_demo_site/Configuration/RTE/Default.yaml';
