# TODO

Project-wide overview of unfinished/planned work for phpbbdocs-hugo. Detailed
plans live under `docs/TODO/`; this file stays a concise summary.

## Detailed TODOs

- [Language TODOs](TODO/language.md) — index of per-language TODO
  directories (terminology audits, translation review notes,
  supplementary glossaries).
- [Next translation priority](TODO/todo-language-priority.md) — ranks the
  remaining phpBB language packs (English, Danish, French, and German are
  done) from highest to lowest priority for the next translation, with the
  reasoning behind each tier.
- [PO round-trip content audit](TODO/todo-po-roundtrip-audit.md) — all 35
  chapter/language combinations swept and clean as of 2026-09-15; kept as
  the reference method for re-auditing after future catalog/hand-file
  changes, not an open item.
- [Sphinx dev-docs pipeline: spike results](TODO/todo-sphinx-devdocs-spike.md)
  — Phase 0 proved the proposed Sphinx-native gettext pipeline end to end
  on one real file; Phase 1 widened element coverage across two more
  files and found three real bugs (silent content loss from unescaped
  angle brackets, a blockquote/code-fence formatting bug, toctree links
  with no real target). Recommends proceeding; each remaining item
  (a real transform, `translations.sh` support, content migration) is
  its own fresh scoping decision.
