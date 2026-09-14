# Exhaustive Italian terminology audit

This audit cross-references UI terms across all seven end-user chapters
(`admin_guide.xml`, `user_guide.xml`, `moderator_guide.xml`,
`quick_start_guide.xml`, `upgrade_guide.xml`, `server_guide.xml`,
`glossary.xml`) and `dev-docs-docbook/it/` against phpBB's real Italian
language pack. Claude did the cross-checking, translating, and
investigating described below.

## The reference pack

The obvious first candidate — `phpbbitalia/phpbb-it` on GitHub — turned
out to be **stale**: its last commit is from 2014 and its newest tag is
`3.0.12`, an entire major generation behind this project's phpBB 3.3.x
target. Using it produced several false "fixes" early in this audit
(caught and reverted before they were committed) because keys the old
pack was simply missing looked like gaps in the real pack rather than
gaps in a decade-old snapshot.

The correct, current reference is the **Italian** contribution on
phpBB's own Customisation Database
([phpbb.com/customise/db/translation/italian/](https://www.phpbb.com/customise/db/translation/italian/)),
maintained by **alex75**, validated for phpBB 3.3.16 (the current
stable release) — 5,263 of the English pack's 5,274 language keys
present, versus only 4,800 in the stale GitHub mirror. Every fix in
this audit is checked against that pack, downloaded directly from
phpBB.com's download link for the `Italian_3_3_16` revision.

## Method

Every `<guilabel>`/`<guimenuitem>`/`<title>` string in every chapter
was extracted and paired with its English source line (positional
pairing after confirming EN/IT tag counts matched exactly per chapter
— `admin_guide.xml` needed one adjustment first, see below), then
looked up against a key→value map built from every `.php` language
file in both the real pack and phpBB core's own `language/en/` tree
(not sampled). A string only counts as a confirmed mismatch when the
**English documentation text itself is a literal, exact quote of a
real phpBB string** (verified against the matched key's own English
value) — this distinction matters: many `<guilabel>`/`<title>` strings
in the English source are deliberate paraphrases of the real UI text,
and forcing the Italian to literally match a key the English itself
isn't literally quoting would fork the translation from its own
source for no reason. Several apparent mismatches turned out to be
exactly this — most notably a chapter heading for the UCP's "Global"
preferences tab, which a naive key search matched to the topic-type
radio button `POST_GLOBAL` purely by string coincidence; the Italian
"Generali" is correct there and was left alone.

`admin_guide.xml`'s English source contains one broken pre-existing
duplicated phrase — `<guilabel>Look Up User</guilabel>. In the
<guilabel>Find a user</guilabel> field...` — where the Italian
translation had already (correctly) merged this into a single coherent
field label ("Cerca utente"), dropping the redundant tag. This is a
pre-existing English-source issue, not an Italian translation defect;
it was compensated for in the audit tooling (not the file) so the
rest of the chapter's positional pairing stays aligned.

## Results

| Chapter | Real fixes applied | Status |
|---|---|---|
| `admin_guide.xml` | 196 strings (230 occurrences) | Exhaustively resolved |
| `user_guide.xml` | 48 strings | Exhaustively resolved |
| `quick_start_guide.xml` | 22 strings | Exhaustively resolved |
| `moderator_guide.xml` | 0 (none needed) | Exhaustively resolved |
| `upgrade_guide.xml` | 0 (none needed) | Exhaustively resolved |
| `server_guide.xml` | 0 (none needed — titles only, no literal UI quotes) | Exhaustively resolved |
| `glossary.xml` | 0 (none needed) | Exhaustively resolved |
| `dev-docs-docbook/it/` | — | Doesn't use `<guilabel>`/`<guimenuitem>` tags at all, confirmed via `grep -rl` — nothing for this audit to check |

Every chapter's confirmed literal mismatches were fixed and verified;
no chapter was left with a real fix outstanding by the time this audit
finished — unlike the French and German audits, `admin_guide.xml` and
`user_guide.xml` did **not** need to be left partially triaged, since
their much larger volume of drift (298 and 78 initial mismatches,
respectively) was still small enough to resolve item-by-item within
this pass. Match rates after fixing:
`admin_guide.xml` 478→704/981, `user_guide.xml` 121→168/309,
`quick_start_guide.xml` 52→78/117 tags now confirmed matching the real
pack.

Representative fixes, from small wording differences to some outright
different terms:

- **"ACP" stays "ACP", not translated** — confirmed against the
  German and French translations (both keep the literal acronym
  untranslated even inside `<guilabel>` tags) before touching it;
  the real pack's own short form is "PCA" but this project's
  established convention across every other language is to leave the
  acronym as-is, so Italian was left consistent with that rather than
  "fixed" to differ from its sibling translations.
- **"Ruoli permesso"/"Ruolo permesso" should be "Ruolo permessi"** —
  the real ACP permission-roles page name, used inconsistently (three
  different near-miss spellings) across `quick_start_guide.xml`
  before this pass; now uniform.
- **Present tense should be passato prossimo in notification-type
  descriptions** — "Qualcuno risponde a..." should be "Qualcuno ha
  risposto a...", the same drift pattern the German audit found in
  its own notification-description cluster. Fixed across seven
  notification-type rows in `user_guide.xml`.
- **"Impostazioni del forum"/"Funzionalità del forum" should be the
  real page names "Impostazioni"/"Caratteristiche"** — the doc
  consistently over-translated these two ACP page titles into fuller
  descriptive phrases instead of the terser real labels, across both
  `<title>` tags and quoted prose references to the same page names.
- **Database/installer field labels** — "Nome utente del database"
  should be "Nome utente database" (and five sibling DB-connection
  field labels), matching the real installer's terser phrasing
  throughout `quick_start_guide.xml`.
- **A cluster of ACP settings-page names** across `admin_guide.xml`
  that had been translated more literally/verbosely than the terser
  real page names — "Impostazioni di sicurezza" → "Sicurezza",
  "Impostazioni sul carico" → "Processi", "Impostazioni di ricerca" →
  "Motore di ricerca", and similarly for cookie, server, email,
  Jabber, ban, prune-users, and mass-email admin pages.
- **`BOT_AGENT` ("Agent match")** is one of the few keys the real pack
  leaves untranslated (English fallback) — the Italian doc had
  translated it as "Corrispondenza agente" anyway; changed to match
  what an administrator will actually see on their board. Worth a
  note to the pack maintainer (alex75) as a small completeness gap,
  not a documentation bug.

## Genuinely unconfirmed terms

A residual set of strings — mostly in `admin_guide.xml` and
`user_guide.xml`, where the sheer number of settings pages means many
labels are compound/multi-field constructs the crude key-matching
can't resolve — had no matching real-pack key found at all. Most of
these fall into established non-issue categories (untranslated
technical terms like `PHP`, `URL`, `BBCode`, `MySQL Fulltext`; curly
vs. straight apostrophe/quote artifacts; colon-suffixed field labels
that don't match the pack's own colon-free key values; plural/singular
grammatical variants of an already-correct term). A curated set of the
more substantive open questions is listed in the supplementary
glossary rather than repeated here — this audit did not attempt to
individually re-verify literally every one of the roughly 360 residual
`NO_KEY` strings against every candidate file, matching the same
practical limit the French and German audits documented for their own
largest chapters.

## How to do this

For each `<guilabel>`/`<guimenuitem>`/`<title>` string, identify the
real phpBB language key it corresponds to (grep the relevant
`language/it/` or `language/it/acp/` file from the current
[Italian pack on phpBB.com](https://www.phpbb.com/customise/db/translation/italian/)
— **not** the stale `phpbbitalia/phpbb-it` GitHub mirror — by its
English string first, via phpBB core's own `language/en/` tree at the
matching `3.3.x` branch, to find the key, then check the Italian
value) and fix the document if it differs. Before trusting a key
match, confirm the **English documentation text is itself a literal
quote** of that key's real English value — if the English is already
a paraphrase, the Italian mirroring that same paraphrase is not a bug,
and if two different English words could plausibly map to the same
short common term (this bit hard on "Global", "Normal", "Allow",
generic one-word titles), check the surrounding context/section id
against the matched key's file before changing anything. Watch for
false positives from crude string matching: case differences, curly
vs straight quotes/apostrophes, and inline markup in the real PHP
source all cause a real match to look unmatched at first pass.
Verify with a real `./phpbbdocs_hugo.sh it` build afterward.

**Where this applies to future edits:** any `.xml` file under
`content/it/chapters/`. **How:** if new or edited text references a
literal phpBB UI string (a button, field, menu item, or page name the
reader would actually click), wrap it in `<guilabel>` or
`<guimenuitem>` and run it through the same check as above before
merging — if there's no matching key, add a row to
[`italian-it-supplementary-glossary.md`](italian-it-supplementary-glossary.md)
instead of leaving it unverified.
