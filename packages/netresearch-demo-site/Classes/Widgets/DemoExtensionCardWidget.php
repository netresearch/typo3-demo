<?php

declare(strict_types=1);

/*
 * This file is part of the Netresearch TYPO3 Demo.
 *
 * It is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, either version 2
 * of the License, or any later version.
 */

namespace Netresearch\DemoSite\Widgets;

use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Backend\Routing\Exception\RouteNotFoundException;
use TYPO3\CMS\Backend\Routing\UriBuilder;
use TYPO3\CMS\Backend\View\BackendViewFactory;
use TYPO3\CMS\Dashboard\Widgets\AdditionalCssInterface;
use TYPO3\CMS\Dashboard\Widgets\RequestAwareWidgetInterface;
use TYPO3\CMS\Dashboard\Widgets\WidgetConfigurationInterface;
use TYPO3\CMS\Dashboard\Widgets\WidgetInterface;

/**
 * Reusable dashboard card presenting one Netresearch demo extension.
 *
 * Options (set per widget instance in Services.yaml):
 * - description  string        1-2 sentences on what the extension does
 * - howTo        list<string>  concrete demo steps in the backend
 * - moduleRoute  string        backend module route identifier for the CTA button (optional)
 * - buttonLabel  string        label of the CTA button (optional, used with moduleRoute)
 */
final class DemoExtensionCardWidget implements WidgetInterface, RequestAwareWidgetInterface, AdditionalCssInterface
{
    private ServerRequestInterface $request;

    public function __construct(
        private readonly WidgetConfigurationInterface $configuration,
        private readonly BackendViewFactory $backendViewFactory,
        private readonly UriBuilder $uriBuilder,
        private readonly array $options = [],
    ) {}

    public function setRequest(ServerRequestInterface $request): void
    {
        $this->request = $request;
    }

    public function renderWidgetContent(): string
    {
        $moduleUri = '';
        $moduleRoute = (string)($this->options['moduleRoute'] ?? '');
        if ($moduleRoute !== '') {
            try {
                $moduleUri = (string)$this->uriBuilder->buildUriFromRoute($moduleRoute);
            } catch (RouteNotFoundException) {
                // Extension providing the module is not installed — render the card without a button.
            }
        }

        $view = $this->backendViewFactory->create(
            $this->request,
            ['typo3/cms-dashboard', 'netresearch/typo3-demo-site']
        );
        $view->assignMultiple([
            'configuration' => $this->configuration,
            'description' => (string)($this->options['description'] ?? ''),
            'howTo' => (array)($this->options['howTo'] ?? []),
            'moduleUri' => $moduleUri,
            'buttonLabel' => (string)($this->options['buttonLabel'] ?? 'Open module'),
        ]);

        return $view->render('Widget/DemoExtensionCard');
    }

    /**
     * The dashboard loads these once per page, not once per widget, so all
     * eighteen cards share the single file.
     */
    public function getCssFiles(): array
    {
        return ['EXT:netresearch_demo_site/Resources/Public/Css/demo-extension-card.css'];
    }

    public function getOptions(): array
    {
        return $this->options;
    }
}
