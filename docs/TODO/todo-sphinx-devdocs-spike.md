# Sphinx dev-docs pipeline: spike results and real converter (Phases 0-3)

## Status: converter, translations.sh CLI support, full 5-language translation rollout, and the live-site cutover are all complete

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

## Phase 1: widened element coverage, still successful

Ran the same walking-skeleton approach one size up: two more real files
— `development/development/git.rst` (555 lines: admonitions, internal
`:doc:` cross-references, bullet lists, line blocks, block quotes, an
image, and the *already-fixed* csv-table case, run through
`fix_csv_table_headers.py` on a copy first) and
`extensions/database_types_list.rst` (list-table-driven tables across
five sections) — chosen together to hit every element type Phase 0
identified as missing, in the fewest extra files. Same synthetic
`[XX]`-prefixed translation, same full pipeline, same discipline of
inspecting real output at every stage.

**Extended element coverage, all confirmed working through a real Hugo
build** (`<table>`, `<blockquote>`, headings, `<code>`/`<pre>`, `<img>`,
`<ul>`/`<ol>`, `<em>`/`<strong>` all present and correct in the rendered
HTML): `bullet_list`, `emphasis`, the full `table`/`tgroup`/`colspec`/
`thead`/`tbody`/`row`/`entry` structure, `note`/`warning`/`tip`/`seealso`
(Sphinx uses a distinct element per admonition type, not one generic
wrapper — confirmed by direct inspection), `title_reference` (the
single-backtick RST role — rendered as inline code, matching how this
corpus actually uses it for command/branch-name-like text), `block_quote`,
`line_block`/`line`, internal `reference[@internal='True']`, and a basic
`image`.

**Three real problems found, not just missing coverage:**

1. **Angle-bracket placeholder text causes silent content loss in Hugo,
   not just a cosmetic issue.** git.rst's prose includes literal
   `<category>/<user>/<name-or-id>`-style placeholders. Emitted as raw
   `<`/`>` into Markdown, Goldmark (Hugo's renderer) interprets them as
   unrecognized HTML tags and **silently drops them** — confirmed in the
   actual rendered HTML: "renamed to `<category>/<user>/<name-or-id>`"
   became "renamed to `//`" (the placeholder text vanished entirely, not
   just re-rendered oddly). A real transform must HTML-escape `<`/`>` in
   text content before emitting it.
2. **`block_quote` containing a `literal_block` produces invalid Markdown
   blockquote continuation.** The spike's transform prefixes the code
   fence's opening/closing lines with `>` but not the code content lines
   between them — Markdown requires every line of a blockquote to carry
   the `>` prefix, code fences included, or rendering breaks out of the
   blockquote partway through. Confirmed in the rendered output: the
   `<blockquote>` count was still correct, but this specific pattern
   needs its `>`-prefixing fixed to be reliable, not just directionally
   right.
3. **Toctree-generated navigation entries carry no real link target.**
   git.rst's `.. toctree::` directive expands into `paragraph`/
   `reference` pairs in the XML with `refuri=""` — genuinely empty, not
   just unresolved-looking. These aren't real page links to fix; they're
   Sphinx's own internal navigation construct. A real transform should
   likely skip toctree-generated links entirely and let Hugo generate its
   own section navigation instead (matching how `phpbbdocs_hugo_devdocs.sh`
   already hand-builds its own `_index.md` navigation rather than
   preserving DocBook's).

**Confirmed still accurate from Phase 0, unaffected by Phase 1:** the
`names`-vs-`ids` attribute quirk (Sphinx keeps a section's original,
untranslated name alongside the translated one for cross-reference
stability — anchor a real transform on `ids`), and the internal
cross-reference URL-resolution gap (`refuri` for a `:doc:`/`:ref:` role is
a Sphinx-relative path like `../testing/index`, not a real Hugo URL — a
production transform needs to resolve it against Hugo's actual content
path structure, which this spike does not attempt).

Spike files kept as scratch, not committed — same reasoning as Phase 0:
proving element coverage and finding real problems, not delivering a
general-purpose tool yet.

## Phase 2: the real converter

The three Phase 1 problems, plus the internal cross-reference URL gap
Phase 0/1 both flagged as unattempted, are now implemented as a real,
committed tool, not scratch:

- `xsl/proteus_sphinx_hugo.xsl` — the transform, covering the full
  element vocabulary both spikes proved.
- `translations/sphinx_to_hugo.py` — the CLI entry point (`--source-root`,
  an RST path, a `.po` catalog, `--language`, `--output`; every Sphinx
  build intermediate lives under a temp directory, never in the source
  tree or repo working directory).
- `tests/sphinx_devdocs/` — a real, assert-based test suite (fixtures:
  the 3 real files both spikes used — `development/git.rst`,
  `testing/unit_testing.rst`, `extensions/database_types_list.rst` —
  plus a shared `index.rst` and a `testing/index.rst` stub so cross-file
  `:doc:` resolution is tested against a real target, not a mock) that
  runs the actual pipeline end to end, including a real `hugo build` of
  the converted output, and checks specific rendered HTML — not just
  "did it exit 0". Run it directly:
  `python3 tests/sphinx_devdocs/test_sphinx_to_hugo.py`.

Internal-link resolution (the one gap Phase 0/1 explicitly left
unattempted) now works: a `:doc:`/`:ref:` role's Sphinx-relative
`refuri` is resolved against the current file's own directory into a
target docname, checked against every known RST file under
`--source-root`, and emitted as a Hugo `{{< relref >}}` shortcode — an
unresolvable target gets a loud inline diagnostic and an `xsl:message`
warning instead of a silent or broken link.

Still explicitly out of scope, unchanged from the "Recommended next
step" below: migrating existing hand-translated dev-docs content, and
CI. (`translations.sh` `development`-family CLI support and running the
converter against the full 55-file corpus were both completed in later
phases below — see "Phase 3" and "Full 55-file corpus sweep".)

## Still open, unrelated to whether the pipeline works

These don't block the Sphinx-native decision above, but remain real,
separate problems for whenever full rollout is scoped:

- ~~**CSV-table content-loss bug** (13 files)~~ — **fixed.**
  `fix_csv_table_headers.py` (repo root) is now a real, committed,
  idempotent script, re-verified against the real upstream checkout
  (52 headers across the same 13 files the original POC found) and
  confirmed end-to-end: a real `sphinx-build` against the unfixed source
  drops the table entirely (`ERROR: '|' expected after '"'`, 0
  `<table>` elements in the output XML); against the fixed source, the
  same build succeeds cleanly with the table's real content present.
  Not yet wired into any pipeline — `convert_dev_docs_to_docbook.sh`
  doesn't need it (confirmed: Pandoc already tolerates the malformed
  headers fine, this bug is Sphinx-specific), so it stays a standalone
  tool until an actual Sphinx-based pipeline entry point exists to call
  it from.
- ~~**`translations.sh` has no `development` family support.**~~ —
  **fixed in Phase 3.** Six `devdocs-*` subcommands now exist, with
  their own `current_devdocs_commit()` tracking the separate
  `upstream-phpbb-documentation` checkout's own git history.
- ~~**Existing hand-translated dev-docs content isn't migrated.**~~ —
  **superseded, not fixed.** No migration path was ever designed or
  needed: all 5 languages were translated directly against the new
  pipeline's PO catalogs instead (see "Full translation rollout" below).
  The old pipeline's own file-count drift (`da`/`fr`/`it` have 55
  hand-translated `dev-docs-docbook/<lang>/` files, `de`/`de_x_sie` only
  50) is real but now belongs entirely to the old Pandoc/DocBook
  pipeline's own upkeep — irrelevant to the new pipeline, which has no
  DocBook dependency at all.
- **No round-trip audit equivalent** for this pipeline yet (the DocBook
  side has `translations.sh audit` — see `docs/TODO/todo-po-roundtrip-audit.md`
  and `docs/gettext-workflow-checklist.md`; a Sphinx-side version needs
  designing once there's real per-language content to audit against).

## Full 55-file corpus sweep: clean

Ran the real converter against every `.rst` file in a real upstream
`development/` checkout (after `fix_csv_table_headers.py`, its own
documented prerequisite), each with a synthetic `[XX]`-prefixed
translation — the same discipline both spikes and the fixture test
suite already used, now at full scale instead of 3 representative
files.

**First pass: 0 hard failures, 0 unresolved internal links, but real
element-coverage gaps** the 3 fixtures hadn't happened to exercise —
most significantly RST definition lists (87 occurrences across the
corpus) and field lists, both entirely unhandled; `raw` HTML passthrough
(24, mostly `<br>` line breaks and FontAwesome icon substitutions);
`important`/`caution`/generic `.. admonition::` (Sphinx has more
admonition types than note/warning/tip/seealso); a `.. contents::
:local:` directive's auto-generated mini-TOC; a captioned code block's
wrapper `container`/`caption`; and `:abbr:` roles.

**All fixed and re-verified**: definition/field lists render as real
`<dl>/<dt>/<dd>` HTML (this site's Goldmark config has no
definition-list Markdown extension, but does allow raw HTML through);
`raw[@format='html']` passes through verbatim, any other format is
dropped rather than leaked as literal source text;
`substitution_definition` is suppressed at its own definition site
(confirmed Sphinx already resolves every actual use site inline before
XML output, so nothing is lost); `:abbr:` becomes a real
`<abbr title="...">`; every standard Docutils admonition type
(hint/danger/attention/error added alongside the ones already handled)
and the generic `.. admonition:: Custom Label` form (using its own
`<title>` as the label) are covered; a `.. contents::`-generated topic
is suppressed like toctree navigation; a captioned code block's caption
renders as a bold label line above the fence.

**Second pass, after those fixes: fully clean** — 0 hard failures, 0
unresolved internal links, 0 unsupported elements, across all 55 files.
The one remaining flagged item is a genuine upstream RST authoring bug
in `language/validation.rst` (a mismatched double-backtick/single-backtick
inline-literal marker), independently confirmed by Sphinx's own build
warning on the same line — correctly surfaced as a loud diagnostic, not
a converter gap, and not fixed here (it's a source content issue, not
this tool's job to silently paper over).

All new element handling has permanent regression coverage in
`tests/sphinx_devdocs/test_sphinx_to_hugo.py` (test count 37 → 53).

## Phase 3: translations.sh development-family support

`translations.sh` gained six `devdocs-*` subcommands
(`devdocs-extract`/`init`/`update`/`status`/`check`/`build`), giving the
55-file dev-docs tree the same gettext workflow the `documentation`
family already has, using the Phase 2 converter as the real per-file
worker. PO catalogs mirror the RST tree exactly
(`<lang>/development/<docname>.po`); `current_devdocs_commit()` tracks
`upstream-phpbb-documentation/`'s own git history (a real separate
upstream, unlike `documentation`'s hand-authored-in-this-repo source);
`metadata/source.json`'s `upstream` object is now per-family.
`devdocs-build` writes to `build/devdocs-preview/`, a preview-only
location — it does **not** touch `site/content/<lang>/development/`,
which stays fully owned by the existing Pandoc/DocBook pipeline until a
deliberate future cutover. No `devdocs-audit` yet (nothing real to audit
against). Verified against the full real corpus, not just fixtures: a
complete `devdocs-check fr` run against all 55 real files came back
`Result: COMPLETE`. 27 new regression tests in
`tests/translations_sh/test_devdocs_workflow.py`.

Still explicitly not started at the time Phase 3 landed: any real
language actually being translated through this pipeline (everything
verified through Phase 3 used synthetic `[XX]` translations), and CI.
**Since resolved** — see "Full translation rollout" below.

## Full translation rollout: complete (all 5 languages, 2026-09-16/17)

Rather than migrating the old pipeline's hand-translated DocBook content
(`dev-docs-docbook/<lang>/` in the `phpbbdocs-hugo` repo — a completely
different storage model, and a genuine re-authoring/alignment problem
with no honest automated shortcut), every language was translated
directly against the new pipeline's real PO catalogs in the
`phpbbdocs-languages` repo, file by file, using
`translations.sh devdocs-init <lang>` to create empty catalogs, then
hand-translation swept across all 55 files per language (5498 msgids
each, including the 2690-entry `events_list.po`).

**French, Danish, Italian** were each translated from scratch and merged
(`phpbbdocs-languages` PR #9 for da+it, fr merged earlier the same
session).

**German** used a two-variant approach: `de` (Casual, "du" address) was
translated from scratch the same way; `de_x_sie` (Formal, "Sie" address)
reused `de`'s translations directly for the ~91% of entries that are
impersonal/technical (no second-person address, so casual vs. formal is
identical), and only the ~518 entries with actual direct address were
hand-translated into Sie/Ihnen/Ihr forms. Both merged together as
`phpbbdocs-languages` [PR #10](https://github.com/phpbbmodders/phpbbdocs-languages/pull/10).

All five languages — `fr`, `da`, `it`, `de`, `de_x_sie` — are at
`devdocs-status` 100.0% (5498/5498 translated, 0 fuzzy, 0 untranslated)
and passed `devdocs-check` (`Result: COMPLETE`) as of this rollout. This
fully supersedes the "migrating existing hand-translated dev-docs
content" plan below — no DocBook migration tooling was built or needed.

## Live-site cutover: complete

`devdocs-build <lang> [target_content_dir]` now accepts an optional
target directory (defaulting to the old `build/devdocs-preview/<lang>/development`
preview location for backward compatibility), and the documented build
recipe (`README.md`, `docs/translation-process-prompt.md`) calls it
with the real site path —
`./translations.sh devdocs-build <lang> site/content/<lang>/development`
— for all six languages (`en` plus the five translated languages).
This replaces the old Pandoc/DocBook pipeline
(`phpbbdocs_hugo_devdocs.sh`/`dev-docs-docbook/`) as the documented
dev-docs build path; those old files still exist in the repo but get
no further maintenance (see
[`docs/TODO/todo-old-devdocs-pipeline-cleanup.md`](todo-old-devdocs-pipeline-cleanup.md)
for their eventual removal).

Chapter and page order come from the real upstream `.. toctree::`
structure (`translations/devdocs_toc_order.py`, a new depth-first
toctree parser/resolver), not an alphabetical directory walk — this
matches the old pipeline's own reading order rather than regressing
it. `cmd_devdocs_build` also gained `_index.md` generation
(chapter-level and top-level landing pages, ported from the old
pipeline's `pretty_title()`/heredoc shape) and full regeneration
(`rm -rf` + rebuild) so stale pages from a prior run don't linger.

English is built through the same pipeline as every other language:
`devdocs-init en` creates real PO catalogs with English msgids, and
`msginit`'s own same-language auto-fill behavior sets `msgstr = msgid`
at creation time — confirmed empirically before relying on it. No
English-specific code exists anywhere in the new pipeline.

Verified end-to-end: unit tests
(`tests/translations_sh/test_devdocs_toc_order.py`, new;
`tests/translations_sh/test_devdocs_workflow.py`, extended), a real
6-language build into `site/content/`, a real `hugo` build with
page-count parity confirmed against the old pipeline's output (131/129
pages per language, matching a pre-cutover reference build), and a
live browser check confirming rendering, toctree-derived ordering,
nested-page slugs, title-quoting, the cross-language `translationKey`
switcher, and the `de`/`de_x_sie` casual/formal distinction all work
in the real running site.

## What's still open

- **No `devdocs-audit` / round-trip check yet** for this pipeline (the
  DocBook side has `translations.sh audit`; a Sphinx-side equivalent
  needs designing now that there's real per-language content — all 5
  translated languages plus English — to audit against instead of
  synthetic `[XX]` translations).
- **CI** for the new pipeline still doesn't exist.
- **Old-pipeline file removal** — see
  [`docs/TODO/todo-old-devdocs-pipeline-cleanup.md`](todo-old-devdocs-pipeline-cleanup.md).
