# Italian (it) supplementary glossary

A working glossary for Italian terms across the end-user chapters
where the exhaustive terminology audit (see
[`todo-italian-it-terminology-audit.md`](todo-italian-it-terminology-audit.md))
could not find a matching string anywhere in phpBB's real Italian
language pack (the current `Italian_3_3_16` contribution by alex75 on
phpBB.com, not the stale `phpbbitalia/phpbb-it` GitHub mirror). That's
not the same as "wrong" — it just means there's no official phpBB
string to check the wording against, so a native speaker has to judge
it on its own merits rather than by comparison. `dev-docs-docbook/it/`
doesn't use `<guilabel>`/`<guimenuitem>` tags at all as of this audit,
so it has no entries here yet — but if a future edit introduces a real
UI term with no phpBB language-pack match, add it here too.

This is a curated selection of the more substantive open questions
from `admin_guide.xml` and `user_guide.xml`'s residual unmatched
strings, not literally every one of the roughly 360 remaining
`NO_KEY` strings — most of the rest are settled non-issues
(untranslated technical terms, quote/colon artifacts, grammatical
variants) documented by category in the audit doc rather than listed
individually here.

**How to use this file:** for each row, fill in "Agreed Italian term"
with the wording the team settles on (it can just be the current
wording, confirmed as-is, or something new), "Confirmed by" with a
name, and "Date" (YYYY-MM-DD). Once a row is filled in, its term is
the project's standing glossary decision — future edits to that
chapter should use it, and it's worth checking new content against
this table before introducing a competing translation for the same
concept.

## Genuinely unconfirmed terms

| English source / concept | Current Italian | Location | Note | Agreed Italian term | Confirmed by | Date |
|---|---|---|---|---|---|---|
| System timezone | Fuso orario di sistema | admin_guide.xml:99 | No candidate key found. | | | |
| Allow Mass PMs | Abilita invio di messaggi privati a utenti multipli ed a gruppi | admin_guide.xml:156 | No candidate key found; doc expands the concept rather than quoting a short label. | | | |
| Email function name / Return email address | Nome della funzione e-mail / Indirizzo e-mail di risposta | admin_guide.xml:314,317 | No candidate keys found for this pair of mail() config fields. | | | |
| Run periodic tasks from system cron | Esegui le attività periodiche dal cron di sistema | admin_guide.xml:431 | No candidate key found. | | | |
| Recompile stale templates | Ricompila i template obsoleti | admin_guide.xml:599 | Same pre-existing English-source pattern the German and French audits both flagged for this setting — closest real key is about style components, not templates specifically. | | | |
| Support for non-latin UTF-8 characters (PCRE/mbstring) | Supporto per caratteri UTF-8 non latini tramite PCRE/mbstring | admin_guide.xml:652,653 | Same gap as the German and French glossaries — no matching key. | | | |
| Posting Settings (ACP page name) | Impostazioni sui contenuti | admin_guide.xml:801 | No candidate key found under this exact phrasing; a different real key (`ACP_POST_SETTINGS` → "Messaggi pubblici") was matched and fixed elsewhere in the doc for a different occurrence — this one may be the same page referenced with different English wording. | | | |
| Manage extension groups | Gestisci gruppi di estensioni | admin_guide.xml:801,1106 | No candidate key found. | | | |
| Maximum thumbnail width/filesize | Larghezza massima della miniatura in pixel / Dimensione massima del file della miniatura | admin_guide.xml:1066,1067 | No candidate key found — parallel to the same open item in the German and French glossaries. | | | |
| Exclude IP from [dis]allowed IPs/hostnames | Escludi IP dagli IP/nomi host [non] consentiti | admin_guide.xml:1075 | No candidate key found. | | | |
| Global Settings / Posting Defaults (UCP section titles) | Impostazioni generali / Impostazioni predefinite di scrittura | admin_guide.xml:1323 | No candidate key found for either title as phrased. | | | |
| Until -> (ban duration dropdown) | Fino a -> | admin_guide.xml:1612,1643,1674 | Matches the real key's base text plus an arrow decoration present in both languages' source — likely fine, listed for completeness. | | | |
| Un-ban or un-exclude usernames | Revoca il ban o rimuovi l'esclusione dei nomi utente | admin_guide.xml:1680 | No dedicated form-title key found, parallel to the German/French glossary's un-ban entries (email and IP variants of this same form title were confirmed and fixed elsewhere in this chapter). | | | |
| Team (ACP team/staff section) | Staff | admin_guide.xml:1878,1886 | English loanword used in place of a literal translation; no candidate key checked yet to confirm this is the real pack's own choice too. | | | |
| Copy permissions | Copia permessi da | admin_guide.xml:2165 | No candidate key found. | | | |
| Board Maintenance | Manutenzione del forum | admin_guide.xml:2339 | No candidate key found. | | | |
| Module parent | Modulo genitore | admin_guide.xml:2587 | No candidate key found; the guilabel-tagged bare "Parent" field label elsewhere in this same section was confirmed and fixed to "Genitore" — this longer variant wasn't independently checked. | | | |
| Custom… (avatar type dropdown) | Personalizzato… | user_guide.xml:210 | Ellipsis included in the doc's quote; no candidate key checked with matching punctuation. | | | |
| Enable smiles by default | Abilita le emoticon come impostazione predefinita | user_guide.xml:220 | English source itself reads "smiles" rather than "smilies" — likely an upstream typo, not an Italian translation issue. | | | |
| Foe (ignore-list terminology) | Ignorato | user_guide.xml:286 | Translated as "ignored" rather than a literal "nemico" — plausible and consistent with the `IS_FOE` UI behavior, but not checked against a confirmed key. | | | |
| Allow revoting (poll setting) | Permetti cambio voto | user_guide.xml:415 | No candidate key found. | | | |
| Mark as important (PM action) | Contrassegna come importante | user_guide.xml:532 | No candidate key found; a related PM action `MARK_AS_IMPORTANT` ("Evidenzia messaggio") was confirmed and fixed elsewhere in this chapter — this may be the same action described with different English wording. | | | |
| View your posts (quick-search shortcut) | Mostra i tuoi argomenti | user_guide.xml:659 | No candidate key found; translated as "topics" rather than "posts", which matches the accompanying description's own wording ("topics you have posted in") rather than being a literal mistranslation. | | | |
| Search in subforums | Cerca nei subforum | user_guide.xml:770 | No candidate key found. | | | |
