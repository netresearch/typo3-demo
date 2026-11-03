<?php

$EM_CONF[$_EXTKEY] = [
    'title' => 'Falkenquell Site',
    'description' => 'Site package for the fictional town Falkenquell in the Netresearch TYPO3 Demo',
    'category' => 'templates',
    'author' => 'Netresearch DTM GmbH',
    'author_email' => 'info@netresearch.de',
    'author_company' => 'Netresearch DTM GmbH',
    'state' => 'stable',
    'version' => '1.0.0',
    'constraints' => [
        'depends' => [
            'typo3' => '14.3.0-14.99.99',
            'bootstrap_package' => '16.0.0-16.99.99',
            'news' => '14.0.0-14.99.99',
            'sf_event_mgt' => '9.0.0-9.99.99',
        ],
    ],
];
