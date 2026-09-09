# Complete the German admin guide translation

`content/de_x_sie/chapters/admin_guide.xml` was committed truncated —
discovered while regenerating the site to verify an unrelated `de` →
`de_x_sie` directory rename (see `docs/phpbb-hugo-languages.md`).
Everything through `acp_ban_emails` is present (53 of 96 sections,
matching `content/en/chapters/admin_guide.xml`'s structure); the file
then ends mid-section at a `<!-- PART4_END -->` marker with no closing
tags, so it fails to parse and the German build currently cannot
succeed at all (`./phpbbdocs_hugo.sh de_x_sie` fails outright, not just
missing content).

Every other German chapter (`glossary.xml`, `moderator_guide.xml`,
`quick_start_guide.xml`, `server_guide.xml`, `upgrade_guide.xml`,
`user_guide.xml`) already matches its English counterpart's line count
and section count exactly — this file is the sole gap.

## Missing sections

In `content/en/chapters/admin_guide.xml`'s order, everything from
`acp_ban_ips` onward (43 sections):

```
acp_ban_ips
acp_ban_users
acp_disallow_users
acp_prune_users
acp_groups
acp_groups_types
acp_groups_edit
acp_groups_default
acp_groups_position
acp_permissions
acp_permissions_global
acp_permissions_global_user
acp_permissions_global_moderator
acp_permissions_global_administrator
acp_permissions_forumbased
acp_permissions_forumbased_user
acp_permissions_forumbased_moderator
acp_permissions_roles
acp_permissions_mask
acp_permissions_shortcuts
acp_permissions_quickstart
acp_permissions_quickstart_global_admin
acp_permissions_quickstart_global_mod
acp_permissions_quickstart_global_user
acp_permissions_quickstart_forum_mod
acp_permissions_quickstart_user_forum
acp_permissions_quick_answers
acp_customise
acp_customise_styles
acp_styles_manage
acp_customise_extensions
acp_customise_language
acp_maintenance
acp_maintenance_logs
acp_maintenance_database
acp_maintenance_search
acp_system
acp_system_updates
acp_system_spiders
acp_system_mail
acp_system_phpinfo
acp_system_reasons
acp_system_modules
```

Also close out the truncated `acp_ban_emails` section itself
(currently opens at line 1599 with no body) and the file's outer
`</chapter>` once all sections are added.

## How to do this

Translate each section from `content/en/chapters/admin_guide.xml`,
cross-referencing phpBB's real German (Formal Honorifics) language
pack (ACP menu labels, button/field names) for established
terminology rather than inventing new German phrasing for concepts
phpBB has already named. Match the existing completed sections'
tone/register (formal "Sie") and DocBook structure (`<section
id="...">`, `<sectioninfo>`/`<authorgroup>`/`<othername>` attribution
blocks, `<guilabel>` for UI labels) exactly.

Verify with a real regeneration (`./phpbbdocs_hugo.sh de_x_sie`) once
done — the build must succeed, not just parse.
