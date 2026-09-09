# Next translation priority

Ranks the phpBB language packs not yet done in this project (English,
Danish, French, and German — formal register only — are already complete;
see [phpbb-hugo-languages.md](../phpbb-hugo-languages.md)) from highest to
lowest priority for the next translation. Grouped by language rather than
by raw phpBB code, so an honorific-split pack (e.g. German casual/formal)
counts as one entry, not two.

**Ranking criteria**, in order of weight:

1. **Global reach** — native + second-language speaker count. General
   knowledge, not phpBB-specific data.
2. **phpBB's own historical community strength** in that language/region —
   general knowledge (e.g. phpBB has deep, long-standing roots in the German-
   and other European-language hosting/forum communities), not a verified
   current statistic. Treat as a soft signal, not a hard number.
3. **Added technical complexity**, which pushes a language down a tier even
   with strong reach:
   - An **honorific split** (German, Spanish, Dutch, Croatian) means the
     phpBB pack itself ships as two variants — same double-effort tradeoff
     discussed for French, where we picked one register rather than
     translating twice. Still worth doing, just costs more per language.
   - An **RTL script** (Arabic, Hebrew, Persian, Urdu) is a real unknown:
     this project's CSS/templates have never been exercised in RTL, so the
     first RTL language is partly a layout-verification project, not just a
     translation one.
   - A **non-Latin, non-RTL script** (Russian, Greek, CJK, Thai, etc.) is
     generally low-risk — Hugo/CSS are Unicode-safe — but still noted since
     it's untested in this project specifically.

This is a starting point, not a fixed queue — easy to reorder if a specific
community asks for a language, or if effort/complexity assumptions turn out
wrong once actually attempted.

## Tier 1 — highest priority

Large global reach, established phpBB community, no more than one added
complexity factor.

| Language | Complexity | Notes |
|---|---|---|
| Spanish (Formal) | Honorific split (Tú/Usted) | Pick one register |
| Italian | None | Lowest-friction large-community option |
| Russian | Cyrillic script | Not RTL, no layout risk expected |
| Portuguese (Formal) | Minor: preAO spelling variant | Distinct from Brazilian Portuguese below |
| Brazilian Portuguese | None | Large, distinct market from European Portuguese |
| Polish | None | |
| Dutch | Honorific split (informal/formal) | Pick one register |

## Tier 2 — solid reach, low complexity

Established communities, Latin or simple non-Latin script, no split.

Turkish, Ukrainian, Czech, Hungarian, Romanian, Greek, Swedish, Vietnamese,
Indonesian, Finnish, Norwegian (bokmål)

## Tier 3 — RTL scripts

Real communities, but the first one doubles as this project's RTL
layout-verification effort (unverified: sidebar, nav, breadcrumbs, language
switcher, admonition/table styling all assume LTR today).

Arabic, Hebrew, Persian, Urdu

## Tier 4 — CJK / other non-Latin scripts

Lower risk than RTL (Unicode-safe, no layout direction change), but still
untested in this project and smaller reach than Tier 1/2 for phpBB
specifically.

Japanese, Mandarin Chinese (Simplified), Mandarin Chinese (Traditional), Thai

## Tier 5 — lowest priority

Smaller/regional communities, compounding complexity (dual-script, split
plus small reach), or a regional variant that only makes sense once its
parent language exists.

- **Regional variants of a not-yet-added language** (add the parent first):
  Argentinian Spanish, Mexican Spanish — after Spanish (Formal)
  American English — after nothing else is blocking, but English (British)
  already covers the language; lowest-value duplicate
- **Second (informal) register of an already-done honorific-split
  language**: German (Du) — deferred; the formal register (Sie) already
  covers the core need, so the informal variant is a nice-to-have refinement
  rather than new coverage. The same deferral pattern will apply to Spanish
  (Tú) and Dutch (informal) once their own formal/casual variant is done.
- **Compounding complexity**: Croatian (honorific split), Serbian (dual
  script, Cyrillic/Latin, same phpBB code — needs the `sr-Latn-RS` handling
  noted in the language reference doc)
- **Smaller reach, no major complexity**: Bulgarian, Slovak, Slovenian,
  Lithuanian, Estonian, Belarusian, Macedonian, Catalan, Basque, Galician,
  Gaelic
- **Low-confidence locale mapping already flagged in the reference doc**:
  Azerbaijani, Kurdish, Tatar
