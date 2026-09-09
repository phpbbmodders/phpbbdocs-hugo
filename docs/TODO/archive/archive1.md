# Completed TODOs

## Complete the German admin guide translation

**Completed:** 09/09/2026

`content/de_x_sie/chapters/admin_guide.xml` was truncated mid-section
(discovered while regenerating the site to verify the `de` → `de_x_sie`
directory rename). Translated the missing 43 sections (`acp_ban_ips`
through `acp_system_modules`), plus the `acp_ban_emails` section itself,
which had also shipped with zero content. Verified with a real
`./phpbbdocs_hugo.sh de_x_sie` build — German now generates 53 pages,
matching the site's structure.

Terminology cross-referenced against phpBB's real German (Formal
Honorifics) language pack (`phpbb-de/phpbb-translation`,
`language/de_x_sie/acp/*.php`) rather than invented — ACP section
titles, button/field labels, and common UI terms (Submit, Username,
Yes/No, etc.) all match the real board.
