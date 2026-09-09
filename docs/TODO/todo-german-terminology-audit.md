# Exhaustive German terminology audit

A representative pass (commit `af72adf`) cross-referenced UI terms in
`user_guide.xml`, `moderator_guide.xml`, and `quick_start_guide.xml`
against phpBB's real German (Formal Honorifics) language pack
(`phpbb-de/phpbb-translation`, `language/de_x_sie/`) and found real
mismatches — not just close paraphrases, but different literal button
and field labels (see that commit for examples). `upgrade_guide.xml`,
`server_guide.xml`, and `glossary.xml` were spot-checked and already
matched.

That pass was representative, not exhaustive: there are roughly 730
unique `<guilabel>`/`<guimenuitem>` strings across the six end-user
chapters, and only a sample was actually checked against the real
language files per chapter. Not yet covered at all:

- A full line-by-line pass of every remaining `<guilabel>`/
  `<guimenuitem>` string in `user_guide.xml`, `moderator_guide.xml`,
  and `quick_start_guide.xml` against the real pack.
- The 55 files under `dev-docs-docbook/de_x_sie/` (developer docs) —
  these reference fewer end-user UI strings, but where they do (e.g.
  CLI flag names, ACP references), the same terminology-checking rule
  applies.
- `admin_guide.xml`'s originally-shipped sections (everything before
  `acp_ban_emails` — the part that predated the truncation fix in
  commit `fc25f5c`) — only the newly-written sections in that commit
  were checked against the real pack while writing them; the
  pre-existing ~1,600 lines haven't been re-checked.

## How to do this

For each `<guilabel>`/`<guimenuitem>` string, identify the real phpBB
language key it corresponds to (grep the relevant `language/de_x_sie/`
or `language/de_x_sie/acp/` file from
[phpbb-de/phpbb-translation](https://github.com/phpbb-de/phpbb-translation)
by its English string first, via `language/en/`, to find the key, then
check the German value) and fix the document if it differs. Verify
with a real `./phpbbdocs_hugo.sh de_x_sie` build afterward.
