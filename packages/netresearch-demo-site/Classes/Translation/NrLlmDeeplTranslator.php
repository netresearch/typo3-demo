<?php

/*
 * Copyright (c) 2026 Netresearch DTT GmbH
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

declare(strict_types=1);

namespace Netresearch\DemoSite\Translation;

use DeepL\Language;
use DeepL\TextResult;
use DeepL\Translator;
use Netresearch\NrLlm\Service\Feature\TranslationServiceInterface;
use Netresearch\NrLlm\Service\Option\TranslationOptions;

/**
 * Routes EXT:autotranslate's translations through nr-llm.
 *
 * autotranslate has no provider hook of its own; a local composer patch
 * (patches/thieleundklose-autotranslate-translator-hook.patch) teaches its
 * DeeplApiHelper to resolve the class named in
 * $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['autotranslate']['translatorClass']
 * from the container instead of building a DeepL client — deliberately a
 * demo-local patch, not an upstream PR, until upstream ships a real hook.
 * The class EXTENDS \DeepL\Translator so every type hint in autotranslate's
 * private translation flow keeps holding; the parent is constructed with a
 * placeholder key and none of its HTTP paths are reachable through the
 * overridden methods. autotranslate's own DeepL key stays unused.
 *
 * Registered as a PUBLIC service in the demo-site Services.yaml (the patch
 * resolves it via the container).
 */
final class NrLlmDeeplTranslator extends Translator
{
    private readonly TranslationServiceInterface $translationService;

    public function __construct(TranslationServiceInterface $translationService)
    {
        // The parent validates the key format only; no HTTP happens here.
        // Its client is never used — every provider-reaching method that
        // autotranslate calls is overridden below.
        parent::__construct('nr-llm-routed');
        $this->translationService = $translationService;
    }

    /**
     * Signature mirrors \DeepL\Translator::translateText() (deepl-php 1.x).
     *
     * @param string|string[] $texts
     * @param array<string, mixed> $options
     *
     * @return TextResult|TextResult[]
     */
    public function translateText($texts, ?string $sourceLang, string $targetLang, array $options = [])
    {
        $sourceLanguage = $this->stripRegion($sourceLang);
        $targetLanguage = $this->stripRegion($targetLang) ?? 'en';

        $results = [];
        foreach (is_array($texts) ? $texts : [$texts] as $text) {
            $result = $this->translationService->translate(
                (string)$text,
                $targetLanguage,
                $sourceLanguage,
                new TranslationOptions(preserveFormatting: true),
            );

            $results[] = new TextResult(
                $result->translation,
                $sourceLanguage ?? $targetLanguage,
                strlen((string)$text),
            );
        }

        return is_array($texts) ? $results : $results[0];
    }

    /**
     * Static catalogue for the site-configuration dropdowns — the only
     * consumer of these lists. nr-llm's LLM path is not limited to them;
     * DeepL's own catalogue is used because autotranslate stores
     * DeepL-shaped language codes in the site configuration.
     *
     * @return Language[]
     */
    public function getSourceLanguages(): array
    {
        return array_map(
            static fn(string $code): Language => new Language($code, $code, null),
            ['bg', 'cs', 'da', 'de', 'el', 'en', 'es', 'et', 'fi', 'fr', 'hu', 'id', 'it', 'ja', 'ko', 'lt', 'lv', 'nb', 'nl', 'pl', 'pt', 'ro', 'ru', 'sk', 'sl', 'sv', 'tr', 'uk', 'zh'],
        );
    }

    /** @return Language[] */
    public function getTargetLanguages(): array
    {
        return array_map(
            static fn(string $code): Language => new Language($code, $code, in_array($code, ['de', 'es', 'fr', 'it', 'ja', 'nl', 'pl', 'pt-BR', 'pt-PT', 'ru'], true)),
            ['bg', 'cs', 'da', 'de', 'el', 'en-GB', 'en-US', 'es', 'et', 'fi', 'fr', 'hu', 'id', 'it', 'ja', 'ko', 'lt', 'lv', 'nb', 'nl', 'pl', 'pt-BR', 'pt-PT', 'ro', 'ru', 'sk', 'sl', 'sv', 'tr', 'uk', 'zh'],
        );
    }

    /**
     * DeepL codes may carry a region (en-GB, pt-BR); nr-llm expects the
     * ISO 639-1 base code.
     */
    private function stripRegion(?string $language): ?string
    {
        if ($language === null || $language === '') {
            return null;
        }

        return strtolower(explode('-', $language)[0]);
    }
}
