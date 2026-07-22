<?php

declare(strict_types=1);

namespace Netresearch\DemoSite\Command;

use ApacheSolrForTypo3\Solr\Domain\Index\IndexService;
use ApacheSolrForTypo3\Solr\Domain\Index\Queue\QueueInitializationService;
use ApacheSolrForTypo3\Solr\Domain\Site\Site;
use ApacheSolrForTypo3\Solr\Domain\Site\SiteRepository;
use ApacheSolrForTypo3\Solr\IndexQueue\Queue;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;
use TYPO3\CMS\Core\Utility\GeneralUtility;

/**
 * Fills the Apache Solr index for the demo site in-process.
 *
 * EXT:solr (14.0) ships no CLI indexing command — indexing is normally driven by
 * the backend Index Queue module plus the Index Queue Worker scheduler task.
 * This command reproduces that flow so the demo can index end-to-end from the
 * container entrypoint: it (re)initializes the index queue from the site's
 * index-queue configuration and then indexes all pending items in batches.
 *
 * The indexing sub-request needs a site base with a real host, otherwise EXT:solr
 * throws SolrIndexRuntimeException 1741200001 and stored result URLs are hostless.
 * The entrypoint therefore runs this command with TYPO3_SITE_BASE set to the real
 * domain.
 */
#[AsCommand(
    name: 'demo:solr:index',
    description: 'Initialize the EXT:solr index queue for the demo site (root page 1) and index all pending items in-process.',
)]
final class SolrIndexCommand extends Command
{
    private const ROOT_PAGE_ID = 1;

    private const BATCH_SIZE = 50;

    private const MAX_ITERATIONS = 1000;

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);

        $siteRepository = GeneralUtility::makeInstance(SiteRepository::class);
        $site = $siteRepository->getSiteByRootPageId(self::ROOT_PAGE_ID);
        if (!$site instanceof Site) {
            $io->error(sprintf('No EXT:solr site found for root page %d.', self::ROOT_PAGE_ID));

            return Command::FAILURE;
        }

        // Fill the index queue from every index-queue configuration on the site.
        $queueInitializationService = GeneralUtility::makeInstance(QueueInitializationService::class);
        $queueInitializationService->initializeBySiteAndIndexConfiguration($site, '*');

        $queue = GeneralUtility::makeInstance(Queue::class);
        $indexService = GeneralUtility::makeInstance(IndexService::class, $site);

        $pending = $queue->getStatisticsBySite($site)->getPendingCount();
        $io->writeln(sprintf('Index queue initialized: %d item(s) pending.', $pending));

        $iterations = 0;
        while ($queue->getStatisticsBySite($site)->getPendingCount() > 0) {
            if ($iterations >= self::MAX_ITERATIONS) {
                $io->warning(sprintf(
                    'Stopped after %d iterations with %d item(s) still pending.',
                    $iterations,
                    $queue->getStatisticsBySite($site)->getPendingCount(),
                ));

                return Command::FAILURE;
            }

            $indexService->indexItems(self::BATCH_SIZE);
            ++$iterations;
        }

        $statistics = $queue->getStatisticsBySite($site);
        $io->success(sprintf(
            'Solr indexing complete: %d document(s) indexed, %d failed, in %d batch(es).',
            $statistics->getSuccessCount(),
            $statistics->getFailedCount(),
            $iterations,
        ));

        return Command::SUCCESS;
    }
}
