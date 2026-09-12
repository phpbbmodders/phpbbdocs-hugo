# Danish (da) supplementary glossary

A working glossary for Danish terms across the seven end-user chapters
where the terminology audit (see
[`todo-danish-da-terminology-audit.md`](todo-danish-da-terminology-audit.md))
either found no matching string in phpBB's real Danish language pack
(`scootergrisen/phpbb_da`), or found a plausible-but-unconfirmed
alternate wording. That's not the same as "wrong" — for genuinely
unmatched terms there's simply no official phpBB string to check the
wording against, so a native speaker has to judge it on its own
merits. `dev-docs-docbook/da/` has not yet been checked at all (see
the audit doc), so it has no entries here yet.

**How to use this file:** for each row, fill in "Agreed Danish term"
with the wording the team settles on (it can just be the current
wording, confirmed as-is, or something new), "Confirmed by" with a
name, and "Date" (YYYY-MM-DD). Once a row is filled in, its term is
the project's standing glossary decision.

## Open terminology-choice question: "kodeord" vs. "adgangskode", "email" vs. "e-mail"

Unlike the confirmed "smilies"→"smileys" fix already applied (see the
audit doc), these two are not obvious typos — both are legitimate
Danish words/spellings, so this needs a native speaker's call before
any project-wide change, the same way the German audit's "Ausdünnen"
and the French audit's "sticky"/"Note" cases were left open rather
than force-changed.

The real language pack consistently uses **"Adgangskode"** (`PASSWORD`
→ `Adgangskode`, `NEW_PASSWORD` → `Ny adgangskode`,
`PASSWORD_CONFIRMATION` and similar keys) and consistently
**hyphenates "e-mail"** (`EMAIL_ADDRESS` → `E-mailadresse`). The
existing translation instead uses "kodeord" (36 occurrences) and
unhyphenated "email" (128 occurrences), concentrated here:

| Term | Occurrences | Chapters |
|---|---|---|
| kodeord | 36 | `admin_guide.xml` (29), `quick_start_guide.xml` (4), `glossary.xml` (2), `user_guide.xml` (1) |
| email (unhyphenated) | 128 | `admin_guide.xml` (107), `user_guide.xml` (16), `glossary.xml` (4), `moderator_guide.xml` (1) |

| English source | Current Danish | Location | Agreed Danish term | Confirmed by | Date |
|---|---|---|---|---|---|
| Password | kodeord (throughout) | see table above | | | |
| Email | email (throughout, unhyphenated) | see table above | | | |

## Genuinely unconfirmed terms — `moderator_guide.xml`, `quick_start_guide.xml`, `upgrade_guide.xml`, `user_guide.xml`

These four chapters' residual unmatched terms have been individually
reviewed; none turned out to be a confirmed language-pack mismatch
beyond the smilies fix already applied.

| English source / concept | Current Danish | Location | Note | Agreed Danish term | Confirmed by | Date |
|---|---|---|---|---|---|---|
| Can delete posts | Kan slette indlæg | moderator_guide.xml:110 | No candidate key found. | | | |
| Moderator tools | Redaktørværktøjer | moderator_guide.xml:125,177 | No candidate key found. | | | |
| Global announcements | Globale bekendtgørelser | moderator_guide.xml:165 | No candidate key found. | | | |
| Split from selected post onward | Del fra valgte indlæg og fremefter | moderator_guide.xml:178 | No candidate key found. | | | |
| Find topic | Find emne | moderator_guide.xml:204 | No candidate key found. | | | |
| Report this post | Rapporter dette indlæg | moderator_guide.xml:232 | No candidate key found. | | | |
| Moderator Control Panel | Redaktørkontrolpanelet | moderator_guide.xml:246 | No candidate key found (parallel to the German/French MCP-naming entries). | | | |
| Resynchronise | Resynkroniser | moderator_guide.xml:333 | No candidate key found. | | | |
| Change topic type | Ændre emnetype | moderator_guide.xml:334 | No candidate key found (parallel to the French glossary entry). | | | |
| Start Install | Start installation | quick_start_guide.xml:105 | No candidate key found (parallel to the German/French glossary entries). | | | |
| Database server hostname / port / DSN / name | Databaseserverens værtsnavn eller DSN, Databaseserverens portnummer, Databasenavnet | quick_start_guide.xml:115,118,121 | No candidate keys found for this installer-form cluster. | | | |
| Table prefix | tabelpræfiks for tabellerne | quick_start_guide.xml:141 | No candidate key found. | | | |
| Continue to next step | Fortsæt til næste trin | quick_start_guide.xml:142 | No candidate key found (installer-specific string, not in the fetched acp/help/root pack). | | | |
| Could not connect to the database | Kunne ikke forbinde til databasen | quick_start_guide.xml:143 | English source itself paraphrases the real error message (same non-issue confirmed in the German/French audits). | | | |
| Advanced settings | Avancerede indstillinger | quick_start_guide.xml:161 | No candidate key found. | | | |
| Board timezone | Tidszone for board | quick_start_guide.xml:192 | No candidate key found. | | | |
| Max characters per post | Maksimalt antal tegn pr. indlæg | quick_start_guide.xml:213 | No candidate key found. | | | |
| Forum administration | Forumadministation | quick_start_guide.xml:231 | Note: possible typo in the existing Danish ("Administation" missing an "r") independent of the pack-matching question — worth a native speaker's look regardless of the terminology question. | | | |
| Back to previous page | Tilbage til foregående side | quick_start_guide.xml:248 | No candidate key found. | | | |
| Permission roles | Tilladelseroller | quick_start_guide.xml:315 | No candidate key found. | | | |
| Refresh page to continue conversion | Genindlæs siden for at fortsætte konverteringen | upgrade_guide.xml:586 | Installer-specific string; not present in the fetched acp/help/root pack cache (install language files weren't fetched for this audit). | | | |
| Begin Conversion / Continue Conversion | Begynd konvertering / Fortsæt konvertering | upgrade_guide.xml:587,588,589 | Same as above — installer-specific strings not in the fetched pack. | | | |
| Account activation notice (templated) | "Din konto er oprettet. ..." | user_guide.xml:52 | Long templated confirmation message with embedded variables; likely a non-literal paraphrase, not independently confirmed (parallel to the French glossary's equivalent entry). | | | |
| Character limit notice (templated) | ...ikke må være længere end x tegn. | user_guide.xml:127 | Templated string with a variable; likely fine, not independently confirmed. | | | |
| Upload from remote URL / Link to remote location | Upload fra ekstern URL / Link til ekstern placering | user_guide.xml:131,135,136 | No candidate keys found for this pair of avatar-source options. | | | |
| Popup window on new PM | Popupvindue ved nye private beskeder | user_guide.xml:155 | No candidate key found. | | | |
| Move marked to xxx | Flyt valgte til xxx | user_guide.xml:372 | Template placeholder ("xxx" stands in for a folder name), parallel to the French glossary's "Place into folder" entry. | | | |
| Mark/unmark as important | Marker/afmarker som vigtig | user_guide.xml:393 | No candidate key found. | | | |

## `admin_guide.xml` — largest residual, triaged by theme (not yet exhaustively resolved)

163 unmatched `<guilabel>`/`<guimenuitem>` strings remain in
`admin_guide.xml`, the same situation the French audit left for its
own largest chapter. Grouped here by theme with line references so a
future pass can work through them systematically rather than
individually re-deriving the clusters:

| Theme | Example terms | Location (lines) |
|---|---|---|
| Avatar settings | Avatargallerimappens placering, Eksterne avatars, Uploud af avatars, images/avatars/gallery, images/avatars/upload | 116-119 |
| LDAP authentication | LDAP-base dn, LDAP uid, LDAP-emailattribut, LDAP-bruger dn, LDAP-kodeord | 233-238 |
| Email/SMTP/Jabber settings cluster | Boardets emailsystem er, Navn på emailfunktion, Pakkestørrelse for emails, Emailadresse for kontakt, Returadresse for emails, Signatur i emails, Brug SMTP-server til email, Autentifikationsmetode for SMTP, SMTP-kodeord, Jabberport, Jabberbrugernavn eller JID, Jabberkodeord | 260-303 |
| Gzip compression settings | Gzip, Gzip, stier & URL | 318,362,368 |
| Icon/attachment folder paths | Indlægikonmappens placering, Filtypeikonmappens placering | 374-375 |
| Misc board settings | Sessioners varighed, Anvend database-emnemarkering, Vis brugeres online og offline-status, Vis "Hop til" boksen | 521-538 |
| Search backend labels | Fulltext mysql, Fulltext native, Fulltext Native (case variant), Understøttelse af UTF-8-tegnsæt under PCRE/mbstring | 564-592 |
| BBCode template field names | INTTEXT2, fontnavn, SIMPLETEXT1 | 740 |
| PM/attachment permission toggles | Maximalt antal tilladte modtagere, Tillad samtidig afsending til flere modtagere, Tillad brug af BBkode-tag'en [IMG]/[FLASH], Tillad at vedhæfte filer i private beskeder, Visningsorden for vedhæftede filer | 769-889 |
| Icon/smiley pack management | Installer ikonpakke, Tilføj mange ikoner, Installer smileypakke | 803-834 |
| IP/hostname ban list settings | Angiv hvidlistede/sortlistede IP-adresser eller værtsnavne, Fjern IP-adresser eller værtsnavne, Maksimal bredde på miniature i pixels, IP-adresser eller værter, Ekskluder fra hvid-/sortliste | 895-915 |
| User/group management | Opret en ny gruppe, [ Find en tilmeldt bruger ], "Vælg gæstebruger", Nyt kodeord, Bekræft kodeord | 948-1095 |
| Ban/exclusion management (repeated cluster across ban-by-user/IP/email pages) | Udeluk pr. emailadresse, Vis datalog, Loghændelse, Indtil ->, Udelukkelsesgrund, Vist udelukkelsesgrund, Udeluk emailadresser, Emailadresse | 1086-1528 |
| Profile field cluster | ICQ-nummer, MSN Messenger, Hjemmeside, Indlægsindstillinger, Indstillinger for visning, Tilføj brugeren til gruppen, Slet medlem fra gruppe | 1119-1227 |
| Registration form fields | Opret et nyt felt, Vis på tilmeldingsskærmbilledet | 1374-1388 |
| Style/template management | Eksporter, Erstat typografi med, Ikke installerede typografier, Mellemlager, Genopfrisk, Genindlæs, Eksporteres, Ændre grafikpakke, Vælg grafikelement, Nuværende grafik, Valgte grafikfil, Grafikfil, Grafikbredde/-højde, Inkluder dimensioner, Gem fil lokalt | 1912-2092 |
| Forum log / search index stats | Forumlog, Antal indekserede ord i alt | 2044,2072,2132 |
| Mass email form | Emailens tekst, Prioritet for email | 2219-2220 |
| Language/extension management | Ikke installerede sprogpakker, Indsend og download | 2237,2242 |

Most of these are plausible, idiomatic Danish for their concept and
may simply reflect real pack keys this audit's fetch didn't cover
(install-specific language files were not fetched, and a handful of
ACP settings added in newer phpBB releases may postdate the fetched
pack snapshot) rather than actual mismatches — the same caveat the
French audit noted for its own untriaged residual. Confirming each
one against the real pack (or against a live phpBB 3.3 ACP install)
is the open item for a future pass.
