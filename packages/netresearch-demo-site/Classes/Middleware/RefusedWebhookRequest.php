<?php

declare(strict_types=1);

namespace Netresearch\DemoSite\Middleware;

use RuntimeException;

/**
 * A request the social webhook test receiver does not accept. The code is the
 * HTTP status it answers with; the message is the reason for the log only.
 */
final class RefusedWebhookRequest extends RuntimeException
{
    public function __construct(int $status, string $reason)
    {
        parent::__construct($reason, $status);
    }
}
