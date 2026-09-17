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
  — the Sphinx-native gettext pipeline has replaced the old Pandoc-based
  dev-docs pipeline as the documented build path: a real, committed
  converter validated against the full 55-file upstream corpus,
  `translations.sh` full `devdocs-*` CLI support, all 5 languages (fr,
  da, it, de, de_x_sie) translated to 100% in its PO catalogs, and the
  live-site cutover itself (toctree-derived chapter/page ordering,
  `_index.md` generation, `site/content/<lang>/development/` as the
  real build target) all complete and verified.
- [Old dev-docs pipeline cleanup](TODO/todo-old-devdocs-pipeline-cleanup.md)
  — the old Pandoc/DocBook pipeline (`dev-docs-docbook/`,
  `phpbbdocs_hugo_devdocs.sh`, `convert_dev_docs_to_docbook.sh`,
  `xsl/proteus_hugo_devdocs.xsl`) gets no more maintenance and is left
  in place only until the live-site cutover above has proven itself,
  then should be physically removed — tracked separately so it isn't
  forgotten.
