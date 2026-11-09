<?php

declare(strict_types=1);

namespace Netresearch\DemoSite\Log\Writer;

use TYPO3\CMS\Core\Log\LogRecord;
use TYPO3\CMS\Core\Log\Writer\DatabaseWriter;

/**
 * Core's DatabaseWriter, bounded to what sys_log can store.
 *
 * sys_log.message and sys_log.data are TEXT columns, which hold 65,535 bytes.
 * Core writes the full exception string, trace included, into data. When that
 * exceeds the column, MariaDB in strict mode rejects the insert, the logger
 * throws, and the request that only wanted to log an error ends with HTTP 500.
 *
 * This writer cuts both fields to fit. An oversized context is replaced by an
 * excerpt that starts with the exception text, so message and first trace
 * frames stay readable. The full record still goes to the file log, because
 * the record handed to the other writers is not modified.
 */
final class BoundedDatabaseWriter extends DatabaseWriter
{
    public const MAX_BYTES = 65535;

    public function writeLog(LogRecord $record)
    {
        $message = (string)$record->getMessage();
        $context = $record->getData();
        $boundedMessage = self::boundMessage($message);
        $boundedContext = self::boundContext($context);
        if ($boundedMessage !== $message || $boundedContext !== $context) {
            $record = clone $record;
            $record->setMessage($boundedMessage);
            $record->setData($boundedContext);
        }

        return parent::writeLog($record);
    }

    public static function boundMessage(string $message): string
    {
        if (strlen($message) <= self::MAX_BYTES) {
            return $message;
        }
        $suffix = ' [truncated]';

        return mb_strcut($message, 0, self::MAX_BYTES - strlen($suffix), 'UTF-8') . $suffix;
    }

    /**
     * @param array<array-key, mixed> $context
     * @return array<array-key, mixed>
     */
    public static function boundContext(array $context): array
    {
        if (isset($context['exception']) && $context['exception'] instanceof \Throwable) {
            $context['exception'] = (string)$context['exception'];
        }
        $encoded = json_encode($context, JSON_INVALID_UTF8_SUBSTITUTE | JSON_PARTIAL_OUTPUT_ON_ERROR);
        if ($encoded === false || strlen($encoded) <= self::MAX_BYTES) {
            return $context;
        }

        $source = is_string($context['exception'] ?? null) ? $context['exception'] : $encoded;
        $length = intdiv(self::MAX_BYTES, 2);
        do {
            $bounded = [
                'truncated' => true,
                'originalBytes' => strlen($encoded),
                'excerpt' => mb_strcut($source, 0, $length, 'UTF-8'),
            ];
            $length = intdiv($length * 4, 5);
            $size = strlen((string)json_encode($bounded, JSON_INVALID_UTF8_SUBSTITUTE));
        } while ($size > self::MAX_BYTES && $length > 0);

        return $bounded;
    }
}
