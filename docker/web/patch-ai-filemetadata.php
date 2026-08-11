<?php
/*
 * Build-time patch for mfd/ai-filemetadata 1.6.1.
 *
 * EnrichFileMetadataAfterCreation::__invoke() guards the whole listener behind
 * generateAltTextInFrontend():
 *
 *     if (!$this->configurationService->generateAltTextInFrontend()) return;
 *
 * The setting is named for the frontend but gates the UPLOAD path too, so
 * turning frontend generation off silently turns automatic alt texts on upload
 * off as well — even with generateAltTextOnFileUpload = 1. Measured on this
 * instance: adding a file produced a metadata row with an empty `alternative`,
 * while the very same generation path returns a correct German alt text in
 * 1.8s when called directly.
 *
 * The guard is not pointless: AfterFileMetaDataCreatedEvent can fire during a
 * frontend request when a file is indexed on demand, and the listener cannot
 * otherwise tell the contexts apart — so it conservatively refuses everywhere.
 * This patch keeps that protection exactly where it belongs and drops it where
 * it does not: the flag is enforced only IN a frontend request. Backend uploads
 * and CLI runs proceed.
 *
 * No visitor-facing request gains a synchronous API call from this, which is
 * the reason the demo sets the flag to 0 in the first place.
 *
 * Idempotent: only rewrites when the original guard is present. Runs from the
 * composer-builder stage CWD (/app), so vendor/ is relative.
 */
$file = 'vendor/mfd/ai-filemetadata/Classes/EventListener/EnrichFileMetadataAfterCreation.php';

if (!is_file($file)) {
    fwrite(STDERR, "patch-ai-filemetadata: {$file} not found — skipping\n");
    exit(0);
}

$source = file_get_contents($file);

$needle = "        if (!\$this->configurationService->generateAltTextInFrontend()) {\n"
    . "            return;\n"
    . "        }";

$replacement = "        // Patched at build time (docker/web/patch-ai-filemetadata.php): enforce the\n"
    . "        // frontend flag only inside a frontend request, so a backend upload or a CLI\n"
    . "        // run still generates while a visitor's request never triggers an API call.\n"
    . "        \$request = \$GLOBALS['TYPO3_REQUEST'] ?? null;\n"
    . "        \$isFrontend = \$request instanceof \\Psr\\Http\\Message\\ServerRequestInterface\n"
    . "            && \\TYPO3\\CMS\\Core\\Http\\ApplicationType::fromRequest(\$request)->isFrontend();\n"
    . "        if (\$isFrontend && !\$this->configurationService->generateAltTextInFrontend()) {\n"
    . "            return;\n"
    . "        }";

if (strpos($source, $needle) !== false) {
    file_put_contents($file, str_replace($needle, $replacement, $source));
    echo "patch-ai-filemetadata: frontend guard now applies only to frontend requests\n";
} else {
    echo "patch-ai-filemetadata: guard not found (already patched or upstream changed)\n";
}
