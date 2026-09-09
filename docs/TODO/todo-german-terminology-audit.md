# Exhaustive German terminology audit

Several passes (starting at commit `af72adf`, continuing through
`ed96545`) cross-referenced UI terms across all seven end-user
chapters (`admin_guide.xml`, `user_guide.xml`, `moderator_guide.xml`,
`quick_start_guide.xml`, `upgrade_guide.xml`, `server_guide.xml`,
`glossary.xml`) against phpBB's real German (Formal Honorifics)
language pack (`phpbb-de/phpbb-translation`, `language/de_x_sie/`) and
found real mismatches, not just close paraphrases but different
literal button and field labels, and in several cases an entire
feature described with the wrong term (see the commit log for
examples, including the "Manage extensions" pages being confused with
phpBB's unrelated Extensions/mods feature, predefined permission-role
names like "Vollmoderator" not matching the real "Umfassender
Moderator", and "Moderatorkontrollzentrum"/"Administrationskontroll-
zentrum" not matching the real "Moderations-Bereich"/"Administrations-
Bereich").

`user_guide.xml`, `moderator_guide.xml`, `quick_start_guide.xml`, and
`upgrade_guide.xml` have each had a full line-by-line pass now, not
just a representative one. `server_guide.xml` and `glossary.xml` were
fully read through and are clean (accurate, complete translations).

The 50 files under `dev-docs-docbook/de_x_sie/` (developer docs) have
also had a full read-through against their English originals. These
reference far fewer phpBB UI strings than the end-user chapters, so
the review there was mostly about translation fidelity and technical
accuracy rather than `<guilabel>` matching; it found and fixed two
real translation bugs (a mistranslated "or" that read as a
contradiction in `language/guidelines.dbk` and `language/validation.dbk`).
A handful of factual/numeric errors were also spotted in this pass
(an off-by-one in `database_types_list.dbk`'s int ranges, broken
smart-quotes in a code sample in `tutorial_key_concepts.dbk`, an
inconsistent version number in `tutorial_basics.dbk`) but these are
present identically in the English source, so they're upstream content
bugs rather than translation errors, left as-is and out of this
audit's scope.

Only `admin_guide.xml` still has open ground: about 155 unmatched
`<guilabel>`/`<guimenuitem>`/`<title>` strings, most of which fall into
one of three buckets: genuine remaining mismatches still to find and
fix, grammatical case forms that will never literally match a
dictionary-form language-pack value (e.g. "Namens des Boards"), and
strings the English source itself paraphrases rather than quotes
literally (in which case the German mirrors the same paraphrase and
isn't actually wrong). A representative sample of what's left: "Name
der E-Mail-Funktion", the base `[flash]`/`[img]` BBCode-tag toggles
outside private messages, the permission-delegation role label, a few
module-management fields, and the online-user-list toggle. See
`docs/TODO/todo-german-translation-human-review.md` for more detail on
what's confirmed-fine versus genuinely unconfirmed.

## How to do this

For each `<guilabel>`/`<guimenuitem>` string, identify the real phpBB
language key it corresponds to (grep the relevant `language/de_x_sie/`
or `language/de_x_sie/acp/` file from
[phpbb-de/phpbb-translation](https://github.com/phpbb-de/phpbb-translation)
by its English string first, via `language/en/`, to find the key, then
check the German value) and fix the document if it differs. Verify
with a real `./phpbbdocs_hugo.sh de_x_sie` build afterward.
