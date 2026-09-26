<?php

declare(strict_types=1);

namespace Netresearch\DemoSite\AiLabel;

use B13\AiLabel\Configuration\ApplicableTablesProvider;
use B13\AiLabel\Service\AiLabelApi;
use Netresearch\NrLlm\Domain\Enum\WriteKind;
use Netresearch\NrLlm\Domain\ValueObject\AiActorContext;
use Netresearch\NrLlm\Event\AfterAiRecordWrittenEvent;
use Netresearch\NrLlm\Service\Tool\ActingBackendUserResolverInterface;
use Netresearch\NrLlm\Service\Tool\AgentRunRepositoryInterface;
use Psr\Log\LoggerInterface;
use Throwable;
use TYPO3\CMS\Core\Attribute\AsEventListener;

/**
 * Flags every record an nr-llm agent run writes as AI-created or AI-modified in
 * EXT:ai_label, so the record carries the Article 50 marker in the backend and,
 * until an editor reviews it, on the website.
 *
 * nr-llm announces the write and leaves the reaction to the installation
 * (nr-llm ADR-187); EXT:ai_label owns the label. This listener only connects
 * the two. The flag is written in the name of the backend user who started the
 * run, resolved from the run the event names, because the request that
 * executes an approved write may belong to someone else (the approver, or the
 * queue worker).
 *
 * A table EXT:ai_label does not cover (a file reference, a news record) is
 * skipped. A failure is logged and not rethrown: the write has landed, and a
 * missing label must not turn it into a failed tool call.
 */
#[AsEventListener(identifier: 'netresearch-demo-site/flag-ai-written-record')]
final readonly class FlagAiWrittenRecord
{
    public function __construct(
        private AiLabelApi $aiLabelApi,
        private ApplicableTablesProvider $applicableTables,
        private AgentRunRepositoryInterface $agentRuns,
        private ActingBackendUserResolverInterface $userResolver,
        private LoggerInterface $logger,
    ) {}

    public function __invoke(AfterAiRecordWrittenEvent $event): void
    {
        $table = $event->record->table;
        $uid = $event->record->uid;
        if ($event->kind === WriteKind::DELETED || !$this->applicableTables->isTableApplicable($table)) {
            return;
        }

        try {
            $run = $this->agentRuns->findByUuid($event->correlationId);
            $user = $run === null ? null : $this->userResolver->resolve(AiActorContext::backendUser($run->beUser));
            if ($user === null) {
                $this->logger->warning('No backend user for AI run {run}; {record} is not flagged.', [
                    'run' => $event->correlationId,
                    'record' => (string)$event->record,
                ]);
                return;
            }

            if ($event->kind === WriteKind::CREATED) {
                $this->aiLabelApi->aiCreated($table, $uid, $user);
            } else {
                $this->aiLabelApi->aiModified($table, $uid, $user);
            }
        } catch (Throwable $e) {
            $this->logger->error('Could not flag {record} as AI-written for run {run}.', [
                'record' => (string)$event->record,
                'run' => $event->correlationId,
                'exception' => $e,
            ]);
        }
    }
}
