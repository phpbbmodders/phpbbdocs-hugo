# Exhaustive German terminology audit

Several passes (starting at commit `af72adf`, continuing through
`322eaad`) cross-referenced UI terms across `admin_guide.xml`,
`user_guide.xml`, `moderator_guide.xml`, and `quick_start_guide.xml`
against phpBB's real German (Formal Honorifics) language pack
(`phpbb-de/phpbb-translation`, `language/de_x_sie/`) and found real
mismatches — not just close paraphrases, but different literal button
and field labels, and in a couple of cases an entire section using the
wrong feature name (see the commit log for examples). `upgrade_guide.xml`,
`server_guide.xml`, and `glossary.xml` were spot-checked and already
matched.

This has covered real ground, but it's still not exhaustive: there are
roughly 730 unique `<guilabel>`/`<guimenuitem>` strings across the six
end-user chapters, and `admin_guide.xml` alone still has well over 100
unmatched terms that either need a real language-pack key found for
them or are confirmed fine as-is. Not yet fully covered:

- The remaining unmatched terms in `admin_guide.xml` (avatar/attachment
  paths, contact page, word censor management, extension groups, and a
  handful of settings where no matching official string was found at
  all — see `docs/TODO/todo-german-translation-human-review.md` for the
  specific list of those).
- A full line-by-line pass of every remaining `<guilabel>`/
  `<guimenuitem>` string in `user_guide.xml`, `moderator_guide.xml`,
  and `quick_start_guide.xml` against the real pack.
- The 55 files under `dev-docs-docbook/de_x_sie/` (developer docs) —
  these reference fewer end-user UI strings, but where they do (e.g.
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
