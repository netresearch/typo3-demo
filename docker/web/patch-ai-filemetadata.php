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
 * This patch keeps that protection where it belongs and narrows the rest: the
 * listener runs only in an actual BACKEND request, which is what an upload is.
 * The first version said "not a frontend request", which also covered the CLI --
 * and nr_repurpose's job saves rendered PNGs to FAL, so every save called the
 * vision model. The listener has no try/catch, so one failure took nine of ten
 * artifacts with it.
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

$replacement = "        // Patched at build time (docker/web/patch-ai-filemetadata.php): run only in\n"
    . "        // an actual BACKEND request, which is what a file upload is.\n"
    . "        //\n"
    . "        // The first version of this patch asked for \"not a frontend request\", which\n"
    . "        // also let it run on the CLI. That broke nr_repurpose: its job saves rendered\n"
    . "        // PNGs to FAL, each save fired this listener, and the listener has no\n"
    . "        // try/catch at all - so a failed vision call (\"Invalid base64 image_url\")\n"
    . "        // propagated straight into the artifact generator and killed nine of ten\n"
    . "        // artifacts. Requiring a backend request keeps the upload feature and takes\n"
    . "        // the listener back out of every CLI job that touches an image.\n"
    . "        \$request = \$GLOBALS['TYPO3_REQUEST'] ?? null;\n"
    . "        \$isBackendRequest = \$request instanceof \\Psr\\Http\\Message\\ServerRequestInterface\n"
    . "            && \\TYPO3\\CMS\\Core\\Http\\ApplicationType::fromRequest(\$request)->isBackend();\n"
    . "        if (!\$isBackendRequest && !\$this->configurationService->generateAltTextInFrontend()) {\n"
    . "            return;\n"
    . "        }";

if (strpos($source, $needle) !== false) {
    file_put_contents($file, str_replace($needle, $replacement, $source));
    echo "patch-ai-filemetadata: listener now runs only in a backend request\n";
} else {
    echo "patch-ai-filemetadata: guard not found (already patched or upstream changed)\n";
}
