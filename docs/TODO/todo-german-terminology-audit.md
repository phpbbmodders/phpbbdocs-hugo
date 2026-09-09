# Exhaustive German terminology audit

Several passes (starting at commit `af72adf`, continuing through
`ce5884a`) cross-referenced UI terms across `admin_guide.xml`,
`user_guide.xml`, `moderator_guide.xml`, and `quick_start_guide.xml`
against phpBB's real German (Formal Honorifics) language pack
(`phpbb-de/phpbb-translation`, `language/de_x_sie/`) and found real
mismatches, not just close paraphrases but different literal button
and field labels, and in several cases an entire feature described with
the wrong term (see the commit log for examples, including the "Manage
extensions" pages being confused with phpBB's unrelated Extensions/mods
feature, and predefined permission-role names like "Vollmoderator" not
matching the real "Umfassender Moderator"). `upgrade_guide.xml`,
`server_guide.xml`, and `glossary.xml` were spot-checked and already
matched.

This has covered real ground, but it's still not exhaustive. As of the
last check, `admin_guide.xml` has about 155 unmatched
`<guilabel>`/`<guimenuitem>`/`<title>` strings left, most of which fall
into one of three buckets: genuine remaining mismatches still to find
and fix, grammatical case forms that will never literally match a
dictionary-form language-pack value (e.g. "Namens des Boards"), and
strings the English source itself paraphrases rather than quotes
literally (in which case the German mirrors the same paraphrase and
isn't actually wrong). Not yet fully covered:

- The remaining unmatched terms in `admin_guide.xml`. A representative
  sample of what's left: "Name der E-Mail-Funktion", the base
  `[flash]`/`[img]` BBCode-tag toggles outside private messages, the
  permission-delegation role label, a few module-management fields, and
  the online-user-list toggle. See
  `docs/TODO/todo-german-translation-human-review.md` for more detail on
  what's confirmed-fine versus genuinely unconfirmed.
- A full line-by-line pass of every remaining `<guilabel>`/
  `<guimenuitem>` string in `user_guide.xml`, `moderator_guide.xml`,
  and `quick_start_guide.xml` against the real pack.
- The 55 files under `dev-docs-docbook/de_x_sie/` (developer docs).
  These reference fewer end-user UI strings, but where they do (e.g.
  CLI flag names, ACP references), the same terminology-checking rule
  applies.

## How to do this

For each `<guilabel>`/`<guimenuitem>` string, identify the real phpBB
language key it corresponds to (grep the relevant `language/de_x_sie/`
or `language/de_x_sie/acp/` file from
[phpbb-de/phpbb-translation](https://github.com/phpbb-de/phpbb-translation)
by its English string first, via `language/en/`, to find the key, then
check the German value) and fix the document if it differs. Verify
with a real `./phpbbdocs_hugo.sh de_x_sie` build afterward.
