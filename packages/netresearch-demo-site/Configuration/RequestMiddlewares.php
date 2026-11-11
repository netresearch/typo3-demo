<?php

declare(strict_types=1);

use Netresearch\DemoSite\Middleware\SocialWebhookTestReceiver;

return [
    'frontend' => [
        // Before site resolution: the receiver answers a fixed path on any host
        // TYPO3 accepts and needs nothing from the site or the page tree.
        'netresearch-demo-site/social-webhook-test-receiver' => [
            'target' => SocialWebhookTestReceiver::class,
            'after' => [
                'typo3/cms-core/verify-host-header',
            ],
            'before' => [
                'typo3/cms-frontend/site',
            ],
        ],
    ],
];
