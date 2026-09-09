# German (de-x-sie) supplementary glossary reference

Every term below is a spot in `content/de_x_sie/chapters/admin_guide.xml`
where the exhaustive terminology audit (see
[`todo-german-de-x-sie-terminology-audit.md`](todo-german-de-x-sie-terminology-audit.md))
could not find a matching string anywhere in phpBB's real German
language pack (`phpbb-de/phpbb-translation`). That's not the same as
"wrong" — it just means there's no official phpBB string to check the
wording against, so a native speaker has to judge it on its own merits
rather than by comparison. This list exists to make it easy to turn
these into entries in a project-specific supplementary glossary,
should one be started.

For each entry: the German text currently in the document, the English
source phrase it translates, and the line in `admin_guide.xml` where
it appears.

| Current German | English source | Location | Note |
|---|---|---|---|
| Name der E-Mail-Funktion | Email function name | admin_guide.xml:314 | The ACP setting this describes may no longer exist under that name in current phpBB; couldn't find any candidate key at all. |
| Rückantwort-E-Mail-Adresse | Return email address | admin_guide.xml:317 | Closest real key found (`EMAIL_FORCE_SENDER`) is a related but different setting (a toggle, not this address field). |
| Unterstützung für nicht-lateinische UTF-8-Zeichen mittels PCRE | Support for non-latin UTF-8 characters using PCRE | admin_guide.xml:651 | System-requirement/diagnostic string; no matching key found in the fetched language files. |
| Unterstützung für nicht-lateinische UTF-8-Zeichen mittels mbstring | Support for non-latin UTF-8 characters using mbstring | admin_guide.xml:652 | Same as above. |
| Abmessungen für Bildlinks | Image link dimensions | admin_guide.xml:1069 | No candidate key found in `acp/attachments.php` or elsewhere searched. |
| IP von erlaubten/nicht erlaubten IPs/Hostnamen ausschließen | Exclude IP from [dis]allowed IPs/hostnames | admin_guide.xml:1075 | The doc's own explanation text matches `EXCLUDE_ENTERED_IP`'s *explanation* string closely, but that key is a sentence, not a short label — the real label for this checkbox wasn't confirmed. |
| Neues Passwort bestätigen | Confirm new password | admin_guide.xml:1258, 1260 | This is the admin's "edit another user's password" form. The UCP's own `CONFIRM_PASSWORD` key ("Bestätigung des Passworts") is a different, self-service context — no admin-specific equivalent was found. |
| Benutzernamen entsperren oder Ausnahmen entfernen | Un-ban or un-exclude usernames | admin_guide.xml:1682, 1684 | No dedicated form-title key found in `acp/ban.php` (only per-item log strings like `USER_UNBAN`). |
| Berechtigungen kopieren | Copy permissions | admin_guide.xml:2165 | Real keys found (`COPY_PERMISSIONS` in both `acp/groups.php` and `acp/forums.php`) both end in "...von"/"...from" — this usage describes the action standalone, without an object, so it's unclear whether the bare form matches a real UI string or needs the suffix. |
| übergeordnetes Modul | Module parent | admin_guide.xml:2587 | The closest real key (`PARENT` in `acp/modules.php`) is just "Übergeordnet" alone, with no "Modul" — plausibly this doc's fuller phrase is clearer prose rather than a literal quote, but that wasn't confirmed either way. |

## Two pre-existing issues shared with the English source (not translation gaps)

These aren't candidates for a German-only glossary entry, since the
English original has the identical problem — any fix belongs in a
report against the upstream documentation source, not in this
document alone:

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
