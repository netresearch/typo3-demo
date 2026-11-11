<?php

declare(strict_types=1);

namespace Netresearch\DemoSite\Middleware;

use Netresearch\NrVault\Security\TechnicalActorContextInterface;
use Netresearch\NrVault\Service\VaultServiceInterface;
use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Psr\Log\LoggerInterface;
use Throwable;
use TYPO3\CMS\Core\Configuration\ExtensionConfiguration;
use TYPO3\CMS\Core\Database\ConnectionPool;

/**
 * Test receiver for the social webhook of nr_repurpose.
 *
 * nr_repurpose sends an approved social post, once it is due, as JSON by POST to
 * its extension setting socialWebhookUrl. On this demo that URL points here, so
 * the demo shows that a post arrives without posting to a real network. Each
 * accepted post becomes a row of tx_netresearchdemosite_social_webhook_receipt,
 * an admin-only table on the root page (Content > Records, page 0).
 *
 * The endpoint is public, so it accepts a post only with a valid signature:
 * nr_repurpose signs the body with the nr-vault secret named in its setting
 * socialWebhookSecretIdentifier (header X-Nr-Repurpose-Signature: sha256=<hex
 * HMAC-SHA256 of the body>). The secret is read here as the same backend user
 * that signs with it (nr_repurpose technicalBeUserUid), so nothing else needs
 * access to it. A request without a well-formed signature header is refused
 * before the vault is asked.
 *
 * Every refusal has its own status code, because nr_repurpose stores
 * "Webhook answered HTTP <code>" as the post's error, and that is the only
 * diagnosis the backend shows. Requests other than POST to this path pass on to
 * the site, which answers them as an unknown page.
 */
final readonly class SocialWebhookTestReceiver implements MiddlewareInterface
{
    public const string PATH = '/_social-webhook-test';

    public const string TABLE = 'tx_netresearchdemosite_social_webhook_receipt';

    public const string SIGNATURE_HEADER = 'X-Nr-Repurpose-Signature';

    /** nr_repurpose posts a few kilobytes; anything far above that is not one of its posts. */
    public const int MAX_BODY_BYTES = 65536;

    public function __construct(
        private ResponseFactoryInterface $responseFactory,
        private ConnectionPool $connectionPool,
        private ExtensionConfiguration $extensionConfiguration,
        private VaultServiceInterface $vault,
        private TechnicalActorContextInterface $technicalActor,
        private LoggerInterface $logger,
    ) {}

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        if ($request->getUri()->getPath() !== self::PATH || $request->getMethod() !== 'POST') {
            return $handler->handle($request);
        }

        try {
            $body = self::readAtMost($request, self::MAX_BODY_BYTES + 1);
            $this->store($body, $this->verifiedPost($request, $body));
        } catch (RefusedWebhookRequest $refusal) {
            // Warning, not error: an unsigned request from anybody is expected on a
            // public URL, and only ERROR and above go to sys_log on this instance.
            $this->logger->warning('Social webhook test receiver refused a request: ' . $refusal->getMessage(), ['status' => $refusal->getCode()]);

            return $this->responseFactory->createResponse($refusal->getCode());
        }

        return $this->responseFactory->createResponse(204);
    }

    /**
     * The decoded post, once size and signature are checked.
     *
     * @return array<array-key, mixed>
     * @throws RefusedWebhookRequest
     */
    private function verifiedPost(ServerRequestInterface $request, string $body): array
    {
        if (strlen($body) > self::MAX_BODY_BYTES) {
            throw new RefusedWebhookRequest(413, 'body larger than ' . self::MAX_BODY_BYTES . ' bytes');
        }

        $signature = $request->getHeaderLine(self::SIGNATURE_HEADER);
        if (preg_match('/^sha256=[0-9a-f]{64}$/D', $signature) !== 1) {
            throw new RefusedWebhookRequest(401, 'no well-formed signature header');
        }

        $secret = $this->secret();
        if ($secret === null) {
            throw new RefusedWebhookRequest(503, 'signing secret not readable');
        }

        if (!hash_equals('sha256=' . hash_hmac('sha256', $body, $secret), $signature)) {
            throw new RefusedWebhookRequest(403, 'signature does not match');
        }

        // Decoded to objects: as an array, a JSON list such as [] would pass too.
        try {
            $post = json_decode($body, false, 16, JSON_THROW_ON_ERROR);
        } catch (Throwable) {
            $post = null;
        }
        if (!$post instanceof \stdClass) {
            throw new RefusedWebhookRequest(400, 'body is not a JSON object');
        }

        return get_object_vars($post);
    }

    /**
     * @param array<array-key, mixed> $post
     * @throws RefusedWebhookRequest
     */
    private function store(string $body, array $post): void
    {
        try {
            $now = time();
            $this->connectionPool->getConnectionForTable(self::TABLE)->insert(self::TABLE, [
                'pid' => 0,
                'crdate' => $now,
                'tstamp' => $now,
                'platform' => mb_substr(self::string($post['platform'] ?? ''), 0, 64),
                'post_text' => self::string($post['text'] ?? ''),
                'publish_at' => self::timestamp($post['publishAt'] ?? ''),
                'artifact_uid' => self::uid($post['artifactUid'] ?? 0),
                'job_uid' => self::uid($post['jobUid'] ?? 0),
                'source_url' => self::string($post['sourceUrl'] ?? ''),
                'payload' => $body,
            ]);
        } catch (Throwable $e) {
            $this->logger->error('Social webhook test receiver could not store a signed post', ['exception' => $e]);

            throw new RefusedWebhookRequest(500, 'post could not be stored');
        }
    }

    private function secret(): ?string
    {
        $identifier = $this->repurposeSetting('socialWebhookSecretIdentifier');
        $actorUid = (int)$this->repurposeSetting('technicalBeUserUid');
        if ($identifier === '' || $actorUid <= 0) {
            $this->logger->error('Social webhook test receiver has no secret identifier or technical user in the nr_repurpose settings');

            return null;
        }

        try {
            $secret = $this->technicalActor->runAs($actorUid, fn(): ?string => $this->vault->retrieve($identifier));
        } catch (Throwable $e) {
            $this->logger->error('Social webhook test receiver could not read the signing secret', ['identifier' => $identifier, 'exception' => $e]);

            return null;
        }

        return is_string($secret) && $secret !== '' ? $secret : null;
    }

    private function repurposeSetting(string $key): string
    {
        try {
            $value = $this->extensionConfiguration->get('nr_repurpose', $key);
        } catch (Throwable) {
            return '';
        }

        return is_scalar($value) ? trim((string)$value) : '';
    }

    /** Reads the body up to $limit bytes, so an oversized upload is refused without holding all of it. */
    private static function readAtMost(ServerRequestInterface $request, int $limit): string
    {
        $stream = $request->getBody();
        if ($stream->isSeekable()) {
            $stream->rewind();
        }
        $body = '';
        while (!$stream->eof() && strlen($body) < $limit) {
            $chunk = $stream->read($limit - strlen($body));
            if ($chunk === '') {
                break;
            }
            $body .= $chunk;
        }

        return $body;
    }

    private static function string(mixed $value): string
    {
        return is_string($value) ? $value : '';
    }

    private static function uid(mixed $value): int
    {
        return is_int($value) && $value > 0 ? $value : 0;
    }

    private static function timestamp(mixed $value): int
    {
        $time = is_string($value) ? strtotime($value) : false;

        return $time === false || $time < 0 ? 0 : $time;
    }
}
