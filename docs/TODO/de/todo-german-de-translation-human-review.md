# German (de) translation review notes

A native speaker's ear catches things that cross-referencing official
strings can't. Nothing below is urgent, and nothing here is known to
be broken. It's just where a second pair of eyes would help most.

## What's different about this translation

`content/de/` and `dev-docs-docbook/de/` were produced by converting
the already-audited `de_x_sie` (Formal/Sie) content to the casual Du
register, rather than translating from English again — see
[`todo-german-de-terminology-audit.md`](todo-german-de-terminology-audit.md)
for why the terminology-matching status carries over directly. That
means this review's focus is different from the `de_x_sie` review:
the terminology is already settled, so what's worth a native read here
is the *register conversion itself* — pronouns, possessives, and verb
conjugation changed throughout, and while every change was checked
against the source, machine-assisted grammatical conversion at this
scale (all seven end-user chapters plus all 50 dev-docs files) can
still read slightly stiff or miss a natural-sounding contraction here
and there in a way that only a native speaker would catch.

## Spots where a judgment call was made, worth double-checking

- The same "Ausdünnen" vs. "Löschen"/"Automatisches Löschen" judgment
  call noted in the `de_x_sie` review carries over unchanged (the term
  itself doesn't conjugate, so the register conversion didn't touch
  it).
- The same simplified LDAP field labels (`LDAP-Basis-DN`, `LDAP-UID`,
  `LDAP-Benutzer`) noted in the `de_x_sie` review carry over for the
  same reason.
- A handful of sentences throughout `dev-docs-docbook/de/` describe a
  file, class, or method using third-person "sie"/"ihr" (e.g. "Die
  Methode `acl`... Sie muss vor jeder ACL-Methode aufgerufen werden" —
  "it must be called," not "you must be called"). German capitalizes
  formal "Sie" (you) and third-person "sie" (it/she, for a feminine
  noun) identically at a sentence start, so these needed individual
  verification against the original `de_x_sie` source rather than
  mechanical pattern-matching. About 16 were found mechanically
  misconverted to "Du"/"dein" and corrected; if any read oddly, that's
  the specific category worth a second look.

## Genuinely unconfirmed items

Same terms as the `de_x_sie` review, for the same reason — see
[`german-de-supplementary-glossary.md`](german-de-supplementary-glossary.md).
A row filled in there should be applied to both registers.

## Pre-existing issues shared with the English source

Same two issues as the `de_x_sie` review — both confirmed as genuine
documentation bugs by phpBB dev team lead Marc (09/2026), with a fix
not expected soon since phpBB 4.0 work has priority. Documented in
[`german-de-supplementary-glossary.md`](german-de-supplementary-glossary.md).

Thanks for taking a look. This kind of review is what makes a
machine-assisted translation trustworthy.
