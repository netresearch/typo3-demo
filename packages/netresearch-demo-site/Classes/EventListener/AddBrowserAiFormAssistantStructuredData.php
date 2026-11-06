<?php

declare(strict_types=1);

namespace Netresearch\DemoSite\EventListener;

use Brotkrueml\Schema\Core\Model\NodeIdentifier;
use Brotkrueml\Schema\Event\RenderAdditionalTypesEvent;
use Brotkrueml\Schema\Type\TypeFactory;
use TYPO3\CMS\Core\Attribute\AsEventListener;
use TYPO3\CMS\Core\Http\NormalizedParams;
use TYPO3\CMS\Core\Site\Entity\SiteLanguage;
use TYPO3\CMS\Frontend\Page\PageInformation;

/**
 * Structured data for the Browser AI form assistant page (9004): what the
 * plugin is, and the chain it demonstrates as a HowTo, so an answer engine can
 * state what the page shows without parsing its prose.
 *
 * A listener rather than a SCHEMA object in TypoScript: the HowTo carries a
 * list of four HowToStep nodes, and a SCHEMA object cannot express a list of
 * typed nodes (brotkrueml/schema, TypoScript chapter). The four steps are the
 * four the page itself lists under "How it works".
 *
 * The site-wide WebSite and Organization nodes come from the SCHEMA objects in
 * the NetresearchDemo set; "author" points at that Organization by @id.
 */
#[AsEventListener(identifier: 'netresearch-demo-site/browser-ai-form-assistant-structured-data')]
final readonly class AddBrowserAiFormAssistantStructuredData
{
    private const PAGE_UID = 9004;
    private const PAGE_PATH = 'extensions/browser-ai-form-assistant';
    private const ORGANIZATION_ID = 'https://www.netresearch.de/#organization';

    /**
     * name => text, in the order the page lists them.
     */
    private const STEPS = [
        'Intent' => "The sentence goes to the on-device model together with the form's own JSON Schema. The schema is a constraint rather than a suggestion: the model answers with JSON that fits it.",
        'Structured output' => "Those arguments are checked against the schema again before anything is touched. A value outside a field's option set, or a field the form does not have, stops the call and changes nothing.",
        'Tool call' => 'The values are written into the visible controls, so what the model understood is on screen in the same controls anybody would use by hand, and can be corrected there.',
        'Real action' => 'The form is read back in full, the model having set only what the sentence mentioned, and the query runs.',
    ];

    public function __construct(
        private TypeFactory $typeFactory,
    ) {}

    public function __invoke(RenderAdditionalTypesEvent $event): void
    {
        $request = $event->getRequest();
        $pageInformation = $request->getAttribute('frontend.page.information');
        if (!$pageInformation instanceof PageInformation || $pageInformation->getId() !== self::PAGE_UID) {
            return;
        }
        $normalizedParams = $request->getAttribute('normalizedParams');
        if (!$normalizedParams instanceof NormalizedParams) {
            return;
        }

        // TYPO3_SITE_URL, as for the site-wide nodes: the site base is "/".
        $pageUrl = $normalizedParams->getSiteUrl() . self::PAGE_PATH;
        $softwareId = $pageUrl . '#software';
        $language = $request->getAttribute('language');
        $languageCode = $language instanceof SiteLanguage ? $language->getLocale()->getLanguageCode() : '';

        $offer = $this->typeFactory->create('Offer')
            ->setProperty('price', '0')
            ->setProperty('priceCurrency', 'EUR');

        $software = $this->typeFactory->create('SoftwareApplication')
            ->setId($softwareId)
            ->setProperties([
                'name' => 'Browser AI form assistant',
                'alternateName' => 'netresearch/nr-browser-ai',
                'applicationCategory' => 'BrowserApplication',
                'applicationSubCategory' => 'TYPO3 extension',
                'operatingSystem' => 'Chrome 148 or newer with the on-device model available',
                'softwareRequirements' => 'Chrome built-in AI (Prompt API)',
                'url' => $pageUrl,
                'isAccessibleForFree' => true,
                'offers' => $offer,
                'author' => new NodeIdentifier(self::ORGANIZATION_ID),
                'featureList' => [
                    'Fills a parameter-rich form from a single sentence',
                    "Derives the parameters on the visitor's device, with no API key and no server call",
                    'Generates its JSON Schema from the form definition rather than by hand',
                    'Registers the same form as a tool for an in-browser agent via the model context',
                ],
                'description' => "A TYPO3 plugin that turns one sentence into the parameters of a form with seventy controls, runs it, and shows the result. The sentence never leaves the device: Chrome's built-in model produces JSON constrained by a schema generated from the form definition, and only the finished query goes out.",
            ]);

        // schema.org defines codeRepository on SoftwareSourceCode, not on
        // SoftwareApplication; the source code points at the application it builds.
        $sourceCode = $this->typeFactory->create('SoftwareSourceCode')
            ->setId($pageUrl . '#source')
            ->setProperty('codeRepository', 'https://github.com/netresearch/t3x-nr-browser-ai')
            ->setProperty('targetProduct', new NodeIdentifier($softwareId));

        $steps = [];
        $position = 0;
        foreach (self::STEPS as $name => $text) {
            $steps[] = $this->typeFactory->create('HowToStep')
                ->setProperty('position', ++$position)
                ->setProperty('name', $name)
                ->setProperty('text', $text);
        }

        $howTo = $this->typeFactory->create('HowTo')
            ->setId($pageUrl . '#howto')
            ->setProperty('name', 'How a sentence becomes a filled-in form and a real query')
            ->setProperty('inLanguage', $languageCode)
            ->setProperty('step', $steps);

        $event->addType($software, $sourceCode, $howTo);
    }
}
