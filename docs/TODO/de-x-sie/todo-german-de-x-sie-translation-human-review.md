# German translation review notes

A native speaker's ear catches things that cross-referencing official
strings can't. Nothing below is urgent, and nothing here is known to be
broken. It's just where a second pair of eyes would help most.

## Current status

`content/de_x_sie/` (the German docs, formal "Sie" register) has had a
full, exhaustive line-by-line terminology cross-check against phpBB's
real German language pack (the same one used on live German phpBB
boards), covering every chapter — `admin_guide.xml`, `user_guide.xml`,
`moderator_guide.xml`, `quick_start_guide.xml`, `upgrade_guide.xml`,
`server_guide.xml`, `glossary.xml` — and all 50 files under
`dev-docs-docbook/de_x_sie/`. Every `<guilabel>`/`<guimenuitem>`/
`<title>` string in every one of these files has been individually
traced to its English source line and checked against the real
language pack, not sampled.

Around 75 real mismatches were found and fixed in `admin_guide.xml`
alone, from small things ("Smilies" became "Smileys", since the real
board never uses "Smilies" as a German word) to larger ones (an entire
section calling something "Themensymbole"/topic icons now correctly
says "Beitrags-Symbole"/post icons; the dotted-topics, read-marking,
and password-complexity toggles; several ACP page titles and dropdown
labels that didn't match the real navigation). Full details and the
"why" behind what's left unmatched (grammatical case forms, hyphenation,
and untranslated technical strings, mostly) are in
[`todo-german-de-x-sie-terminology-audit.md`](todo-german-de-x-sie-terminology-audit.md).

## Content that's never had a native read

The newly-written part of `admin_guide.xml` (everything from the "Ban
emails" section through to the end, covering groups, permissions,
moderation, styles/extensions/language packs, and system settings) is
brand new prose. Every UI label in it was cross-checked, but the
connecting sentences around those labels are new writing that no
German speaker has read yet. If you only have time for one thing, read
this section start to finish and flag anything that sounds stiff,
oddly phrased, or like it was translated rather than written.

## Spots where a judgment call was made, worth double-checking

- The user guide and moderator guide occasionally use "Ausdünnen" for
  what phpBB's own official strings usually call "Löschen"/
  "Automatisches Löschen" (English "pruning"). This was kept
  deliberately, since it was already established earlier in the
  document and switching mid-way would have been more jarring than
  helpful. If it doesn't sound right, it can be changed everywhere.
- A handful of ACP field labels reference LDAP settings
  (`LDAP-Basis-DN`, `LDAP-UID`, `LDAP-Benutzer`) using simplified plain
  text, because the real board's own strings embed small inline HTML
  tags around parts of the label that don't translate cleanly into
  this document format. The words themselves are the same as the real
  board uses; just the little bit of embedded formatting got dropped.
  Take a look and confirm they still read naturally without it.

## Genuinely unconfirmed items in admin_guide.xml

For these, no matching key could be found at all in the fetched
language-pack files, so there's nothing to check the wording against.
That doesn't mean anything is known to be wrong, just unverified. Full
detail — English source, exact location, and why each one couldn't be
confirmed — is in
[`todo-german-de-x-sie-supplementary-glossary.md`](todo-german-de-x-sie-supplementary-glossary.md),
which is meant to make it easy to turn these into entries in a
project-specific supplementary glossary:

- "Name der E-Mail-Funktion" (mail function name) — the ACP setting
  this describes may no longer exist under that name in current phpBB.
- "Abmessungen für Bildlinks" (image link dimensions), "Neues Passwort
  bestätigen" (confirm new password, in the admin's edit-user form),
  "Rückantwort-E-Mail-Adresse" (return email address), "übergeordnetes
  Modul" (module parent), "Berechtigungen kopieren" (copy permissions),
  "Benutzernamen entsperren oder Ausnahmen entfernen" (un-ban or
  un-exclude usernames), and "IP von erlaubten/nicht erlaubten
  IPs/Hostnamen ausschließen" (the exclude-IP checkbox) — all
  plausible, existing German, just not independently verified.
- The two system-requirement checks for non-Latin UTF-8 character
  support (`mbstring`/`PCRE`) — no matching key found either.

## Pre-existing issues shared with the English source

These aren't translation problems — the German is a faithful mirror of
an English original that has the same issue — but they're worth
knowing about, possibly for an upstream report:

- The "Maximum thumbnail filesize" setting's description talks about a
  maximum that gets exceeded, but the real phpBB key for that setting
  is a *minimum* filesize threshold (`MIN_THUMB_FILESIZE`). Both
  language versions describe the old/wrong behavior identically.
- "Recompile stale templates" may describe a feature that's since been
  renamed — the closest real key found is about recompiling "stale
  style components," not templates.
- The base `[flash]`/`[img]` BBCode-tag toggles outside of private
  messages aren't documented at all (only the private-message versions
  are covered, and those are confirmed correct) — a content gap in
  both languages, not a wording error.
- Four issues already noted from the dev-docs pass: a version-number
  inconsistency in `tutorial_basics.dbk`, corrupted smart-quotes in a
  code sample in `tutorial_key_concepts.dbk`, an off-by-one in
  `database_types_list.dbk`'s int ranges, and a typo plus imprecise
  example in `tutorial_templates.dbk`.

Thanks for taking a look. This kind of review is what makes a
machine-assisted translation trustworthy.
