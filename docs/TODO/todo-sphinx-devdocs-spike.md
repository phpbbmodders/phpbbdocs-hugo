# Sphinx dev-docs pipeline: Phase 0 spike results

## Status: spike successful — full mechanical path proven on one file

`docs/phpbb-gettext-translation-plan.md` proposes a Sphinx-native gettext
pipeline for developer docs (`dev-docs-docbook/`), as a replacement for
the current Pandoc/DocBook/hand-translation path. Before this spike,
nothing on that track existed beyond planning docs — no code, and the two
POC artifacts the plan/POC-results doc reference (`poc_sphinx_hugo.xsl`,
`fix_csv_table_headers.py`) were never actually committed to this repo.

This spike ran the complete proposed path end to end against one real
file — `upstream-phpbb-documentation/development/testing/unit_testing.rst`
(headings, prose, inline markup, external links, two languages of code
block, an enumerated list; deliberately not one of the 13 files using
`.. csv-table::`, to isolate that separate, already-known bug) — using a
synthetic placeholder translation (every string prefixed `[XX]`) rather
than a real language, so the result answers "does the pipeline work"
without conflating it with translation quality:

1. **`sphinx-build -b gettext`** against a minimal `conf.py` (see decision
   below) → clean `.pot`, one msgid per heading/paragraph, code blocks
   correctly excluded from extraction.
2. **Synthetic `.po`** filled via `polib`, compiled with `msgfmt`.
3. **`sphinx-build -b xml -D language=xx`** → real Docutils XML, every
   translated string present with `translated="True"`, inline markup
   (`<literal>`, `<strong>`, `<reference>`) correctly re-parsed into
   structured elements — richer than raw RST-in-msgid would suggest.
4. **A minimal XSLT** (`xsltproc`, matching this project's existing
   toolchain rather than introducing a new one) transformed that XML into
   Hugo-ready Markdown + YAML front matter — headings, code fences with
   the correct language tag, inline formatting, links, and an ordered
   list.
5. **`hugo` build** of the result produced a real HTML page: correct
   heading hierarchy, Chroma syntax highlighting on both the PHP and XML
   code blocks (picked up automatically from the fence language, no extra
   work needed), correct ordered-list rendering despite the XSLT literally
   emitting `1.` for every item (Goldmark renumbers automatically — a
   cosmetic non-issue).

**Recommendation: proceed with the Sphinx-native architecture.** Every
step worked cleanly on real content, and the intermediate output (POT,
localized XML, rendered HTML) was inspected directly at each stage, not
just checked for "didn't crash."

## Decision resolved: `conf.py` extensions

Confirmed by direct grep of all 55 `.rst` files under `development/` for
every role/directive the declared `sensio.sphinx.*`, `sphinxcontrib.
phpdomain`, and `sphinx_multiversion` extensions provide: **zero
matches**. None of it is used in current content, even though Symfony is
likely why it's *declared* (phpBB's backend direction, not doc content).
The spike's `conf.py` used `extensions = []` and `smartquotes = False`
(matching this project's established straight-quote convention, flagged
in the original plan as needed but never set) — no vendoring of
`fabpot/sphinx-php` needed. Revisit only if future upstream content
actually starts using PHP-domain roles.

## What a real (non-spike) transform needs, beyond this spike's coverage

The spike's XSLT (kept as scratch, not committed — it only covers one
file's element vocabulary, explicitly not meant to generalize as-is)
handled: `section` (recursive, arbitrary depth), `title`, `paragraph`,
`literal_block` (with `@language`), `enumerated_list`/`list_item`,
`literal`, `strong`, `reference`, `target` (suppressed — anchor-only, no
visible content). A production transform needs at minimum, based on
element types visible elsewhere in the 55-file corpus but not exercised by
this one file:

- `bullet_list` (unordered lists) alongside `enumerated_list`
- `emphasis` (italic) alongside `strong`
- `table`/`tgroup`/`thead`/`tbody`/`row`/`entry` (Docutils' table
  structure — same general shape problem `proteus_hugo_devdocs.xsl`
  already solved for DocBook's `informaltable`, different vocabulary)
- `note`/`warning`/`tip`-equivalent admonition directives (RST's
  `.. note::` etc. — need to confirm Docutils' exact XML element names
  for these before generalizing)
- Internal cross-references (`:doc:`/`:ref:` roles) resolving to Hugo
  page links, not just the external `reference`/`target` pair this file
  happened to use
- The `names` attribute quirk noted during the spike: Sphinx keeps a
  section's *original* (untranslated) name alongside the translated one
  for cross-reference stability (e.g. `names="running unit tests [xx]
  running unit tests"`) — a real transform should anchor on `ids`, not
  `names`, and should be aware this attribute holds multiple
  space-separated values, not one

None of this was proven or disproven by the spike — it's scoped-out
follow-up work, listed here so the next phase isn't rediscovering it from
scratch.

## Still open, unrelated to whether the pipeline works

These don't block the Sphinx-native decision above, but remain real,
separate problems for whenever full rollout is scoped:

- **CSV-table content-loss bug** (13 files) — real, upstream-caused,
  currently masked by the Pandoc path tolerating it silently. Needs its
  own fix script (the POC's `fix_csv_table_headers.py` was verified
  working but never committed — this spike didn't touch it).
- **`translations.sh` has no `development` family support.** Its
  `lib.py` metadata schema already anticipates one (`record-source`/
  `read-source` accept `family=development`), but the PO-path/
  source-path helpers and every `cmd_*` function are hard-coded to
  `content/*/chapters/`. Needs its own source-revision tracking against
  the separate `upstream-phpbb-documentation` checkout, not this repo's
  own git history (`current_hugo_commit()`'s current approach doesn't
  apply).
- **Existing hand-translated dev-docs content isn't migrated.**
  `da`/`fr`/`it` have 55 hand-translated files, `de`/`de_x_sie` only 50 —
  real drift already exists, a migration path needs designing (the
  `align_existing_translation.py`/`align_glossary_by_term.py` scripts
  built for the DocBook end-user-docs pipeline don't transfer: they
  assume itstool's `#. path: ...` POT comments and DocBook element names,
  neither of which apply to Sphinx/RST).
- **No round-trip audit equivalent** for this pipeline yet (the DocBook
  side has `translations.sh audit` — see `docs/TODO/todo-po-roundtrip-audit.md`
  and `docs/gettext-workflow-checklist.md`; a Sphinx-side version needs
  designing once there's real per-language content to audit against).

## Recommended next step

Given the spike succeeded, the natural Phase 1 would be generalizing the
transform against a wider slice of real files (enough to hit every
element type above) before committing to `translations.sh` integration or
touching any real language's content — same walking-skeleton approach,
next size up. Not started as part of this plan; a decision for whenever
that's prioritized.
