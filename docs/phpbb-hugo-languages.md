# phpBB → Hugo language reference

Every phpBB language pack (from https://www.phpbb.com/languages/), its real
phpBB "ISO Code" (read from each language's own detail page at
`https://www.phpbb.com/customise/db/translation/<slug>/`), and a suggested
Hugo `locale` value for this project's `config.toml` `[languages.<code>]`
blocks. Compiled 08/30/2026.

phpBB currently lists 55 language packs; all 55 are captured below.

**How "Suggested Hugo locale" was derived:** if phpBB's own ISO Code already
includes a region subtag (e.g. `pt-br`, `es-mx`), it is simply re-cased to
the Hugo convention (lowercase language, uppercase region). If phpBB's code
is a bare language tag with no region (e.g. `da`), a standard/default region
was inferred by best judgment and is flagged in the Notes column. A few
phpBB codes use non-standard forms (private-use honorific tags like
`hr-x-vi`, or script/extlang forms like `zh-cmn-hans`) — those are flagged
individually, since a region can't be mechanically re-cased out of them.

| Display name | Local name | phpBB ISO Code | Suggested Hugo locale | Notes |
|---|---|---|---|---|
| American English | American English | en_us | en-US | ISO Code uses an underscore; recased/hyphenated per Hugo convention |
| Arabic | العربية | ar | ar-SA | region inferred, not in phpBB's code; no single "standard" country for Arabic, SA used as a common default |
| Argentinian Spanish | Español Argentino | es-ar | es-AR | |
| Azerbaijani | Azərbaycanca | az | az-AZ | region inferred, not in phpBB's code |
| Basque | Euskara | eu | eu-ES | region inferred, not in phpBB's code (Basque Country, Spain) |
| Belarusian | Беларуская | be | be-BY | region inferred, not in phpBB's code |
| Brazilian Portuguese | Português Brasileiro | pt-br | pt-BR | |
| British English | British English | en | en-GB | region inferred, not in phpBB's code; already in use in this project |
| Bulgarian | Български | bg | bg-BG | region inferred, not in phpBB's code |
| Catalan | Català | ca | ca-ES | region inferred, not in phpBB's code (Catalonia, Spain) |
| Croatian (Casual Honorifics) | Hrvatski ("Ti") | hr | hr-HR | region inferred, not in phpBB's code |
| Croatian (Formal Honorifics) | Hrvatski ("Vi") | hr-x-vi | hr-HR | phpBB code uses a private-use tag (`x-vi`) for honorifics, not a real region; region inferred as HR. Same base locale as Croatian (Casual) — a custom key is needed to distinguish the two honorific variants in Hugo |
| Czech | Čeština | cs | cs-CZ | region inferred, not in phpBB's code |
| Danish | Dansk | da | da-DK | region inferred, not in phpBB's code; already in use in this project |
| Dutch (Casual Honorifics) | Nederlands (Informeel) | nl | nl-NL | region inferred, not in phpBB's code |
| Dutch (Formal Honorifics) | Nederlands (Formeel) | nl-x-formal | nl-NL | phpBB code uses a private-use tag (`x-formal`), not a real region; region inferred as NL. Same base locale as Dutch (Casual) — a custom key is needed to distinguish the two honorific variants in Hugo |
| Estonian | Eesti keel | et | et-EE | region inferred, not in phpBB's code |
| Finnish | Suomi | fi | fi-FI | region inferred, not in phpBB's code |
| French | Français | fr | fr-FR | region inferred, not in phpBB's code |
| Gaelic | Gàidhlig | gd | gd-GB | region inferred, not in phpBB's code (Scottish Gaelic, UK) |
| Galician | Galego | gl | gl-ES | region inferred, not in phpBB's code (Galicia, Spain) |
| German (Casual Honorifics) | Deutsch (Du) | de | de-DE | region inferred, not in phpBB's code |
| German (Formal Honorifics) | Deutsch (Sie) | de-x-sie | de-DE | phpBB code uses a private-use tag (`x-sie`), not a real region; region inferred as DE. Same base locale as German (Casual) — a custom key is needed to distinguish the two honorific variants in Hugo |
| Greek | Ελληνικά | el | el-GR | region inferred, not in phpBB's code |
| Hebrew | עברית | he | he-IL | region inferred, not in phpBB's code |
| Hungarian | Magyar | hu | hu-HU | region inferred, not in phpBB's code |
| Indonesian | Bahasa Indonesia | id | id-ID | region inferred, not in phpBB's code |
| Italian | Italiano | it | it-IT | region inferred, not in phpBB's code |
| Japanese | 日本語 | ja | ja-JP | region inferred, not in phpBB's code |
| Kurdish | کوردی | ku | ku-TR | region inferred, low confidence — Kurdish has no single associated country (spoken across Turkey, Iraq, Iran, Syria); TR chosen as a common default |
| Lithuanian | Lietuvių | lt | lt-LT | region inferred, not in phpBB's code |
| Macedonian | македонски јазик | mk | mk-MK | region inferred, not in phpBB's code |
| Mandarin Chinese (Simplified Script) | 简体中文 | zh-cmn-hans | zh-CN | phpBB code is a language-extlang-script tag (`zh-cmn-Hans`), not language-region; `zh-CN` used as the conventional Hugo-style equivalent for Simplified Chinese |
| Mandarin Chinese (Traditional Script) | 正體中文 | zh-cmn-hant | zh-TW | phpBB code is a language-extlang-script tag (`zh-cmn-Hant`), not language-region; `zh-TW` used as the conventional Hugo-style equivalent for Traditional Chinese |
| Mexican Spanish | Español Mexicano | es-mx | es-MX | |
| Norwegian (bokmål) | Norsk (bokmål) | nb | nb-NO | region inferred, not in phpBB's code |
| Persian | فارسی | fa | fa-IR | region inferred, not in phpBB's code |
| Polish | Polski | pl | pl-PL | region inferred, not in phpBB's code |
| Portuguese (Formal) | Português | pt | pt-PT | region inferred, not in phpBB's code (European Portuguese, distinct from Brazilian) |
| Portuguese preAO (Formal) | Português Pré-Acordo Ortográfico (Formal) | pt-preao | pt-PT | phpBB's `preao` suffix denotes pre-orthographic-agreement spelling, not a real region; region inferred as PT. Same base locale as Portuguese (Formal) — a custom key is needed to distinguish the two spelling variants in Hugo |
| Romanian | Română | ro | ro-RO | region inferred, not in phpBB's code |
| Russian | Русский | ru | ru-RU | region inferred, not in phpBB's code |
| Serbian (Cyrillic Script) | Српски | sr | sr-RS | region inferred, not in phpBB's code; phpBB uses the same ISO Code (`sr`) for both script variants |
| Serbian (Latin Script) | Srpski (Latinica) | sr | sr-RS | region inferred, not in phpBB's code; phpBB uses the same ISO Code (`sr`) as the Cyrillic variant — consider `sr-Latn-RS` as a distinguishing Hugo locale if both script variants are needed side by side |
| Slovak | Slovenčina | sk | sk-SK | region inferred, not in phpBB's code |
| Slovenian | Slovenščina | sl | sl-SI | region inferred, not in phpBB's code |
| Spanish (Casual Honorifics) | Español (Tú) | es-x-tu | es-ES | phpBB code uses a private-use tag (`x-tu`), not a real region; region inferred as ES. Same base locale as Spanish (Formal) — a custom key is needed to distinguish the two honorific variants in Hugo |
| Spanish (Formal Honorifics) | Español (Usted) | es | es-ES | region inferred, not in phpBB's code |
| Swedish | Svenska | sv | sv-SE | region inferred, not in phpBB's code |
| Tatar | Татар | tt | tt-RU | region inferred, low confidence — Tatar is primarily spoken in Tatarstan, Russia |
| Thai | ภาษาไทย | th | th-TH | region inferred, not in phpBB's code |
| Turkish | Türkçe | tr | tr-TR | region inferred, not in phpBB's code |
| Ukrainian | Українська | uk | uk-UA | region inferred, not in phpBB's code |
| Urdu | اردو | ur | ur-PK | region inferred, not in phpBB's code |
| Vietnamese | Tiếng Việt | vi | vi-VN | region inferred, not in phpBB's code |

## Currently supported in this project

- **English** — `en` in this project, phpBB's **British English** pack, Hugo locale `en-GB` (see row above)
- **Danish** — `da` in this project, phpBB's **Danish** pack, Hugo locale `da-DK` (see row above)
- **French** — `fr` in this project, phpBB's **French** pack, Hugo locale `fr-FR` (see row above). Screenshots reuse the English set (`content/en/images`, copied verbatim) since this project has no live French-language phpBB install to source real localized captures from, unlike the Danish set.
- **German** — `de_x_sie` in this project (matching phpBB's own code exactly, not the plain `de` casual base pack), phpBB's **German (Formal Honorifics)** pack, Hugo locale `de-DE` (see row above). Formal register ("Sie") chosen, matching French's formal-register choice — this project doesn't offer the casual ("Du") variant separately. Screenshots reuse the English set, same reasoning as French.
