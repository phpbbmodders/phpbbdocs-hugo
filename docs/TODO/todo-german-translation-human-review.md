# German translation review notes

A native speaker's ear catches things that cross-referencing official
strings can't. Nothing below is urgent, and nothing here is known to be
broken. It's just where a second pair of eyes would help most.

## Current status

`content/de_x_sie/` (the German docs, formal "Sie" register) has had a
line-by-line terminology cross-check against phpBB's real German
language pack (the same one used on live German phpBB boards) for
every chapter except `admin_guide.xml`: `user_guide.xml`,
`moderator_guide.xml`, `quick_start_guide.xml`, `upgrade_guide.xml`,
`server_guide.xml`, and `glossary.xml` are all fully checked and clean.
The 50 files under `dev-docs-docbook/de_x_sie/` have likewise had a
full read-through for translation fidelity and technical accuracy.

`admin_guide.xml` is the one file that isn't fully exhaustive yet. It
had a large chunk of missing content (roughly the second half of the
admin guide) filled in from scratch, and every button label, field
name, and menu item that could be matched against the real language
pack has been cross-checked and corrected where wrong — for example
"Smilies" became "Smileys" (the real board never uses "Smilies" as a
German word), and a section that had been calling something
"Themensymbole" (topic icons) now correctly says "Beitrags-Symbole"
(post icons). What's left is tracked in detail in
[`todo-german-terminology-audit.md`](todo-german-terminology-audit.md)
(about 155 unmatched strings, mostly grammatical case forms and
English-source paraphrases rather than real errors).

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

## Areas in admin_guide.xml not yet checked against the real board

A few settings groups weren't cross-referenced, mostly because the
matching official string couldn't be found in the files on hand. That
doesn't mean anything is known to be wrong, just unconfirmed either
way:

- The "Name der E-Mail-Funktion" field.
- The "dotted topics" setting (topics you've already posted in getting
  a visual marker). It currently reads "Gepunktete Themensymbole
  aktivieren".
- The base `[flash]`/`[img]` BBCode-tag toggles outside of private
  messages (the private-message versions were confirmed and fixed).
- The permission-role labels used for delegating permission-management
  (e.g. "Kann die Berechtigungen anderer verwenden").
- A handful of module-management fields ("Modulmodus auswählen",
  "Formular auswählen") and the online-user-list toggle
  ("Online-Benutzerlisten aktivieren").

None of these are guessed wildly. They're existing, presumably
reasonable German, just not independently verified against the live
board's own wording.

If you'd rather the remaining official-string cross-checking in
`admin_guide.xml` gets finished first instead of (or before) a human
pass, that's tracked separately in
[`todo-german-terminology-audit.md`](todo-german-terminology-audit.md).
This document is specifically about the parts that benefit from a
native speaker's judgment, not another round of string-matching.

Thanks for taking a look. This kind of review is what makes a
machine-assisted translation trustworthy.
