# German translation review notes

A native speaker's ear catches things that cross-referencing official
strings can't. Nothing below is urgent, and nothing here is known to be
broken. It's just where a second pair of eyes would help most.

## Current status

The mechanical side of this — cross-checking every UI string against
phpBB's real language pack, file by file — is done and written up in
[`todo-german-de-x-sie-terminology-audit.md`](todo-german-de-x-sie-terminology-audit.md).
This document is the other half: a native speaker reading the prose
itself, which no amount of string-matching can substitute for.

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

## Genuinely unconfirmed items

A handful of terms across `admin_guide.xml`, `moderator_guide.xml`,
and `quick_start_guide.xml` have no matching key anywhere in the
fetched language-pack files, so there's nothing to check the wording
against — that doesn't mean anything is known to be wrong, just
unverified. The full list, with English source, exact location, why
each one couldn't be confirmed, and blank columns to record the team's
decision, is the fillable
[`german-de-x-sie-supplementary-glossary.md`](german-de-x-sie-supplementary-glossary.md).

## Pre-existing issues shared with the English source

These aren't translation problems — the German is a faithful mirror of
an English original that has the same issue — but they're worth
knowing about, possibly for an upstream report. Two of them (the
thumbnail-filesize setting and "Recompile stale templates") are
documented in
[`german-de-x-sie-supplementary-glossary.md`](german-de-x-sie-supplementary-glossary.md)
alongside the real keys involved. The rest, not being terminology
questions, are only here:

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
