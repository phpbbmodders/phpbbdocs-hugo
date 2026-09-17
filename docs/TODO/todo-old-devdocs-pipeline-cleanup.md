# Old dev-docs pipeline: retire once the live-site cutover has landed and held

## Status: not started — deliberately deferred, tracked here so it isn't forgotten

The old Pandoc/DocBook dev-docs pipeline is no longer the documented
build path (see the completed live-site cutover in
[`todo-sphinx-devdocs-spike.md`](todo-sphinx-devdocs-spike.md)) and the
project owner has decided it gets no further maintenance — no more
fixing its content drift (the German `de`/`de_x_sie` 50/55-file gap in
`dev-docs-docbook/`, for example). It was deliberately left physically
in place during the cutover itself rather than deleted in the same
change, so the cutover could be reviewed and trusted before anything
old was removed.

**This TODO exists to make sure that follow-up removal actually
happens once the cutover has proven itself**, rather than the old
pipeline just quietly rotting in the repo forever because no one
circled back.

## What to remove, once ready

- `dev-docs-docbook/` (all languages — `en`, `da`, `fr`, `it`, `de`,
  `de_x_sie`) — the old pipeline's translated content, no longer read
  by anything once the cutover's build recipe is the documented one.
- `phpbbdocs_hugo_devdocs.sh` — the old build script.
- `convert_dev_docs_to_docbook.sh` — produces `dev-docs-docbook/en/`
  from upstream RST via Pandoc; only exists to feed the script above.
- `xsl/proteus_hugo_devdocs.xsl` — the old script's rendering
  stylesheet.
- Any references to the above left in `README.md`,
  `docs/translation-process-prompt.md`, or elsewhere in `docs/` after
  the cutover's own doc updates land (the cutover work updates the
  *primary* build/translator instructions, but a final sweep should
  confirm no stray mention of the old pipeline survives anywhere,
  matching this project's own "check markdown staleness" discipline).

## Before removing anything

- Confirm the new pipeline has been the actual documented/used build
  path for a real stretch of time with no regressions found (not
  removed the same day as the cutover lands).
- Re-grep the repo for the file/script names above to catch anything
  not listed here that still references them.
- This is a real deletion of committed content and scripts, not
  generated output — treat it with the same care as any other
  destructive change (confirm nothing else depends on it first).
