#!/usr/bin/env python3
"""Generate the eight extension-page diagrams (typo3-demo #206).

One visual grammar for all of them, so the pages do not end up with eight
different-looking pictures. Colours follow the Netresearch palette:

    #585961  text          6.96:1 on white  -- AA for all sizes
    #2F99A4  primary       3.38:1 on white  -- fills and large text only
    #FF4D00  accent        3.33:1 on white  -- one highlight per diagram
    #CCCDCC  borders       not for text

Text on a teal fill is white and never below 20px bold, which is "large text"
for WCAG and therefore inside AA at 3.38:1. Everything at body size is #585961
on white.

No web fonts: these are referenced with <img>, where a font declaration cannot
load anything. The stack degrades to whatever the viewer has.
"""
from __future__ import annotations

import html
from pathlib import Path
from typing import Callable

W, H = 1200, 520
FONT = "'Open Sans','Segoe UI',system-ui,-apple-system,sans-serif"
TEXT = "#585961"
PRIMARY = "#2F99A4"
ACCENT = "#FF4D00"
BORDER = "#CCCDCC"
DARK_TEAL = "#15585E"          # 8.1:1 on white, for teal-coloured body text
SOFT = "#F5F5F5"


def esc(s: str) -> str:
    return html.escape(s, quote=True)


# Every visible string passes through t() inside the drawing primitives, before
# wrap() runs -- so the German text is wrapped for German rather than inheriting
# the English line breaks. Layout coordinates are shared: a translation that
# overflows its box is a translation to shorten, not a second layout to maintain.
LANG = "en"
TR: dict[str, dict[str, str]] = {}

# Keyed on the exact English source string, so an edit upstream fails loudly
# in t() instead of silently shipping the English wording in a German file.
TR["de"] = {
    'Every answer is grounded in what the tools returned':
        'Jede Antwort stützt sich auf das, was die Werkzeuge geliefert haben',
    'Question in the backend':
        'Frage im Backend',
    '„Which pages changed today?“':
        '„Welche Seiten haben sich heute geändert?“',
    'AI Chat Agent':
        'KI-Chat-Agent',
    'built on NR LLM':
        'auf Basis von NR LLM',
    'calls':
        'ruft auf',
    'MCP tools':
        'MCP-Werkzeuge',
    'read and act':
        'lesen und handeln',
    'TYPO3 install':
        'TYPO3-Installation',
    'pages · content · records · backend users · logs · site configuration':
        'Seiten · Inhalte · Datensätze · Backend-Benutzer · Logs · Site-Konfiguration',
    'what the tools actually returned':
        'was die Werkzeuge tatsächlich lieferten',
    'Answer':
        'Antwort',
    'no invented facts':
        'keine erfundenen Fakten',
    'A tool call can also change content — the agent reads and acts.':
        'Ein Werkzeugaufruf kann Inhalte auch ändern — der Agent liest und handelt.',
    'Nothing about the page or the question leaves the device':
        'Nichts von Seite oder Frage verlässt das Gerät',
    'the visitor’s device':
        'das Gerät des Besuchers',
    'This page':
        'Diese Seite',
    'its rendered text':
        'ihr gerenderter Text',
    'Chrome built-in model':
        'In Chrome eingebautes Modell',
    'Gemini Nano, on device':
        'Gemini Nano, auf dem Gerät',
    'Answer in the page':
        'Antwort in der Seite',
    'Any server':
        'Irgendein Server',
    'TYPO3 · Netresearch · Google':
        'TYPO3 · Netresearch · Google',
    'never':
        'nie',
    'No server endpoint, no telemetry, no cookie, no stored dialogue.':
        'Kein Server-Endpunkt, keine Telemetrie, kein Cookie, kein gespeicherter Dialog.',
    'Needs Chrome 148 or newer and the downloaded model; without it the':
        'Braucht Chrome 148 oder neuer und das geladene Modell; ohne das zeigt das',
    'plugin shows the fallback the editor configured.':
        'Plugin den vom Redakteur konfigurierten Ersatz.',
    'The form definition is the tool contract':
        'Die Formulardefinition ist der Werkzeugvertrag',
    'One sentence':
        'Ein Satz',
    '„Wind gusts in Innsbruck for ten days“':
        '„Windböen in Innsbruck für zehn Tage“',
    'Schema from the form':
        'Schema aus dem Formular',
    'validators · options · labels':
        'Validatoren · Optionen · Beschriftungen',
    'On-device model':
        'Modell auf dem Gerät',
    'produces arguments':
        'erzeugt Argumente',
    'Validated':
        'Geprüft',
    'enum members checked':
        'Enum-Werte kontrolliert',
    'The form fills itself in, and runs':
        'Das Formular füllt sich selbst aus und läuft',
    'seventy controls · one MultiCheckbox is one array property':
        'siebzig Felder · eine MultiCheckbox ist eine Array-Eigenschaft',
    'result':
        'Ergebnis',
    'Answer with the data':
        'Antwort mit den Daten',
    'rendered as text nodes':
        'als Textknoten gerendert',
    'No server endpoint: the query runs from the page itself.':
        'Kein Server-Endpunkt: die Abfrage läuft aus der Seite selbst.',
    'One page tree instead of one tree per channel':
        'Ein Seitenbaum statt eines Baums je Kanal',
    'One page tree':
        'Ein Seitenbaum',
    'pages · menu entries · single content elements':
        'Seiten · Menüeinträge · einzelne Inhaltselemente',
    'Context matches?':
        'Kontext trifft zu?',
    'domain · GET parameter · IP range · HTTP header · session value, or an AND / OR / XOR combination of them':
        'Domain · GET-Parameter · IP-Bereich · HTTP-Header · Session-Wert, oder eine UND- / ODER- / XOR-Verknüpfung davon',
    'yes':
        'ja',
    'no':
        'nein',
    'Shown in this channel':
        'In diesem Kanal sichtbar',
    'Hidden in this channel':
        'In diesem Kanal verborgen',
    'Editors mark where something appears — no parallel tree to keep in sync.':
        'Redakteure markieren, wo etwas erscheint — kein Parallelbaum, der abgeglichen werden muss.',
    'No backend module, no extra table — the output is the sitemap':
        'Kein Backend-Modul, keine Zusatztabelle — die Ausgabe ist die Sitemap',
    'Pages and content elements':
        'Seiten und Inhaltselemente',
    'the images already referenced':
        'die bereits referenzierten Bilder',
    'Title and caption':
        'Titel und Bildunterschrift',
    'what editors entered on the image':
        'was Redakteure am Bild erfasst haben',
    'XmlSitemapDataProvider':
        'XmlSitemapDataProvider',
    'registered with EXT:seo':
        'bei EXT:seo registriert',
    'image sitemap XML':
        'Bilder-Sitemap-XML',
    'the Google image-sitemap schema, beside the core sitemap':
        'das Google-Bilder-Sitemap-Schema, neben der Core-Sitemap',
    'Nothing else to maintain':
        'Nichts weiter zu pflegen',
    'no scheduler run, no separate database table, no editor step':
        'kein Scheduler-Lauf, keine eigene Datenbanktabelle, kein Redaktionsschritt',
    'Its demo is the XML itself.':
        'Seine Demo ist das XML selbst.',
    'Same configuration everywhere, execution only where it belongs':
        'Überall dieselbe Konfiguration, Ausführung nur dort, wo sie hingehört',
    'Scheduler task':
        'Scheduler-Aufgabe',
    'built on the base classes':
        'auf den Basisklassen aufgebaut',
    'In this context?':
        'In diesem Kontext?',
    'Production / Staging / …':
        'Production / Staging / …',
    'Runs':
        'Läuft',
    'on failure':
        'bei Fehlschlag',
    'E-mail to the configured recipients':
        'E-Mail an die konfigurierten Empfänger',
    'own subject and message — not just a red row in the module':
        'eigener Betreff und Text — nicht nur eine rote Zeile im Modul',
    'Skipped, and says so':
        'Übersprungen, und sagt es',
    'Deployed unchanged':
        'Unverändert ausgerollt',
    'one configuration in the repository, gated per application context instead of edited per environment':
        'eine Konfiguration im Repository, je Anwendungskontext geschaltet statt je Umgebung bearbeitet',
    'Start from a page that already exists':
        'Ausgangspunkt ist eine Seite, die es schon gibt',
    'An existing page':
        'Eine vorhandene Seite',
    'the content you already published':
        'die bereits veröffentlichten Inhalte',
    'Repurpose':
        'Repurpose',
    'Social posts':
        'Social-Posts',
    'short copy per channel':
        'kurzer Text je Kanal',
    'Summaries':
        'Zusammenfassungen',
    'the gist, at length':
        'der Kern, in mehreren Längen',
    'Alternative phrasings':
        'Alternative Formulierungen',
    'tuned per audience':
        'auf die Zielgruppe abgestimmt',
    'Nothing is re-typed: the source is the page, not a fresh brief.':
        'Nichts wird neu getippt: Quelle ist die Seite, kein neues Briefing.',
    'TYPO3 Forge #14277: timed content stayed cached past its window':
        'TYPO3 Forge #14277: zeitgesteuerte Inhalte blieben über ihr Fenster hinaus im Cache',
    'content is visible':
        'Inhalt ist sichtbar',
    'starttime':
        'starttime',
    'endtime':
        'endtime',
    'cache cleared':
        'Cache geleert',
    'not yet shown':
        'noch nicht sichtbar',
    'no longer shown':
        'nicht mehr sichtbar',
    'Scoping':
        'Geltungsbereich',
    'a single page, a page tree, or every page':
        'eine Seite, ein Seitenbaum oder alle Seiten',
    'When':
        'Wann',
    'on demand, or on a Scheduler run':
        'auf Anforderung oder im Scheduler-Lauf',
    'Works with any content type that uses starttime and endtime.':
        'Funktioniert mit jedem Inhaltstyp, der starttime und endtime nutzt.',
    'How the AI Chat Agent answers':
        'Wie der KI-Chat-Agent antwortet',
    'A question typed in the TYPO3 backend goes to the chat agent, which calls MCP tools against pages, records, backend users, logs and site configuration, and answers from what those tools returned.':
        'Eine im TYPO3-Backend gestellte Frage geht an den Chat-Agenten. Der ruft MCP-Werkzeuge gegen Seiten, Datensätze, Backend-Benutzer, Logs und Site-Konfiguration auf und antwortet aus dem, was diese Werkzeuge geliefert haben.',
    'Where the answer is computed':
        'Wo die Antwort berechnet wird',
    "The page text and the question are handed to Chrome's built-in model on the visitor's own device. Nothing about the page or the dialogue is sent to a server.":
        'Seitentext und Frage gehen an das in Chrome eingebaute Modell auf dem Gerät des Besuchers. Nichts über die Seite oder den Dialog wird an einen Server gesendet.',
    'One sentence fills a seventy-control form':
        'Ein Satz füllt ein Formular mit siebzig Feldern',
    'The form definition itself becomes the tool contract: its validators, options and descriptions are turned into a schema, the on-device model produces arguments against it, and the filled form runs.':
        'Die Formulardefinition selbst wird zum Werkzeugvertrag: ihre Validatoren, Optionen und Beschreibungen werden zu einem Schema, das Modell auf dem Gerät erzeugt dazu passende Argumente, und das ausgefüllte Formular läuft.',
    'One page tree, many channels':
        'Ein Seitenbaum, viele Kanäle',
    'A context is defined by domain, GET parameter, IP range, HTTP header, session value or a combination of those. Pages, menu entries and single content elements are switched on or off per context.':
        'Ein Kontext wird über Domain, GET-Parameter, IP-Bereich, HTTP-Header, Session-Wert oder eine Kombination davon definiert. Seiten, Menüeinträge und einzelne Inhaltselemente werden je Kontext ein- oder ausgeschaltet.',
    'A second sitemap type for images':
        'Ein zweiter Sitemap-Typ für Bilder',
    'Every image referenced from a page or a content element is listed with its title and caption in the Google image-sitemap schema, provided to EXT:seo as an additional XmlSitemapDataProvider.':
        'Jedes Bild, das von einer Seite oder einem Inhaltselement referenziert wird, erscheint mit Titel und Bildunterschrift im Google-Bilder-Sitemap-Schema — bereitgestellt für EXT:seo als zusätzlicher XmlSitemapDataProvider.',
    'What a task gains from the base classes':
        'Was eine Aufgabe durch die Basisklassen gewinnt',
    "A Scheduler task built on the toolkit's base classes is bound to application contexts and reports its failures by e-mail, so the same configuration can be deployed everywhere while executing only where it should.":
        'Eine Scheduler-Aufgabe auf Basis der Toolkit-Basisklassen ist an Anwendungskontexte gebunden und meldet ihre Fehlschläge per E-Mail. So lässt sich dieselbe Konfiguration überall ausrollen und läuft doch nur dort, wo sie soll.',
    'One page, many channels':
        'Eine Seite, viele Kanäle',
    'An existing page is the source: the extension derives social copy, summaries and alternative phrasings from it through NR LLM, without re-entering the content by hand.':
        'Eine vorhandene Seite ist die Quelle: die Erweiterung leitet daraus über NR LLM Social-Texte, Zusammenfassungen und alternative Formulierungen ab, ohne den Inhalt neu zu erfassen.',
    'Cache that follows starttime and endtime':
        'Cache, der starttime und endtime folgt',
    'Content with a visibility window stayed cached beyond it (TYPO3 Forge #14277). The cache is now invalidated exactly when content becomes visible and again when it expires.':
        'Inhalte mit Sichtbarkeitsfenster blieben darüber hinaus im Cache (TYPO3 Forge #14277). Der Cache wird jetzt genau dann verworfen, wenn Inhalt sichtbar wird — und erneut, wenn er abläuft.',
}


def t(s: str) -> str:
    if LANG == "en" or not s:
        return s
    table = TR.get(LANG, {})
    if s not in table:
        raise KeyError(f"no {LANG} translation for: {s!r}")
    return table[s]


def wrap(text: str, width: int) -> list[str]:
    words, lines, cur = text.split(), [], ""
    for w in words:
        trial = f"{cur} {w}".strip()
        if len(trial) <= width:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def box(x, y, w, h, title, body="", *, fill="#FFFFFF", stroke=BORDER,
        title_fill=TEXT, body_fill=TEXT, title_size=19, dashed=False):
    title, body = t(title), t(body)
    out = [
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="{fill}" '
        f'stroke="{stroke}" stroke-width="1.5"'
        + (' stroke-dasharray="6 5"' if dashed else "")
        + " />"
    ]
    lines = wrap(title, max(8, int((w - 24) / (title_size * 0.62))))
    ty = y + 34 if body else y + h / 2 + 7
    for i, line in enumerate(lines):
        out.append(
            f'<text x="{x + w / 2}" y="{ty + i * (title_size + 5)}" font-family="{FONT}" '
            f'font-size="{title_size}" font-weight="700" fill="{title_fill}" '
            f'text-anchor="middle">{esc(line)}</text>'
        )
    if body:
        by = ty + len(lines) * (title_size + 5) + 8
        for i, line in enumerate(wrap(body, max(12, int((w - 24) / 8.4)))):
            out.append(
                f'<text x="{x + w / 2}" y="{by + i * 21}" font-family="{FONT}" '
                f'font-size="15" fill="{body_fill}" text-anchor="middle">{esc(line)}</text>'
            )
    return "\n".join(out)


MARKER_COLOURS = (TEXT, PRIMARY, ACCENT)


def arrow(x1, y1, x2, y2, label="", *, colour=TEXT, dashed=False, above=True):
    # An arrow whose colour has no marker renders without a head -- silently in a
    # browser, and as a crash in cairosvg. Fail here instead.
    assert colour in MARKER_COLOURS, f"no arrow head defined for {colour}"
    label = t(label)
    out = [
        f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{colour}" '
        f'stroke-width="2" marker-end="url(#head-{colour.lstrip("#")})"'
        + (' stroke-dasharray="6 5"' if dashed else "")
        + " />"
    ]
    if label:
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        dy = -12 if above else 24
        out.append(
            f'<text x="{mx}" y="{my + dy}" font-family="{FONT}" font-size="14" '
            f'fill="{colour}" text-anchor="middle">{esc(label)}</text>'
        )
    return "\n".join(out)


def note(x, y, text, *, size=15, anchor="start", weight="400", colour=TEXT):
    text = t(text)
    return (
        f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" '
        f'font-weight="{weight}" fill="{colour}" text-anchor="{anchor}">{esc(text)}</text>'
    )


def frame(x, y, w, h, label):
    # No t() here: the label goes through note(), which translates it. Doing it
    # twice would look up an already-German string and raise.
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="none" '
        f'stroke="{PRIMARY}" stroke-width="2" stroke-dasharray="8 6" />\n'
        + note(x + 16, y + 26, label, size=15, weight="700", colour=DARK_TEAL)
    )


def svg(title: str, desc: str, body: str) -> str:
    title, desc = t(title), t(desc)
    heads = "\n".join(
        f'<marker id="head-{c.lstrip("#")}" viewBox="0 0 10 10" refX="9" refY="5" '
        f'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
        f'<path d="M0,0 L10,5 L0,10 z" fill="{c}" /></marker>'
        for c in MARKER_COLOURS
    )
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" role="img" aria-labelledby="t d">
<title id="t">{esc(title)}</title>
<desc id="d">{esc(desc)}</desc>
<defs>
{heads}
</defs>
<rect width="{W}" height="{H}" fill="#FFFFFF" />
{body}
</svg>
"""


def teal(x, y, w, h, title, body=""):
    return box(x, y, w, h, title, body, fill=PRIMARY, stroke=PRIMARY,
               title_fill="#FFFFFF", body_fill="#FFFFFF", title_size=20)


D: dict[str, tuple[str, str, "Callable[[], str]"]] = {}

# ---------------------------------------------------------------- ai-agent
D["ai-agent"] = (
    "How the AI Chat Agent answers",
    "A question typed in the TYPO3 backend goes to the chat agent, which calls MCP "
    "tools against pages, records, backend users, logs and site configuration, and "
    "answers from what those tools returned.",
    # A thunk, not a string: the body has to be rendered per language, and
    # rendering it at import time would freeze the English wording into D.
    lambda: "\n".join([
        note(60, 60, "Every answer is grounded in what the tools returned", size=17, weight="700"),
        box(60, 100, 250, 110, "Question in the backend", "„Which pages changed today?“"),
        arrow(320, 155, 400, 155),
        teal(410, 100, 220, 110, "AI Chat Agent", "built on NR LLM"),
        arrow(640, 155, 720, 155, "calls"),
        box(730, 100, 230, 110, "MCP tools", "read and act"),
        arrow(845, 220, 845, 290),
        box(620, 300, 460, 160, "TYPO3 install",
            "pages · content · records · backend users · logs · site configuration"),
        arrow(620, 380, 350, 380, "what the tools actually returned", colour=PRIMARY),
        box(60, 320, 270, 120, "Answer", "no invented facts", stroke=PRIMARY),
        note(60, 490, "A tool call can also change content — the agent reads and acts.",
             size=15, colour=ACCENT),
    ]),
)

# -------------------------------------------------------------- browser-ai
D["browser-ai"] = (
    "Where the answer is computed",
    "The page text and the question are handed to Chrome's built-in model on the "
    "visitor's own device. Nothing about the page or the dialogue is sent to a server.",
    # A thunk, not a string: the body has to be rendered per language, and
    # rendering it at import time would freeze the English wording into D.
    lambda: "\n".join([
        note(60, 58, "Nothing about the page or the question leaves the device", size=17, weight="700"),
        frame(40, 80, 720, 300, "the visitor’s device"),
        box(75, 130, 220, 110, "This page", "its rendered text"),
        arrow(305, 185, 385, 185),
        teal(395, 130, 230, 110, "Chrome built-in model", "Gemini Nano, on device"),
        arrow(510, 250, 510, 300),
        box(340, 310, 340, 55, "Answer in the page", ""),
        box(830, 130, 320, 110, "Any server", "TYPO3 · Netresearch · Google",
            stroke=BORDER, dashed=True, title_fill=TEXT),
        arrow(640, 185, 820, 185, colour=ACCENT, dashed=True),
        f'<line x1="762" y1="166" x2="790" y2="204" stroke="{ACCENT}" stroke-width="3" />',
        note(700, 172, "never", size=15, anchor="middle", weight="700", colour=ACCENT),
        note(60, 430, "No server endpoint, no telemetry, no cookie, no stored dialogue.", size=16, weight="700"),
        note(60, 460, "Needs Chrome 148 or newer and the downloaded model; without it the", size=15),
        note(60, 484, "plugin shows the fallback the editor configured.", size=15),
    ]),
)

# ------------------------------------------- browser-ai-form-assistant
D["browser-ai-form-assistant"] = (
    "One sentence fills a seventy-control form",
    "The form definition itself becomes the tool contract: its validators, options "
    "and descriptions are turned into a schema, the on-device model produces "
    "arguments against it, and the filled form runs.",
    # A thunk, not a string: the body has to be rendered per language, and
    # rendering it at import time would freeze the English wording into D.
    lambda: "\n".join([
        note(60, 58, "The form definition is the tool contract", size=17, weight="700"),
        box(50, 100, 240, 120, "One sentence",
            "„Wind gusts in Innsbruck for ten days“"),
        arrow(300, 160, 360, 160),
        box(370, 100, 250, 120, "Schema from the form",
            "validators · options · labels"),
        arrow(630, 160, 690, 160),
        teal(700, 100, 230, 120, "On-device model", "produces arguments"),
        arrow(940, 160, 1000, 160),
        box(1010, 100, 140, 120, "Validated", "enum members checked"),
        arrow(1080, 230, 1080, 290),
        box(700, 300, 450, 110, "The form fills itself in, and runs",
            "seventy controls · one MultiCheckbox is one array property"),
        arrow(690, 355, 500, 355, "result", colour=PRIMARY),
        box(150, 300, 330, 110, "Answer with the data", "rendered as text nodes"),
        note(50, 470, "No server endpoint: the query runs from the page itself.", size=15, colour=ACCENT),
    ]),
)

# ---------------------------------------------------------------- contexts
D["contexts"] = (
    "One page tree, many channels",
    "A context is defined by domain, GET parameter, IP range, HTTP header, session "
    "value or a combination of those. Pages, menu entries and single content "
    "elements are switched on or off per context.",
    # A thunk, not a string: the body has to be rendered per language, and
    # rendering it at import time would freeze the English wording into D.
    lambda: "\n".join([
        note(60, 58, "One page tree instead of one tree per channel", size=17, weight="700"),
        box(50, 100, 300, 330, "One page tree",
            "pages · menu entries · single content elements"),
        arrow(360, 265, 430, 265),
        teal(440, 150, 300, 230, "Context matches?",
             "domain · GET parameter · IP range · HTTP header · session value, "
             "or an AND / OR / XOR combination of them"),
        arrow(750, 205, 830, 175, "yes", colour=PRIMARY),
        arrow(750, 325, 830, 355, "no", above=False),
        box(840, 120, 310, 110, "Shown in this channel", "", stroke=PRIMARY),
        box(840, 300, 310, 110, "Hidden in this channel", ""),
        note(50, 470, "Editors mark where something appears — no parallel tree to keep in sync.",
             size=15, colour=ACCENT),
    ]),
)

# ----------------------------------------------------------- image-sitemap
D["image-sitemap"] = (
    "A second sitemap type for images",
    "Every image referenced from a page or a content element is listed with its "
    "title and caption in the Google image-sitemap schema, provided to EXT:seo as "
    "an additional XmlSitemapDataProvider.",
    # A thunk, not a string: the body has to be rendered per language, and
    # rendering it at import time would freeze the English wording into D.
    lambda: "\n".join([
        note(60, 58, "No backend module, no extra table — the output is the sitemap",
             size=17, weight="700"),
        box(50, 110, 270, 130, "Pages and content elements",
            "the images already referenced"),
        arrow(330, 175, 390, 175),
        box(400, 110, 250, 130, "Title and caption",
            "what editors entered on the image"),
        arrow(660, 175, 720, 175),
        teal(730, 110, 300, 130, "XmlSitemapDataProvider", "registered with EXT:seo"),
        arrow(880, 250, 880, 310),
        box(620, 320, 520, 120, "image sitemap XML",
            "the Google image-sitemap schema, beside the core sitemap"),
        box(50, 320, 500, 120, "Nothing else to maintain",
            "no scheduler run, no separate database table, no editor step"),
        note(50, 480, "Its demo is the XML itself.", size=15, colour=ACCENT),
    ]),
)

# ------------------------------------------------------------ nr-scheduler
D["nr-scheduler"] = (
    "What a task gains from the base classes",
    "A Scheduler task built on the toolkit's base classes is bound to application "
    "contexts and reports its failures by e-mail, so the same configuration can be "
    "deployed everywhere while executing only where it should.",
    # A thunk, not a string: the body has to be rendered per language, and
    # rendering it at import time would freeze the English wording into D.
    lambda: "\n".join([
        note(60, 58, "Same configuration everywhere, execution only where it belongs",
             size=17, weight="700"),
        box(50, 130, 250, 120, "Scheduler task", "built on the base classes"),
        arrow(310, 190, 370, 190),
        teal(380, 130, 260, 120, "In this context?", "Production / Staging / …"),
        arrow(650, 165, 720, 135, "yes", colour=PRIMARY),
        arrow(650, 220, 720, 385, "no", above=False),
        box(730, 90, 420, 85, "Runs", "", stroke=PRIMARY),
        arrow(940, 185, 940, 235, "on failure", colour=ACCENT),
        box(730, 245, 420, 110, "E-mail to the configured recipients",
            "own subject and message — not just a red row in the module"),
        box(730, 370, 420, 85, "Skipped, and says so", ""),
        box(50, 300, 620, 155, "Deployed unchanged",
            "one configuration in the repository, gated per application context "
            "instead of edited per environment"),
    ]),
)

# --------------------------------------------------------------- repurpose
D["repurpose"] = (
    "One page, many channels",
    "An existing page is the source: the extension derives social copy, summaries "
    "and alternative phrasings from it through NR LLM, without re-entering the "
    "content by hand.",
    # A thunk, not a string: the body has to be rendered per language, and
    # rendering it at import time would freeze the English wording into D.
    lambda: "\n".join([
        note(60, 58, "Start from a page that already exists", size=17, weight="700"),
        box(50, 170, 260, 150, "An existing page",
            "the content you already published"),
        arrow(320, 245, 400, 245),
        teal(410, 170, 250, 150, "Repurpose", "built on NR LLM"),
        arrow(670, 200, 750, 145, colour=PRIMARY),
        arrow(670, 245, 750, 245, colour=PRIMARY),
        arrow(670, 290, 750, 345, colour=PRIMARY),
        box(760, 100, 390, 90, "Social posts", "short copy per channel"),
        box(760, 200, 390, 90, "Summaries", "the gist, at length"),
        box(760, 300, 390, 90, "Alternative phrasings", "tuned per audience"),
        note(50, 430, "Nothing is re-typed: the source is the page, not a fresh brief.",
             size=15, colour=ACCENT),
    ]),
)

# ---------------------------------------------------------- temporal-cache
D["temporal-cache"] = (
    "Cache that follows starttime and endtime",
    "Content with a visibility window stayed cached beyond it (TYPO3 Forge #14277). "
    "The cache is now invalidated exactly when content becomes visible and again "
    "when it expires.",
    # A thunk, not a string: the body has to be rendered per language, and
    # rendering it at import time would freeze the English wording into D.
    lambda: "\n".join([
        note(60, 58, "TYPO3 Forge #14277: timed content stayed cached past its window",
             size=17, weight="700"),
        f'<line x1="80" y1="250" x2="1120" y2="250" stroke="{BORDER}" stroke-width="3" />',
        f'<rect x="380" y="215" width="420" height="70" rx="8" fill="{PRIMARY}" opacity="0.16" />',
        note(590, 205, "content is visible", size=16, anchor="middle", weight="700", colour=DARK_TEAL),
        f'<line x1="380" y1="180" x2="380" y2="320" stroke="{ACCENT}" stroke-width="3" />',
        f'<line x1="800" y1="180" x2="800" y2="320" stroke="{ACCENT}" stroke-width="3" />',
        note(380, 170, "starttime", size=15, anchor="middle", weight="700", colour=ACCENT),
        note(800, 170, "endtime", size=15, anchor="middle", weight="700", colour=ACCENT),
        note(380, 345, "cache cleared", size=14, anchor="middle", colour=ACCENT),
        note(800, 345, "cache cleared", size=14, anchor="middle", colour=ACCENT),
        note(215, 300, "not yet shown", size=15, anchor="middle"),
        note(960, 300, "no longer shown", size=15, anchor="middle"),
        box(80, 380, 480, 110, "Scoping",
            "a single page, a page tree, or every page"),
        box(620, 380, 500, 110, "When",
            "on demand, or on a Scheduler run"),
        note(80, 130, "Works with any content type that uses starttime and endtime.", size=15),
    ]),
)


def main() -> None:
    global LANG
    root = Path(__file__).resolve().parent.parent / "data/fileadmin/user_upload/images/extension-diagrams"
    # English keeps the flat path the seed already references; each further
    # language gets a subdirectory, so adding one never moves an existing file.
    for lang in ("en", *sorted(TR)):
        LANG = lang
        out = root if lang == "en" else root / lang
        out.mkdir(parents=True, exist_ok=True)
        for name, (title, desc, body) in D.items():
            path = out / f"{name}.svg"
            path.write_text(svg(title, desc, body()), encoding="utf-8")
            print(f"{lang}  {path.name:34} {path.stat().st_size:6} bytes")
    LANG = "en"


if __name__ == "__main__":
    main()
