# Exhaustive German terminology audit

This audit cross-references UI terms across all seven end-user
chapters (`admin_guide.xml`, `user_guide.xml`, `moderator_guide.xml`,
`quick_start_guide.xml`, `upgrade_guide.xml`, `server_guide.xml`,
`glossary.xml`) and all 50 developer-doc files under
`dev-docs-docbook/de_x_sie/` against phpBB's real German (Formal
Honorifics) language pack (`phpbb-de/phpbb-translation`,
`language/de_x_sie/`).

All seven chapters — `admin_guide.xml`, `user_guide.xml`,
`moderator_guide.xml`, `quick_start_guide.xml`, `upgrade_guide.xml`,
`server_guide.xml`, `glossary.xml` — have had the exact same
exhaustive treatment: every `<guilabel>`/`<guimenuitem>`/`<title>`
string in every chapter has been individually traced to its English
source line and resolved, not sampled. Real mismatches were found and
fixed in `admin_guide.xml` and `user_guide.xml`, not just close
paraphrases but different literal button and field labels, and in
several cases an entire feature described with the wrong term: the
"Manage extensions" pages being confused with phpBB's unrelated
Extensions/mods feature, predefined permission-role names like
"Vollmoderator" not matching the real "Umfassender Moderator",
"Moderatorkontrollzentrum"/"Administrationskontrollzentrum" not
matching the real "Moderations-Bereich"/"Administrations-Bereich", and
several search/sort dropdown labels and a private-message button whose
wording didn't match the real strings (see the commit log for the full
list). `moderator_guide.xml`, `quick_start_guide.xml`,
`upgrade_guide.xml`, `server_guide.xml`, and `glossary.xml` came back
clean under the same exhaustive check — no fixes needed, though each
turned up a small number of strings genuinely unconfirmable against
the fetched language pack (see the supplementary glossary below).

All 50 dev-docs files have had a full read-through against their
English originals. Dev-docs reference far fewer phpBB UI strings than
the end-user chapters, so this review was mostly about translation
fidelity and technical accuracy rather than `<guilabel>` matching. It
found and fixed two real translation bugs: a mistranslated "or" that
read as a contradiction, in `language/guidelines.dbk` and
`language/validation.dbk`. It also turned up a handful of
factual/numeric errors — an off-by-one in `database_types_list.dbk`'s
int ranges, broken smart-quotes in a code sample in
`tutorial_key_concepts.dbk`, an inconsistent version number in
`tutorial_basics.dbk` — but these are present identically in the
English source, so they're upstream content bugs rather than
translation errors; they're left as-is and out of this audit's scope.

`admin_guide.xml` started this audit with 219 unmatched
`<guilabel>`/`<guimenuitem>`/`<title>` strings. Every single one of
them has since been individually traced to its English source line,
matched against a real phpBB language key where one exists, and
resolved — around 75 turned out to be genuine mismatches and were
fixed (wrong ACP page titles, dropdown labels, table column headers,
password-complexity and settings descriptions that didn't match the
real board's wording). The remaining 144 are not open questions; each
has a specific, checked reason it isn't a translation bug:

- **Confirmed correct, flagged only by a crude string comparison** —
  the real value matches exactly once you account for inline
  `<code>`/`<em>` markup in the source PHP file, curly quotes, or two
  separate real strings concatenated with a slash (e.g.
  "Aktivieren/Deaktivieren" = the real `ACTIVATE` + `DEACTIVATE`
  values joined).
- **Grammatical case forms** of an already-correct term (dative/
  genitive), which will never literally match the pack's dictionary
  form — e.g. "Namens des Boards" is the correct genitive of "Name des
  Boards".
- **Colon or hyphenation differences only** — the real language pack
  never stores the trailing colon a form label gets in the template,
  and a few compound nouns are hyphenated differently without changing
  meaning.
- **Untranslated technical strings by design** — product names (AOL/
  MSN Messenger, the Fulltext search engine names), file paths
  (`images/avatars/upload`), template placeholder tokens (`NUMBER`,
  `TEXT`, `INCLUDEPHP`), and bare acronyms (`PHP`, `URL`).
- **Descriptive section/chapter titles**, mirroring the English
  source's own non-literal heading style (e.g. "Adding a bot",
  "Database backup and restore") rather than quoting a real UI string
  — this covers the great majority of `<title>`-tagged entries.
- **Pre-existing content issues shared identically by the English
  source** — e.g. the "Maximum thumbnail filesize" setting's
  description matches a `MIN_THUMB_FILESIZE`-shaped behavior in both
  languages, and "Recompile stale templates" may describe an
  older/renamed feature; these are flagged for awareness, not silently
  patched in German only, since fixing only the translation would fork
  it from the (equally wrong) English original.
- **Genuinely unconfirmed** — a small residual set, across every
  chapter (not just `admin_guide.xml`), where no matching key could be
  found in the fetched reference files at all. These are listed, with
  the reasoning behind each one, in the fillable
  [`german-de-x-sie-supplementary-glossary.md`](german-de-x-sie-supplementary-glossary.md)
  rather than repeated here.

## How to do this

For each `<guilabel>`/`<guimenuitem>`/`<title>` string, identify the
real phpBB language key it corresponds to (grep the relevant
`language/de_x_sie/` or `language/de_x_sie/acp/` file from
[phpbb-de/phpbb-translation](https://github.com/phpbb-de/phpbb-translation)
by its English string first, via `language/en/`, to find the key, then
check the German value) and fix the document if it differs. Watch for
false positives from crude string matching: inline `<code>`/`<em>`
markup inside the PHP source, curly vs straight quotes, and labels
built by concatenating two separate keys all cause a real match to
look unmatched. When the English source itself is a non-literal
paraphrase of a heading or description (not a literal UI quote), the
German mirroring that same paraphrase is not a bug. Verify with a real
`./phpbbdocs_hugo.sh de_x_sie` build afterward.

**Where this applies to future dev-docs edits:** any `.dbk` file under
`dev-docs-docbook/de_x_sie/`. **How:** if the new or edited text
references a literal phpBB UI string (a button, field, menu item, or
page name the reader would actually click), wrap it in `<guilabel>` or
`<guimenuitem>` and run it through the same check as above before
merging — if there's no matching key, add a row to
[`german-de-x-sie-supplementary-glossary.md`](german-de-x-sie-supplementary-glossary.md)
instead of leaving it unverified.
