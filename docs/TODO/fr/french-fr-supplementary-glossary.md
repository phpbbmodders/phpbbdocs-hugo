# French (fr) supplementary glossary

A working glossary for French terms across all seven end-user chapters
where the exhaustive terminology audit (see
[`todo-french-fr-terminology-audit.md`](todo-french-fr-terminology-audit.md))
could not find a matching string anywhere in phpBB's real French
language pack (`qiaeru/phpbb-language-fr`). That's not the same as
"wrong" — it just means there's no official phpBB string to check the
wording against, so a native speaker has to judge it on its own merits
rather than by comparison. `dev-docs-docbook/fr/` doesn't use
`<guilabel>`/`<guimenuitem>` tags at all as of this audit, so it has no
entries here yet — but if a future edit introduces a real UI term with
no phpBB language-pack match, add it here too.

This list is drawn from `admin_guide.xml` and `user_guide.xml`
specifically, since those two chapters' residual unmatched strings
haven't been individually re-verified to the same exhaustive standard
as the other five (see the audit doc's "Current state per chapter"
section) — a few of these may turn out to have a real match once
someone has time to dig further, rather than being confirmed gaps the
way the smaller chapters' entries are.

**How to use this file:** for each row, fill in "Agreed French term"
with the wording the team settles on (it can just be the current
wording, confirmed as-is, or something new), "Confirmed by" with a
name, and "Date" (YYYY-MM-DD). Once a row is filled in, its term is
the project's standing glossary decision — future edits to that
chapter should use it, and it's worth checking new content against
this table before introducing a competing translation for the same
concept.

## The "sticky" family — a judgment call worth a native speaker's read first

Real phpBB French calls a sticky topic **"Note"** (`POST_STICKY`,
`ICON_STICKY`), not "épinglé"/"épinglée". This word is used
pervasively across `admin_guide.xml`, `user_guide.xml`, and
`moderator_guide.xml` (title, prose, and multiple `<guilabel>`
instances) as "Sujet épinglé" / "sujets épinglés" / "Épinglé". Given
how surprising and widely-used this real term is, this was
deliberately **not** force-changed everywhere the way other confirmed
mismatches were — same treatment as the German audit's "Ausdünnen"
judgment call. If a native French speaker confirms "Note" reads
naturally for this feature, this needs a project-wide find/replace
across three chapters; if "épinglé" is kept deliberately for clarity,
say so here and this stops being an open question.

| English source | Current French | Location | Agreed French term | Confirmed by | Date |
|---|---|---|---|---|---|
| Sticky | Sujet épinglé / sujets épinglés / Épinglé | admin_guide.xml:2110,2147,2149; user_guide.xml:373,376,380; moderator_guide.xml:86,192,193,387 | | | |

## Genuinely unconfirmed terms

| English source / concept | Current French | Location | Note | Agreed French term | Confirmed by | Date |
|---|---|---|---|---|---|---|
| Email function name | Nom de la fonction e-mail | admin_guide.xml:304 | No candidate key found. | | | |
| Return email address | Adresse e-mail de retour | admin_guide.xml:307 | No candidate key found. | | | |
| Authentication method for SMTP | Méthode d'authentification pour SMTP | admin_guide.xml:317 | No candidate key found. | | | |
| LDAP base DN / UID / user | Dn de base LDAP / Uid LDAP / Utilisateur LDAP | admin_guide.xml:261,263,264 | Same judgment call as the German audit's LDAP entries — the real strings embed inline HTML the doc format can't carry; words are plausibly right, formatting isn't checkable. | | | |
| Jabber port / username or JID | Port Jabber / Nom d'utilisateur ou JID Jabber | admin_guide.xml:343,344 | No candidate key found. | | | |
| System timezone | Fuseau horaire du système | admin_guide.xml:89 | No candidate key found. | | | |
| Run cron tasks from system cron job | Exécuter les tâches périodiques depuis la tâche cron système | admin_guide.xml:421 | No candidate key found. | | | |
| Must contain alphanumeric characters | Doit contenir des caractères alphanumériques | admin_guide.xml:523,525 | No candidate key found. | | | |
| Enable use of profile fields in topic view | Afficher les champs de profil personnalisés dans la visualisation des sujets | admin_guide.xml:600 | No candidate key found. | | | |
| Recompile stale templates | Recompiler les gabarits obsolètes | admin_guide.xml:589 | Same pre-existing English-source issue flagged in the German glossary — closest real key is about "style components," not templates. Confirmed as a genuine documentation bug by phpBB dev team lead Marc (09/2026); a fix isn't expected soon since phpBB 4.0 work has priority right now. | | | |
| Allow BBCode/[flash]/[img] in signatures, PMs | Autoriser l'aperçu d'impression / le transfert / la balise [flash]/[img] dans les messages privés | admin_guide.xml:929-934 | No candidate keys found for this cluster of PM-related toggles. | | | |
| Support for non-latin UTF-8 (mbstring/PCRE) | Prise en charge des caractères UTF-8 non latins via mbstring/PCRE | admin_guide.xml:642,643 | Same gap as the German glossary — no matching key. | | | |
| Maximum image link dimensions | Dimensions du lien de l'image | admin_guide.xml:1060 | No candidate key found. | | | |
| Exclude/remove IP from allowed lists | Exclure l'IP des IP/noms d'hôte [non] autorisés / Retirer ou exclure les IP/noms d'hôte autorisés | admin_guide.xml:1047,1066 | No candidate key found. | | | |
| Maximum thumbnail width/filesize | Largeur maximale de vignette en pixels / Taille de fichier maximale de la vignette | admin_guide.xml:1057,1058 | No candidate key found (parallel to the German glossary's thumbnail-filesize entry — that one, `MIN_THUMB_FILESIZE`, is a confirmed documentation bug per phpBB dev team lead Marc, see the German glossary for detail). | | | |
| Un-ban or un-exclude usernames/IPs/emails | Débannir ou retirer l'exclusion des e-mails/IP/noms d'utilisateur | admin_guide.xml:1609-1673 | No dedicated form-title key found, parallel to the German glossary's un-ban entry. | | | |
| Until -> (ban duration dropdown) | Jusqu'à -> | admin_guide.xml:1603,1634,1665 | Matches the real key's base text plus an arrow decoration present in both languages' source — likely fine, listed for completeness. | | | |
| Registered On | Inscrit le | user_guide.xml:831 | No candidate key found. | | | |
| Field type / description / identification / required (colon labels) | Type de champ, Description du champ, Afficher le champ de profil, Afficher dans le panneau de contrôle utilisateur, Afficher sur l'écran d'inscription, Masquer le champ de profil, Champ obligatoire | admin_guide.xml:1529-1545 | No candidate key found for this custom-profile-field cluster (colon differences aside, the base phrases themselves don't match). | | | |
| Change topic type | Changer le type de sujet | moderator_guide.xml:387 | No dedicated dropdown-label key found (parallel to the German glossary entry). | | | |
| Regular Topic | Sujet normal | moderator_guide.xml:387 | No candidate key found. | | | |
| Quick Mod Tools | Outils de modération rapide | moderator_guide.xml:89,144,178 | No candidate key found. | | | |
| Can delete posts | Peut supprimer les messages | moderator_guide.xml:119 | No candidate key found. | | | |
| Soft Delete | Suppression réversible | moderator_guide.xml:120 | No candidate key found. | | | |
| Splitting posts (from selected / selected posts) | Diviser à partir du message sélectionné / Diviser les messages sélectionnés | moderator_guide.xml:209 | No candidate key found for this pair of split-topic actions. | | | |
| Start Install | Démarrer l'installation | quick_start_guide.xml:116 | No candidate key found (parallel to the German glossary entry). | | | |
| Could not connect to the database | Impossible de se connecter à la base de données | quick_start_guide.xml:159 | English source itself paraphrases the real error message (confirmed non-issue in the German audit) — listed here only for cross-reference, not actually a gap. | | | |
| Allow use of IMG BBCode tag in signatures | Autoriser l'utilisation de la balise BBCode IMG dans les signatures des utilisateurs | quick_start_guide.xml:240 | Likely a false positive (inline `<code>` tag in the real PHP source), same class as several confirmed-fine German entries — not independently re-verified for French. | | | |
| Max characters per post / Message settings | Nombre maximal de caractères par message / Paramètres des messages | quick_start_guide.xml:241 | No candidate key found. | | | |
| Administrator / Global Administrator / Moderator permissions (role names) | Permissions d'administrateur, Permissions d'administrateur global, Permissions de modérateur, Permissions utilisateur globales | admin_guide.xml, quick_start_guide.xml (multiple) | No candidate key found for this cluster of permission-type dropdown options. | | | |
| Forum permissions by group / by user | Permissions de forum par groupe / par utilisateur | quick_start_guide.xml:331; admin_guide.xml:1044 | Real keys found for the underlying concepts don't cleanly match this exact phrasing — see the audit doc for detail. | | | |
| Full Admin (role name) | Modérateur complet | admin_guide.xml:2082; quick_start_guide.xml:425 | No candidate key found. | | | |
| Founder | Fondateurs (plural) | admin_guide.xml:2046 | Real key `FOUNDER` is singular ("Fondateur"); doc uses plural in a generic reference to the role, which may be acceptable French — not force-changed. | | | |
| Friend / Foe | Ami / Ennemi | user_guide.xml:72,275,276 | Real `IS_FOE` key translates "foe" as "ignoré", not "ennemi" (already fixed where confirmed) — but the bare nouns "Ami"/"Ennemi" as dropdown option labels have no confirmed key of their own. | | | |
| Topic/Post Icon | Icône du sujet/message | user_guide.xml:316 | No candidate key found. | | | |
| BBCode/Smilies enabled/disabled (status indicators) | BBCode activé/désactivé, Émoticônes activées/désactivées | user_guide.xml:319,320 | No candidate key found for this status-indicator pair. | | | |
| Allow revoting | Autoriser à revoter | user_guide.xml:405 | No candidate key found. | | | |
| Move marked (to folder) | Déplacer la sélection | user_guide.xml:501 | Real key `MOVE_MARKED_TO_FOLDER` includes a `%s` placeholder ("...vers %s"); doc's base phrase without the destination is likely fine in context, not force-changed. | | | |
| Edit options | Modifier les options | user_guide.xml:487; moderator_guide.xml:42 | No candidate key found. | | | |
| Private Messages [X] | Messages privés [X] | user_guide.xml:433 | Bracket-notation UI counter, likely fine as-is (parallel to similar bracket entries elsewhere), not independently confirmed. | | | |
| Place into folder -> X | Placer dans le dossier -&gt; X | user_guide.xml:633 | No candidate key found (template placeholder). | | | |
| Number of replies / views | nombre de réponses / nombre de vues | user_guide.xml:234,241 | No candidate key found. | | | |
| View unread/new posts, active/unanswered topics, your posts | Voir les messages non lus / nouveaux messages / sujets actifs / sujets sans réponse / vos messages | user_guide.xml:649-653 | No candidate keys found for this cluster of UCP quick-links. | | | |
| Module parent | Module parent | admin_guide.xml:2575 | No candidate key found (parallel to the German glossary entry). | | | |
| Forum maintenance / Forum moderation (section headings) | Maintenance du forum / modération de forum | admin_guide.xml:2324,2328; admin_guide.xml:2024,2031,2045 | No candidate key found; may be descriptive section headings rather than literal UI quotes. | | | |
| Manage extension groups | Gérer les groupes d'extensions | admin_guide.xml:792,1095,1097 | No candidate key found. | | | |
| Special groups the user is a member of | Groupes spéciaux dont l'utilisateur est membre | admin_guide.xml:1377 | No candidate key found. | | | |
| Select Anonymous User / Find a member | « Sélectionner l'utilisateur anonyme » / [ Trouver un membre ] / « Trouver un membre : » | admin_guide.xml:1157 | Likely false positives from the guillemets/bracket formatting around an otherwise-correct string (same class as confirmed-fine German entries) — not independently re-verified for French. | | | |
| Find a user | Trouver un utilisateur | admin_guide.xml:1470 | No candidate key found. | | | |
| Read only | Lecture seule | admin_guide.xml:2112 | No candidate key found. | | | |
| Link from external site | Lier depuis un site externe | admin_guide.xml:1328 | No candidate key found. | | | |
| Use settings from | Utiliser les paramètres de | admin_guide.xml:2011 | No candidate key found (parallel to the German glossary's equivalent entry). | | | |
| Convert account / VigLink settings | Convertir le compte / Paramètres VigLink / VigLink | quick_start_guide.xml:190 | Bundled VigLink extension's own strings, not phpBB core — its language files live outside the fetched language pack entirely (parallel to the German glossary entry). | | | |
| Activate/Deactivate | Activer/Désactiver | admin_guide.xml:2249 | Likely fine as the concatenation of two separately-real keys (same class as the confirmed German "Aktivieren/Deaktivieren" entry) — not independently re-verified. | | | |
| Account activation notice (templated) | " Votre compte a été créé. ... " | user_guide.xml:55 | Long templated confirmation message with embedded variables; likely a non-literal paraphrase, not independently confirmed. | | | |
| There is a x character limit. | La limite est de x caractères. | user_guide.xml:156 | Templated string with a variable; likely fine, not independently confirmed. | | | |
