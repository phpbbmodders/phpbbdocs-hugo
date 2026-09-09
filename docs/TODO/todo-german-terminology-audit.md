# Exhaustive German terminology audit

This audit cross-references UI terms across all seven end-user
chapters (`admin_guide.xml`, `user_guide.xml`, `moderator_guide.xml`,
`quick_start_guide.xml`, `upgrade_guide.xml`, `server_guide.xml`,
`glossary.xml`) and all 50 developer-doc files under
`dev-docs-docbook/de_x_sie/` against phpBB's real German (Formal
Honorifics) language pack (`phpbb-de/phpbb-translation`,
`language/de_x_sie/`).

Six of the seven chapters — every one except `admin_guide.xml` — have
had a full line-by-line pass and are confirmed clean. Real mismatches
were found and fixed along the way, not just close paraphrases but
different literal button and field labels, and in several cases an
entire feature described with the wrong term: the "Manage extensions"
pages being confused with phpBB's unrelated Extensions/mods feature,
predefined permission-role names like "Vollmoderator" not matching the
real "Umfassender Moderator", and "Moderatorkontrollzentrum"/
"Administrationskontrollzentrum" not matching the real
"Moderations-Bereich"/"Administrations-Bereich" (see the commit log
for the full list).

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

Only `admin_guide.xml` still has open ground. It started with 219
unmatched `<guilabel>`/`<guimenuitem>`/`<title>` strings; about 70 have
since been tracked down to real key matches and fixed — wrong ACP page
titles, dropdown labels, table column headers, and settings
descriptions that didn't match the real board's wording. About 149
remain unmatched, and nearly all of them fall into one of two buckets
rather than being live bugs: grammatical case forms that will never
literally match a dictionary-form language-pack value (e.g. "Namens des
Boards", correct genitive case), and strings the English source itself
paraphrases rather than quotes literally, which the German mirrors
faithfully. A small number are genuinely unconfirmed rather than
either — no matching key could be found at all — and those are listed
in `docs/TODO/todo-german-translation-human-review.md`.

## How to do this

For each `<guilabel>`/`<guimenuitem>` string, identify the real phpBB
language key it corresponds to (grep the relevant `language/de_x_sie/`
or `language/de_x_sie/acp/` file from
[phpbb-de/phpbb-translation](https://github.com/phpbb-de/phpbb-translation)
by its English string first, via `language/en/`, to find the key, then
check the German value) and fix the document if it differs. Verify
with a real `./phpbbdocs_hugo.sh de_x_sie` build afterward.
