# Exhaustive French terminology audit

This audit cross-references UI terms across all seven end-user chapters
(`admin_guide.xml`, `user_guide.xml`, `moderator_guide.xml`,
`quick_start_guide.xml`, `upgrade_guide.xml`, `server_guide.xml`,
`glossary.xml`) against phpBB's real French language pack
(`qiaeru/phpbb-language-fr`, `language/fr/`). `dev-docs-docbook/fr/`
doesn't use `<guilabel>`/`<guimenuitem>` tags at all, so there was
nothing for it to contribute here.

Every `<guilabel>`/`<guimenuitem>`/`<title>` string in every chapter
was traced to its English source line and checked against the real
pack, not sampled. The French translation had substantially more
drift from the real language pack than German did — roughly 225 real
mismatches were found and fixed across all seven chapters (commits
`9918df5`, `d3b6933`, `868041e`, `8164b25`), from small wording
differences to some outright wrong terms:

- **"OK" should be "Aller"** — the recurring "click after choosing
  from a dropdown" button is called "Aller" on the real board (the
  same UI pattern the German audit found as "Los"), not "OK"; this
  affected 6+ places in `admin_guide.xml`.
- **"Fichiers joints" should be "Pièces jointes"** — the standard
  phpBB term for attachments, used dozens of times, was translated
  with a plain description instead of the real term.
- **"Contient"/"Ne contient pas" should be "Est comme"/"N'est pas
  comme"** — search-filter operators with a completely different
  real wording ("is like" vs "contains").
- **"Panneau de modération" should be "Panneau de contrôle de
  modération"** in `moderator_guide.xml` — missing "de contrôle"
  throughout (18 occurrences), the real MCP name.
- **"Date de naissance" should be "Anniversaire"** for the Birthday
  profile field, and six passé-composé notification-type descriptions
  that had drifted to present tense.
- A cluster of ACP install-form, permissions, and settings labels
  across `quick_start_guide.xml` and `admin_guide.xml` that didn't
  match the real board wording at all (see commit messages for the
  full per-chapter lists).

## Current state per chapter

`moderator_guide.xml`, `upgrade_guide.xml`, and `quick_start_guide.xml`
had every real mismatch found and fixed; their remaining unmatched
strings are colon/apostrophe artifacts, grammatical case forms,
untranslated technical strings, or descriptive section titles — the
same non-issue categories established during the German audit — plus
a small residual documented in the supplementary glossary.
`server_guide.xml` and `glossary.xml` needed no fixes at all.

`admin_guide.xml` (213 unmatched) and `user_guide.xml` (116 unmatched)
are **not yet as exhaustively resolved as the other five chapters**.
Real fixes were applied and verified wherever a confirmed key match
existed — but given the much larger volume of drift in these two
chapters, the remaining unmatched strings have only been triaged by
category (colon/apostrophe artifact, untranslated technical term,
title-only heading, or genuine residue with no key found) rather than
each one individually hand-verified against every candidate file the
way the German audit's much smaller residual set was. The genuine
residue (no explanation found in any category) is listed in the
supplementary glossary. Finishing `admin_guide.xml` and
`user_guide.xml` to the same exhaustive standard as the other chapters
is the open item here.

## How to do this

For each `<guilabel>`/`<guimenuitem>`/`<title>` string, identify the
real phpBB language key it corresponds to (grep the relevant
`language/fr/` or `language/fr/acp/` file from
[qiaeru/phpbb-language-fr](https://github.com/qiaeru/phpbb-language-fr)
by its English string first, via `language/en/`, to find the key, then
check the French value) and fix the document if it differs. Watch for
false positives from crude string matching: curly vs straight
apostrophes (`’` vs `'`) are extremely common in this pack and account
for a large share of the "unmatched" strings that are actually
correct. When the English source itself is a non-literal paraphrase of
a heading or description (not a literal UI quote), the French
mirroring that same paraphrase is not a bug. Verify with a real
`./phpbbdocs_hugo.sh fr` build afterward.
