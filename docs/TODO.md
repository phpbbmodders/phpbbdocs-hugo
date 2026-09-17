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
- [Sphinx dev-docs pipeline: spike results and real converter](TODO/todo-sphinx-devdocs-spike.md)
  — the Sphinx-native gettext pipeline (proposed replacement for the
  current Pandoc-based dev-docs pipeline) has a real, committed
  converter validated against the full 55-file upstream corpus,
  `translations.sh` has full `devdocs-*` CLI support for it, and all 5
  languages (fr, da, it, de, de_x_sie) are translated to 100% in its PO
  catalogs. Not started: the actual cutover of the live site to render
  from this pipeline instead of the old Pandoc/DocBook one.
