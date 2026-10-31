<?php

declare(strict_types=1);

namespace Netresearch\DemoSite\Command;

use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Backend\Routing\UriBuilder;
use TYPO3\CMS\Core\Core\Environment;
use TYPO3\CMS\Install\SystemEnvironment\ServerResponse\FileLocation;
use TYPO3\CMS\Install\SystemEnvironment\ServerResponse\ServerResponseCheck;

/**
 * Core's ServerResponseCheck with probe URLs that also work on the CLI.
 *
 * FileLocation::getBaseUrl() joins the request host with
 * PathUtility::getAbsoluteWebPath(), which drops the leading slash on the CLI
 * ("fileadmin/x.tmp/"). Every probe URL then reads
 * "http://127.0.0.1fileadmin/...", no request ever leaves the process, and the
 * check reports OK because it ignores requests that got no response. The
 * probes, their expectations and the evaluation stay core's, including that
 * gap: a single probe that times out still counts as passed. The command only
 * guards against the probe base not answering at all.
 *
 * @internal Builds on @internal core classes; re-check on every TYPO3 update.
 */
final class CliServerResponseCheck extends ServerResponseCheck
{
    public function __construct(UriBuilder $uriBuilder, bool $useMarkup = true)
    {
        parent::__construct($uriBuilder, $useMarkup);
        $folderName = bin2hex(random_bytes(4));
        $fileadminDir = rtrim($GLOBALS['TYPO3_CONF_VARS']['BE']['fileadminDir'] ?? 'fileadmin', '/');
        $this->assetLocation = self::cliLocation(sprintf('/typo3temp/assets/%s.tmp/', $folderName));
        $this->fileadminLocation = self::cliLocation(sprintf('/%s/%s.tmp/', $fileadminDir, $folderName));
        $this->fileDeclarations = $this->initializeFileDeclarations(bin2hex(random_bytes(4)));
    }

    private static function cliLocation(string $path): FileLocation
    {
        return new class ($path) extends FileLocation {
            public function getBaseUrl(ServerRequestInterface $request): string
            {
                return $request->getAttribute('normalizedParams')->getRequestHost()
                    . '/' . ltrim(substr($this->filePath, strlen(Environment::getPublicPath())), '/');
            }
        };
    }
}
