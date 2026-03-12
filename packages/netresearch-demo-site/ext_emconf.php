<?php

$EM_CONF[$_EXTKEY] = [
    'title' => 'Netresearch Demo Site',
    'description' => 'Site package for the Netresearch TYPO3 Demo',
    'category' => 'templates',
    'state' => 'stable',
    'version' => '1.0.0',
    'constraints' => [
        'depends' => [
            'typo3' => '14.0.0-14.99.99',
            'bootstrap_package' => '16.0.0-16.99.99',
        ],
    ],
];
