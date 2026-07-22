<?php
/*
 * Build-time patch for lochmueller/index 2.3.0.
 *
 * BootstrapPackageInlineContentType::... casts a DateTimeImmutable date field to
 * string with `(string) $item->get('date')`, which throws
 * "Object of class DateTimeImmutable could not be converted to string" and
 * aborts `index:queue` on any bootstrap-package timeline content. That crash
 * blocks nr-ai-search content vectorization. Format the date instead.
 *
 * Idempotent: only rewrites when the buggy line is present. Runs from the
 * composer-builder stage CWD (/app), so vendor/ is relative.
 */
$file = 'vendor/lochmueller/index/Classes/Indexing/Database/ContentType/BootstrapPackage/BootstrapPackageInlineContentType.php';

if (!is_file($file)) {
    fwrite(STDERR, "patch-lochmueller-index: {$file} not found — skipping\n");
    exit(0);
}

$source = file_get_contents($file);
$needle = "\$date = trim((string) \$item->get('date'));";
$replacement = "\$dateVal = \$item->get('date');\n"
    . "            \$date = \$dateVal instanceof \\DateTimeInterface ? \$dateVal->format('Y-m-d') : trim((string) \$dateVal);";

if (strpos($source, $needle) !== false) {
    file_put_contents($file, str_replace($needle, $replacement, $source));
    echo "patch-lochmueller-index: patched DateTimeImmutable date cast\n";
} else {
    echo "patch-lochmueller-index: buggy line not found (already patched or upstream changed)\n";
}
