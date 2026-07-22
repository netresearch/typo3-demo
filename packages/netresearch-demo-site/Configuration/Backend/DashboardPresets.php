<?php

declare(strict_types=1);

/*
 * Overrides the 'default' dashboard preset shipped by EXT:dashboard.
 *
 * The dashboard ServiceProvider merges Configuration/Backend/DashboardPresets.php
 * from every active package in dependency-sorted order (later packages win via
 * array_merge). This site package depends on typo3/cms-dashboard, so it is
 * sorted after it and this 'default' definition replaces the core one. Every
 * backend user's auto-created dashboard therefore shows the Netresearch demo
 * cards on first open.
 */

return [
    'default' => [
        'title' => 'Netresearch Demo',
        'description' => 'Overview of the Netresearch TYPO3 extensions showcased on this demo instance.',
        'iconIdentifier' => 'content-dashboard',
        'defaultWidgets' => [
            'nrdemo.llm',
            'nrdemo.mcpagent',
            'nrdemo.landingpage',
            'nrdemo.cowriter',
            'nrdemo.rteimage',
            'nrdemo.repurpose',
            'nrdemo.passkeysbe',
            'nrdemo.passkeysfe',
            'nrdemo.vault',
            'nrdemo.temporalcache',
            't3information',
        ],
        'showInWizard' => true,
    ],
    // Second dashboard: the extensions' OWN dashboard widgets (live data),
    // as opposed to the explainer cards on the 'default' dashboard. Presets
    // only auto-create the first dashboard, so this one is also seeded into
    // be_dashboards for the existing demo users in data/seed-extensions.sql.
    'netresearch-widgets' => [
        'title' => 'Netresearch Widgets',
        'description' => 'Live dashboard widgets provided by the Netresearch extensions (nr-llm, nr-vault, passkeys).',
        'iconIdentifier' => 'content-widget-chart-bar',
        'defaultWidgets' => [
            'nrllm-monthly-cost',
            'nrllm-requests-by-provider',
            'nrvault-secrets',
            'nrvault-audit-activity',
            'nrpasskeysbe-adoption',
            'nrpasskeysbe-credentials',
            'nrpasskeysfe-adoption',
            'nrpasskeysfe-credentials',
        ],
        'showInWizard' => true,
    ],
];
