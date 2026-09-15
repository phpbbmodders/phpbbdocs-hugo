# Sphinx dev-docs pipeline: spike results (Phase 0 and 1)

## Status: spikes successful — mechanical path proven, element coverage widened

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

With Phase 0 and 1 both successful, the remaining big-ticket items are
genuinely separate, larger commitments, not more of the same
walking-skeleton work:

- **Build a real, committed transform** (not scratch) covering the full
  element vocabulary proven across Phases 0-1, with the three Phase 1
  problems actually fixed (HTML-escaping, blockquote-continuation,
  toctree-link skipping) rather than just documented.
- **`translations.sh` `development`-family support** — real architecture
  work (source-revision tracking against a separate upstream checkout,
  not this repo's own git history).
- **Migrating existing hand-translated dev-docs content** — a real design
  problem, not an audit; `de`/`de_x_sie` are already at 50 files vs.
  `en`/`da`/`fr`/`it`'s 55, so drift needs reconciling before any
  migration tooling can assume 1:1 file correspondence.

Each is a fresh scoping decision, not a continuation of this spike.
