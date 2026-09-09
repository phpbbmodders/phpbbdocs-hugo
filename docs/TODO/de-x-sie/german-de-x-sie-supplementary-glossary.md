# German (de-x-sie) supplementary glossary

A working glossary for German (Formal Honorifics) terms across all
seven end-user chapters where the exhaustive terminology audit (see
[`todo-german-de-x-sie-terminology-audit.md`](todo-german-de-x-sie-terminology-audit.md))
could not find a matching string anywhere in phpBB's real language
pack (`phpbb-de/phpbb-translation`). That's not the same as "wrong" —
it just means there's no official phpBB string to check the wording
against, so a native speaker has to judge it on its own merits rather
than by comparison. `dev-docs-docbook/de_x_sie/` doesn't use
`<guilabel>`/`<guimenuitem>` tags at all as of this audit, so it has no
entries here yet — but if a future edit to the dev-docs introduces a
real UI term with no phpBB language-pack match (the same situation
that produces every other row in this table), add it here too rather
than starting a separate dev-docs glossary.

**How to use this file:** for each row, fill in "Agreed German term"
with the wording the team settles on (it can just be the current
wording, confirmed as-is, or something new), "Confirmed by" with a
name, and "Date" (YYYY-MM-DD). Once a row is filled in, its term is
the project's standing glossary decision — future edits to that
chapter should use it, and it's worth checking new content against
this table before introducing a competing translation for the same
concept.

| English source | Current German | Location | Why unconfirmed | Agreed German term | Confirmed by | Date |
|---|---|---|---|---|---|---|
| Email function name | Name der E-Mail-Funktion | admin_guide.xml:314 | The ACP setting this describes may no longer exist under that name in current phpBB; no candidate key found at all. | | | |
| Return email address | Rückantwort-E-Mail-Adresse | admin_guide.xml:317 | Closest real key found (`EMAIL_FORCE_SENDER`) is a related but different setting (a toggle, not this address field). | | | |
| Support for non-latin UTF-8 characters using PCRE | Unterstützung für nicht-lateinische UTF-8-Zeichen mittels PCRE | admin_guide.xml:651 | System-requirement/diagnostic string; no matching key found in the fetched language files. | | | |
| Support for non-latin UTF-8 characters using mbstring | Unterstützung für nicht-lateinische UTF-8-Zeichen mittels mbstring | admin_guide.xml:652 | Same as above. | | | |
| Image link dimensions | Abmessungen für Bildlinks | admin_guide.xml:1069 | No candidate key found in `acp/attachments.php` or elsewhere searched. | | | |
| Exclude IP from [dis]allowed IPs/hostnames | IP von erlaubten/nicht erlaubten IPs/Hostnamen ausschließen | admin_guide.xml:1075 | The doc's own explanation text matches `EXCLUDE_ENTERED_IP`'s *explanation* string closely, but that key is a sentence, not a short label — the real label for this checkbox wasn't confirmed. | | | |
| Confirm new password (admin edit-user form) | Neues Passwort bestätigen | admin_guide.xml:1258, 1260 | This is the admin's "edit another user's password" form. The UCP's own `CONFIRM_PASSWORD` key ("Bestätigung des Passworts") is a different, self-service context — no admin-specific equivalent was found. | | | |
| Un-ban or un-exclude usernames | Benutzernamen entsperren oder Ausnahmen entfernen | admin_guide.xml:1682, 1684 | No dedicated form-title key found in `acp/ban.php` (only per-item log strings like `USER_UNBAN`). | | | |
| Copy permissions | Berechtigungen kopieren | admin_guide.xml:2165 | Real keys found (`COPY_PERMISSIONS` in both `acp/groups.php` and `acp/forums.php`) both end in "...von"/"...from" — this usage describes the action standalone, without an object, so it's unclear whether the bare form matches a real UI string or needs the suffix. | | | |
| Module parent | übergeordnetes Modul | admin_guide.xml:2587 | The closest real key (`PARENT` in `acp/modules.php`) is just "Übergeordnet" alone, with no "Modul" — plausibly this doc's fuller phrase is clearer prose rather than a literal quote, but that wasn't confirmed either way. | | | |
| Change topic type | Themenart ändern | moderator_guide.xml:96, 397 | No dedicated dropdown-label key found in `root/mcp.php` (only post-action success messages like `TOPIC_TYPE_CHANGED`). | | | |
| Start Install | Installation starten | quick_start_guide.xml:126 | No matching button-label key found in `root/install.php` (only related strings like `INSTALL_RESTART`). | | | |
| (download config.php) | herunterzuladen | quick_start_guide.xml:178 | No matching key found for this specific installer download step. | | | |
| VigLink "Convert account" | Konto umwandeln | quick_start_guide.xml:200 | This is the bundled VigLink extension's own string, not phpBB core — its language files live outside `phpbb-de/phpbb-translation` entirely (confirmed: no `ext/` directory exists in that repo), so there's nothing to check it against. | | | |
| VigLink settings | VigLink-Einstellungen | quick_start_guide.xml:200 | Same as above — extension-specific, not covered by the core language pack. | | | |

## Two pre-existing issues shared with the English source (not glossary candidates)

These aren't candidates for a glossary entry, since the English
original has the identical problem — any fix belongs in a report
against the upstream documentation source, not in this glossary:

- **Maximale Vorschaubild-Dateigröße** (admin_guide.xml:1067,
  "Maximum thumbnail filesize"): the description talks about a maximum
  that gets exceeded, but the real phpBB key for this setting
  (`MIN_THUMB_FILESIZE`) is a *minimum* filesize threshold. Both
  languages describe the same outdated/incorrect behavior.
- **Veraltete Vorlagen neu kompilieren** (admin_guide.xml:598,
  "Recompile stale templates"): the closest real key
  (`RECOMPILE_STYLES`) is about recompiling stale *style components*,
  not templates — this may describe a renamed feature in both
  languages.
