# German translation review notes

A native speaker's ear catches things that cross-referencing official
strings can't. Nothing below is urgent, and nothing here is known to be
broken. It's just where a second pair of eyes would help most.

## What's already been done

`content/de_x_sie/` (the German docs, formal "Sie" register) went through a
big pass this round:

- `admin_guide.xml` had a large chunk of missing content (roughly the second
  half of the admin guide) filled in from scratch, then checked against
  phpBB's own real German language pack (the same one used on live German
  phpBB boards) for every button label, field name, and menu item we could
  match.
- On top of that, a good number of *pre-existing* terms elsewhere in
  `admin_guide.xml`, and in `user_guide.xml`, `moderator_guide.xml`, and
  `quick_start_guide.xml`, turned out not to match the real board's wording
  and got corrected. For example, "Smilies" became "Smileys" (the real
  board never uses "Smilies" as a German word), and a whole section that
  had been calling something "Themensymbole" (topic icons) now correctly
  says "Beitrags-Symbole" (post icons), matching the real ACP page.

This pass fixed mismatches that are checkable against the real board, but
it wasn't a word-for-word comparison of every sentence. It was a targeted
pass guided by whichever official strings we could look up, and that
leaves a few kinds of gaps a human read-through would close nicely.

## Content that's new and has never had a native read

The newly-written part of `admin_guide.xml` (everything from the "Ban
emails" section through to the end, covering groups, permissions,
moderation, styles/extensions/language packs, and system settings) is
brand new prose. Every UI label in it was cross-checked, but the
connecting sentences around those labels are new writing that no German
speaker has read yet. If you only have time for one thing, read this
section start to finish and flag anything that sounds stiff, oddly
phrased, or like it was translated rather than written.

## Spots where we made a judgment call worth double-checking

- The user guide and moderator guide occasionally use "Ausdünnen" for what
  phpBB's own official strings usually call "Löschen"/"Automatisches
  Löschen" (English "pruning"). We kept "Ausdünnen" deliberately, since it
  was already established earlier in the document and switching mid-way
  would have been more jarring than helpful. If it doesn't sound right to
  you, we're glad to change it everywhere.
- A handful of ACP field labels reference LDAP settings (`LDAP-Basis-DN`,
  `LDAP-UID`, `LDAP-Benutzer`) using simplified plain text, because the
  real board's own strings embed small inline HTML tags around parts of
  the label that don't translate cleanly into this document format. The
  words themselves are the same as the real board uses; just the little
  bit of embedded formatting got dropped. Take a look and confirm they
  still read naturally without it.

## Areas we didn't get to check against the real board yet

A few settings groups in `admin_guide.xml` weren't cross-referenced this
round, mostly because we couldn't find the matching official string in the
files we had on hand. That doesn't mean anything is known to be wrong,
just unconfirmed either way:

- The "Name der E-Mail-Funktion" field.
- The "dotted topics" setting (topics you've already posted in getting a
  visual marker). It currently reads "Gepunktete Themensymbole aktivieren".
- The base `[flash]`/`[img]` BBCode-tag toggles outside of private
  messages (the private-message versions were confirmed and fixed).
- The permission-role labels used for delegating permission-management
  (e.g. "Kann die Berechtigungen anderer verwenden").
- A handful of module-management fields ("Modulmodus auswählen", "Formular
  auswählen") and the online-user-list toggle ("Online-Benutzerlisten
  aktivieren").

None of these are guessed wildly. They're existing, presumably reasonable
German, just not independently verified against the live board's own
wording the way most of the rest of the document was.

A later pass fixed a much larger number of real mismatches than the first
round caught, including several that were quietly wrong in a way that
would mislead a German admin: the word-censor field labels, the "Manage
extensions"/"Manage extension groups" pages (previously confused with
phpBB's unrelated Extensions/mods feature, since both use the German word
"Erweiterung"), the predefined permission-role names ("Vollmoderator" vs
the real "Umfassender Moderator", and several others), the five
server-configuration category tabs, avatar upload buttons, mass-email and
Jabber package-size fields, and the "Find a member"/"Select Anonymous
User" controls used throughout the user-management pages. See
[`todo-german-terminology-audit.md`](todo-german-terminology-audit.md)
for the ongoing exhaustive pass.

## Bigger pieces not touched this round at all

- Five of the seven end-user chapters (`glossary.xml`, `server_guide.xml`,
  `upgrade_guide.xml`, and to a lesser extent `moderator_guide.xml` and
  `quick_start_guide.xml`) only got a partial check, not a full
  line-by-line one.
- The 55 files under `dev-docs-docbook/de_x_sie/` (the developer
  documentation) haven't been looked at for terminology at all yet. They
  lean more technical and less UI-label-heavy than the end-user guides, so
  they may need less of this kind of check, but nobody's actually looked.

If you'd rather we keep working through the remaining official-string
cross-checking ourselves instead of (or before) a human pass, that's
tracked separately in
[`todo-german-terminology-audit.md`](todo-german-terminology-audit.md).
This document is specifically about the parts that benefit from a native
speaker's judgment, not another round of string-matching.

Thanks for taking a look. This kind of review is what makes a
machine-assisted translation trustworthy.
