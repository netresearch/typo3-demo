<?php

declare(strict_types=1);

// Posts the social webhook test receiver accepted
// (Classes/Middleware/SocialWebhookTestReceiver.php). Admins only, on the root
// page, and read-only: each row is what nr_repurpose sent, as it arrived.
return [
    'ctrl' => [
        'title' => 'Social webhook test receipt',
        'label' => 'platform',
        'label_alt' => 'crdate',
        'label_alt_force' => true,
        'crdate' => 'crdate',
        'tstamp' => 'tstamp',
        'default_sortby' => 'crdate DESC',
        'rootLevel' => 1,
        'adminOnly' => true,
        'readOnly' => true,
        'hideAtCopy' => true,
        'typeicon_classes' => [
            'default' => 'actions-message',
        ],
    ],
    'columns' => [
        'crdate' => [
            'label' => 'Received',
            'config' => [
                'type' => 'datetime',
                'readOnly' => true,
            ],
        ],
        'platform' => [
            'label' => 'Platform',
            'config' => [
                'type' => 'input',
                'readOnly' => true,
            ],
        ],
        'publish_at' => [
            'label' => 'Publish at (from the post)',
            'config' => [
                'type' => 'datetime',
                'readOnly' => true,
            ],
        ],
        'post_text' => [
            'label' => 'Text',
            'config' => [
                'type' => 'text',
                'rows' => 8,
                'readOnly' => true,
            ],
        ],
        'artifact_uid' => [
            'label' => 'nr_repurpose artifact uid',
            'config' => [
                'type' => 'number',
                'readOnly' => true,
            ],
        ],
        'job_uid' => [
            'label' => 'nr_repurpose job uid',
            'config' => [
                'type' => 'number',
                'readOnly' => true,
            ],
        ],
        'source_url' => [
            'label' => 'Source URL',
            'config' => [
                'type' => 'input',
                'readOnly' => true,
            ],
        ],
        'payload' => [
            'label' => 'Payload as received (JSON)',
            'config' => [
                'type' => 'text',
                'rows' => 12,
                'fixedFont' => true,
                'readOnly' => true,
            ],
        ],
    ],
    'types' => [
        '0' => [
            'showitem' => 'crdate, platform, publish_at, post_text, artifact_uid, job_uid, source_url, payload',
        ],
    ],
];
