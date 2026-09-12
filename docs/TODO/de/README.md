# German (de) TODOs

Detailed TODOs specific to the German (Casual/Du) translation:

- [Terminology audit](todo-german-de-terminology-audit.md) —
  `content/de/` and `dev-docs-docbook/de/` were produced by converting
  the already-audited `de_x_sie` (Formal/Sie) translation to the casual
  Du register, not by translating from English again. Since phpBB's
  real UI button/field labels don't change between the two registers,
  the de_x_sie terminology audit's findings carry over directly —
  confirmed by spot-checking real language-pack values (including both
  pre-existing issues phpBB dev team lead Marc confirmed) against the
  real `de` (casual) pack, and by diffing every chapter's extracted
  `<guilabel>`/`<guimenuitem>`/`<title>` strings against `de_x_sie`'s.
- [Translation review notes](todo-german-de-translation-human-review.md) —
  what's specific to the Sie→Du conversion itself and worth a native
  speaker's read, distinct from the terminology cross-checking above.
- [Supplementary glossary](german-de-supplementary-glossary.md) —
  the same genuinely-unconfirmed terms as the `de_x_sie` glossary
  (inherited for the reason above), with Du-form wording, plus the two
  confirmed pre-existing English-source bugs.
