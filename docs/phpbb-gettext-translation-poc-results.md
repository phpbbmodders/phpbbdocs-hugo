# Gettext translation pipeline: POC results

Results of the two proofs of concept scoped by
[`phpbb-gettext-translation-plan.md`](phpbb-gettext-translation-plan.md)
section 44 ("Immediate Claude Code Task"). Claude ran both POCs and
wrote this report. No production code changed — this is a report, not
an implementation. See that section for the original task definition
and the exact return-format tables it asked for.

All POC artifacts (POT/PO/reconstructed files, logs) live under a
scratch directory and are not part of this repository.

---

## POC 1 — DocBook

Real `content/en/chapters/admin_guide.xml` (2,605 lines, no tables;
`db/dbal.dbk` and `extensions/database_types_list.dbk` used
separately to check table handling) was run through all three
candidates: extract POT → create a 9-entry test PO covering paragraph,
heading, `<guilabel>`, `<acronym>`, `<filename>`, `<link linkend>`,
`<xref linkend>`, list item, and `<note>` content → reconstruct →
`xmllint` → structural comparison. The 9 test strings were identical
across all three engines for a fair comparison.

### Result table

|                    | po4a | poxml | itstool |
|--------------------|------|-------|---------|
| Extraction         | ✅ 7,453 entries | ✅ 8,006 entries | ✅ (comparable) |
| PO quality         | Good — full DocBook element-path context in comments (verbose but precise) | Good — simple `Tag: <name>` comments | Good — `path: parent/child` comments |
| Inline markup      | ✅ preserves markup + attribute values verbatim in msgid | ✅ same | ✅ same |
| **Round trip**      | ✅ **succeeded** | ❌ **failed — see below** | ✅ succeeded |
| IDs/xrefs          | ✅ preserved | — (couldn't test, see below) | ✅ preserved |
| Tables             | ✅ clean, deduped identical cells across repeated tables | ✅ same | ✅ same |
| Code               | not present in `admin_guide.xml`; not separately re-tested | same | same |
| XML validation     | ✅ valid | — | ✅ valid |
| Hugo build         | not run (out of POC scope — reconstructed DocBook, not full site, was the target) | — | — |
| Update handling    | not tested this pass (Phase E, out of scope for POC 1) | — | — |
| Configuration      | Needs `--keep 0` to force output below its 80%-translated default threshold; needs `-o doctype=` for the `.dbk` files that declare a DOCTYPE (a `.dbk` extension attempt produced a non-fatal "Bad document type" warning) | Zero configuration | Zero configuration for basic use; `-l <lang>` needed to tag the root element correctly (see below) |
| Maintenance        | Actively maintained, this project's primary intended use case | Maintained (KDE), general XML/DocBook translation tool but less DocBook-specific tooling around it | Actively maintained (GNOME), used by several real DocBook/Mallard projects |
| Reflow/diff impact | **Rewraps every line** — reconstructed file went from 2,605 to 4,645 lines even though only 9 of ~980 translatable strings were touched | inconclusive (crashed) | **None** — reconstructed file stayed at exactly 2,605 lines; only actually-translated paragraphs differ, *except* see the entity/serialization caveat below |

### The poxml failure (a real, reproducible bug against this project's actual content)

`po2xml` aborted **the entire reconstruction** with `can't find ... in
...` and produced an **empty output file** — not a partial file, not a
warning, total failure — over one single paragraph it had nothing to
do with (it wasn't in the 9-entry test PO at all). Root cause: the
English source itself is inconsistent — most attributes in
`admin_guide.xml` use double quotes, but two paragraphs (lines 2256
and 2313) use `<filename class='directory'>` with single quotes.
`xml2pot` silently normalizes this to double quotes in the POT, but
`po2xml`'s reconstruction re-matches literal text against the
*original* XML and can't find its own normalized text there — so it
gives up on the whole file. This is a real, present-day characteristic
of this project's actual DocBook source, not a contrived edge case,
and it means **poxml is not safe to use unmodified against this
project's chapters** without first auditing and normalizing every
attribute-quoting inconsistency across every chapter — a fragile
precondition for an ongoing translation workflow that other people
will be editing.

### The itstool diff-noise caveat

itstool's round trip succeeded and preserved line count exactly, but
its XML serializer normalizes things globally on *every* run,
regardless of what was actually translated:

- `&quot;` entities anywhere in the file become literal `"` characters
- the XML declaration's `encoding="UTF-8"` becomes lowercase `"utf-8"`
- self-closing tags lose the space before `/>` (`<xref .../>` →
  `<xref.../>`, wait — inverse: `<xref ... />` → `<xref .../>`)
- the root element gets a `lang="…"` attribute — **without** `-l it`
  on the command line this came out as a garbled `lang="admin-GUIDE"`
  (itstool guessing from the file's `id` attribute); with `-l it` it
  correctly reads `lang="it"`

None of this breaks the XML or the translation, but it means **every
single translated file, on every update run, carries a full-document
diff** in a Git PR — including hundreds of lines the translator never
touched — which cuts directly against this project's Git/GitHub
review-centric workflow (plan sections 3 and 36 both lean on small,
reviewable PRs).

### po4a's diff-noise caveat

po4a's failure mode is different but has the same practical effect:
it **reflows every paragraph** to its own wrap width on every run
(2,605 → 4,645 lines for 9 changed strings), so PRs would also show
whole-file diffs, just via line-wrapping rather than entity
normalization. This is standard, well-documented po4a behavior, not a
bug — but it's the same practical problem for a review workflow.

### Recommendation

**po4a**, with reservations. It's the only candidate that both (a)
survived the actual round trip against this project's real,
imperfect source and (b) is designed end-to-end for exactly this
translation-lifecycle use case (fuzzy matching, catalog updates over
time — po4a-updatepo — rather than one-shot extract/merge). Its
reflow-on-every-build behavior needs a mitigation before this is
usable for real Git-reviewed PRs — worth checking whether disabling
po4a's paragraph rewrapping (`--wrap-po` / addendum options, not yet
tested) gets closer to itstool's "only touched lines differ" property
without inheriting itstool's own entity-normalization noise. That
follow-up check belongs in Phase A before a final DocBook engine
decision, not this report.

itstool is the runner-up: technically the more robust round-trip
(genuine DOM-based merge, not text-matching), but the unconditional
serialization normalization is a real cost for a Git-based workflow
and needs the same kind of follow-up investigation (can it be told to
preserve original entity/quote style?) before ruling it in or out.

poxml is not recommended as-is: the demonstrated failure mode
(silent, total reconstruction failure from one pre-existing
inconsistency elsewhere in the file) is disqualifying for unattended
CI use without first cleaning every chapter's attribute-quoting style
— itself nontrivial, ongoing maintenance surface.

---

## POC 2 — Sphinx

Real `upstream-phpbb-documentation/development/` (fetched via this
project's own `pull_upstream_docs.sh`-style sparse checkout, already
present in the working tree) was run through Sphinx's `gettext`
builder, a 7-entry test PO for `auth/authentication.rst` (the same
file this project's Italian translation already covers as
`dev-docs-docbook/it/auth/authentication.dbk`), then the `xml` builder
with `-D language=it`.

### Result table

```text
Gettext extraction:       PASS
PO quality:                PASS — clean prose/heading extraction,
                            inline literals preserved, code blocks
                            correctly excluded by default
Translation application:  PASS — <title>/<paragraph> nodes carry a
                            translated="True"/"False" attribute per
                            node, and the document root carries a
                            translation_progress="{...}" dict with
                            exact translated/total counts — this is a
                            genuinely useful built-in feature for the
                            status reporting the plan wants (section 31)
XML generation:            PASS
References:                PASS — section ids/anchors stay derived
                            from the English source structure even
                            when the title text is translated, so
                            internal :ref:/xref targets don't break
Code/directives:           PASS — PHP literal_block content passes
                            through completely untouched
Tables:                    PASS — 52 real csv-tables across 13 files
                            failed to parse and were silently dropped
                            (found this pass); root-caused to one
                            consistent pattern and fixed with a
                            downstream pre-processing script, verified
                            against the real source (0 errors, table
                            content recovered tree-wide) — see below
Hugo feasibility:          PASS — prose/code/lists/headings/notes/
                            tables all confirmed via a real Phase D
                            transform run against the full corpus
Pandoc replacement:        POSSIBLY — technically demonstrated
                            end-to-end this pass; still needs
                            production hardening (see below), not a
                            content-risk gate anymore
Recommendation:            GO WITH CHANGES
```

### The real conf.py doesn't build as-is

`development/conf.py` names `sensio.sphinx.refinclude`,
`sensio.sphinx.configurationblock`, `sensio.sphinx.phpcode`,
`sensio.sphinx.bestpractice` (from
[fabpot/sphinx-php](https://github.com/fabpot/sphinx-php), Symfony's
documentation tooling — not on PyPI, needs vendoring, and was written
for a much older Sphinx than any currently maintained release),
`sphinxcontrib.phpdomain`, and `sphinx_multiversion` — none of which
are installed by this project's own tooling, since it has never
previously run Sphinx at all (it uses Pandoc on the raw `.rst` files).
Checked whether the actual content needs them:
**none of the Symfony-specific directives/roles are used anywhere in
`development/`'s current `.rst` files** (confirmed by grep), and
`sphinx_multiversion` is only referenced for its `smv_*` config
variables, unused by a single-language gettext/XML build. This POC
built with a **minimal substitute `conf.py`** (same project metadata,
`source_suffix`, `master_doc`; the unused extensions dropped) —
appropriate for a POC, **not** appropriate for production without
first resolving what a real `conf.py` needs (most likely: vendor
`fabpot/sphinx-php` directly and verify it against a current Sphinx,
or confirm with upstream phpBB that those extensions are genuinely
dead weight and can be dropped from the real `conf.py` too).

### `gettext_compact` comparison

- `gettext_compact = True` (Sphinx's default): **11** catalogs, one
  per top-level `development/` subdirectory (`auth.pot`, `cli.pot`,
  `extensions.pot`, …) — `extensions.pot` alone is 18,048 lines.
- `gettext_compact = False`: **55** catalogs, one per `.rst` file —
  this maps exactly onto how this project already organizes its
  DocBook-side translations (`dev-docs-docbook/<lang>/<chapter>/<file>.dbk`,
  file-for-file against the English source), which is also how the
  Italian dev-docs translation done in this repository this session
  was structured and reviewed. **`gettext_compact = False` is the
  better fit for this project's existing conventions and review
  granularity** — worth confirming during Phase B before locking it in,
  but it's the clear leading choice from this pass.

`gettext_uuid` was not tested this pass (it only matters for
update/merge churn over time, which is Phase E scope, not initial
feasibility).

### Smart quotes: a real config decision, not a bug

Docutils' `smartquotes` transform is on by default and silently
converts straight `'`/`"` to typographic `’`/`“ ”` in **both** English
and Italian output — including inside literal inline code descriptions
(`"f_list"` → `“f_list”`). This project's own established convention
(confirmed against `content/it/` and `dev-docs-docbook/it/` this
session) is **straight** apostrophes throughout. `smartquotes = False`
in `conf.py` would need to be set to match; flagging this now so it
isn't discovered as a surprise diff later.

### Csv-tables: not cosmetic warnings — 52 tables silently dropped, across 14 files

Corrected after closer inspection (the original pass under-called
this): of the 54 build messages, **52 are `ERROR`, not `WARNING`**,
and each one means Sphinx **silently drops that table from the build
entirely** — no error in the rendered output, no table either, the
content is just gone. Confirmed against the actual generated XML:
`cli/getting_started.xml` has zero `<table>` elements despite its
source having one. This is present in the **English** source as-is
and would affect any Sphinx build of this content, gettext or not —
not a translation-pipeline bug — but it is a real content-loss risk
for a Sphinx-based Hugo pipeline specifically, since **the current
Pandoc-based pipeline renders every one of these tables successfully**
(confirmed against `dev-docs-docbook/en/cli/getting_started.dbk`,
which has the full table Pandoc produced from the same source line).
Pandoc tolerates whatever docutils' stricter csv-table parser rejects;
Sphinx does not.

All 52 errors share **one single, consistent root cause**, confirmed
by spot-checking multiple files: every affected table sets a custom
`:delim:` (` | ` or `#`) for its data rows, but the `:header:` line
above it keeps the *default* comma-and-quotes CSV syntax
(`:header: "Parameter", "Usage"`) instead of matching the same custom
delimiter — docutils' csv-table parser applies `:delim:` to the whole
directive including the header line, so it fails to parse the header
and aborts the whole table. Affects (error count in parens):
`cli/getting_started.rst` (1), `db/dbal.rst` (15), `request/request.rst`
(9), `extensions/tutorial_notifications.rst` (7),
`extensions/tutorial_basics.rst` (4), `extensions/tutorial_bbcodes.rst`
(4), `extensions/tutorial_advanced.rst` (2), `extensions/new_in_rhea.rst`
(2), `extensions/tutorial_modules.rst` (2), `migrations/dependencies.rst`
(2), `migrations/tools/module.rst` (2), plus one each in
`extensions/modification_to_extension.rst` and
`extensions/tutorial_controllers.rst`.

**Resolved with a downstream fix.** Upstream isn't a realistic path
for this — the maintainers have no reason to touch it, since it
doesn't affect their own Pandoc-based flow. Instead: a small,
idempotent script
(`fix_csv_table_headers.py`, POC-scratch only, not yet in this repo)
finds every `:header: "A", "B"[, ...]` line immediately followed by
its own `:delim: X` line and rewrites the header to use that same
delimiter (`:header: "A"|"B"`, or the `#` equivalent) — this project
would own and run it as a pipeline pre-processing step against its
own local copy of the upstream checkout, the same way
`convert_dev_docs_to_docbook.sh` already owns other downstream
fixups against Pandoc's output today (`<br>` repair, `&nbsp;` repair
— see that script's own header comment).

**Verified against the real source:** ran it against a full copy of
`development/` — **52 headers fixed across the same 13 files** the
survey above found, matching exactly. Rebuilt the Sphinx XML from
that patched copy: **0 `ERROR`s** (down from 52), the 2 unrelated
pre-existing `WARNING`s untouched, and the previously-empty
`cli/getting_started.xml` now has its table back, confirmed rendering
correctly end-to-end through the Phase D transform below
(`| Option | Usage |` and all 9 data rows present). Table content
across the whole tree went from 11 to 61 matches. Re-ran the full
47-file transform pass against the patched build: still 0 errors, 0
empty output.

This is no longer an open blocker — it has a working, verified fix
that only needs to be promoted from POC scratch into this project's
actual pipeline (as its own script, run before Sphinx, alongside the
existing Pandoc-path fixups) if/when the Sphinx path is adopted.

### Sphinx XML is not DocBook (plan section 20, confirmed)

The generated XML is genuine Docutils/Sphinx XML — `<document>`,
`<section>`, `<paragraph>`, `<literal_block language="php">` — not
DocBook 4. `proteus_hugo_devdocs.xsl` cannot be pointed at it as-is.
Building the dedicated Sphinx-XML→Hugo transformation this would
require (plan section 24, Phase D) was **not** attempted in this
pass — it's a separate, nontrivial POC of its own.

### Recommendation

**GO WITH CHANGES.** Sphinx's native gettext/XML pipeline works
cleanly against this project's real developer-docs content once the
Symfony-extension gap is resolved, and it comes with translation-
progress tracking and reference stability essentially for free. The
open item that actually gates a "GO" is Phase D (Sphinx XML → Hugo),
which this report did not attempt — until a real transformation from
Sphinx XML to Hugo Markdown exists and has been compared against the
current Pandoc→DocBook→Hugo output, "Pandoc replacement" stays
**POSSIBLY**, not **YES**.

---

## Follow-up 1 — po4a reflow: not a quick flag

Checked whether po4a's whole-document reflow (see POC 1) can be
turned off with a documented option before treating it as a real
factor in the DocBook recommendation. `--wrap-po` controls the *PO
file's* wrapping, not the reconstructed XML's — irrelevant here.
`-w`/`--width` and `-o wrap=no` on `po4a-translate` had **zero
effect** on the reconstructed XML in a direct test (same 4,645 lines,
same ~80-column reflow either way). Per `Locale::Po4a::Xml`'s own
documentation, the DocBook module pre-sets tags like `<para>` to wrap
(`w`) internally, and the *global* `wrap` toggle doesn't override a
tag's own preset — turning it off requires per-tag overrides via
`-o translated="W<para>..."`-style hierarchy strings for every
wrapped element, which is real configuration work, not a one-flag
fix. This doesn't change the POC 1 recommendation, but it does mean
**taming po4a's diff noise is nontrivial** and belongs as an explicit
task in Phase A's implementation, not a quick pre-check.

## Follow-up 2 — Phase D: Sphinx XML → Hugo (done this pass)

Built the smallest practical transform
(`poc_sphinx_hugo.xsl` — front matter from the root section's title,
heading levels from `ancestor::section` count, code blocks, inline
literal/strong/emphasis, bullet lists, internal vs external
references; the auto-generated local `.. contents::` block dropped to
match pandoc's existing behavior for the same file) and ran it against
the real, un-modified `auth/authentication.rst`, then diffed the
result against **`site/content/en/development/auth/authentication/index.md`**
— this repository's actual, currently-published output for the exact
same source file.

Result: **semantically equivalent, and better in two ways, with two
concrete gaps** —

- **Better:** code fences now carry the right language
  (` ```php ` / ` ```default `) — the current Pandoc path can't do
  this at all (see `proteus_hugo_devdocs.xsl`'s own comment on this).
- **Better:** no stray leading/trailing space inside every paragraph
  — a visible, longstanding artifact of the current pandoc→DocBook
  path (`" This is an explanation... "`, with a leading and trailing
  space, in the *current live page*) that Sphinx XML's text nodes
  don't produce.
- **Gap:** the current output emits an `<a id="...">` anchor before
  every heading for stable deep-linking; the POC transform doesn't
  yet (trivial to add — the id is already on Sphinx's `<section>` as
  `ids="…"`).
- **Gap:** `translationKey` front matter isn't wired through yet
  (mechanical — the driver script already computes this string
  per-file today; needs threading into the new transform the same
  way).
- **Heads up, not a blocker:** anchor slugs would change shape
  slightly — current pipeline emits e.g. `#i.-acl-getf`, Sphinx's own
  ids are dash-only (`#i-acl-getf`, no literal dot). Any existing
  external deep-links into dev-docs pages using the old anchor format
  would 404 after a cutover.
- One list-spacing cosmetic difference (extra blank line between
  `<li>`s) — valid GFM either way, renders fine.

**Update: `note` and `table` templates added and verified.** Both
element types now have templates (note → the same `> **Note:**`
blockquote convention `proteus_markdown.xsl` already uses; table →
GFM table, handling both the headered case and the headerless case —
`extensions/tutorial_templates.rst` has one of each — matching
`proteus_hugo_devdocs.xsl`'s existing `informaltable|table`
convention). Verified against real content:
`extensions/tutorial_templates.rst`'s two tables and
`files/upload.rst`'s two notes both render correctly, including a
`twig`-labeled code fence as a third free language-labeling win.

**Full-tree robustness pass:** ran the updated transform against
every one of the 47 generated Sphinx XML files (the whole
`development/` tree except its own `index.xml`) — **zero XSLT
errors, zero suspiciously-empty output**, 748K of Markdown produced.
This doesn't mean every page is *correct* (that needs eyes-on review,
not just "didn't crash"), but it rules out any element type in the
real corpus causing an outright transform failure.

Given this, the core question this phase set out to answer — can
Sphinx XML drive Hugo generation for prose/code/lists/headings/
notes/tables content, which is the overwhelming majority of this
docs set — has a clear, evidenced **yes**. The one real content-risk
left standing is the csv-table parse-error issue below, which is a
**source-content problem, not a transform problem**: no XSLT template
can render a table whose data never reached the XML in the first
place.

## Follow-up 3 — itstool reconstruction can silently fall back to English for specific paragraphs, even with a correct PO catalog

Discovered while migrating the Danish (`da`) translation's existing
hand-authored `content/da/chapters/*.xml` into PO catalogs via
`translations/align_existing_translation.py`, then verifying the
result by reconstructing (`msgfmt` → `itstool -m`) and diffing every
`<para>` against the authoritative hand-translated file.

**What happened:** `admin_guide.xml`'s `acp_posting_bbcodes` section —
one `<title>` plus six `<para>` elements, all beginning with or
containing `<glossterm>BBCode(s)</glossterm>` — reconstructs as raw,
untranslated English, even though the compiled `.mo` file demonstrably
contains the correct Danish `msgstr` for the exact `msgid` text
(verified directly against the `.mo` with `polib`, bypassing itstool
entirely). Everywhere else in the same 924-entry catalog, including
other `<glossterm>`-wrapped paragraphs elsewhere in the same file
(IP address, Attachments, etc.), reconstruction is correct.

**What this isn't:** not a bad translation, not a bad alignment, not a
duplicate-msgid collision (`msgfmt --check` passes clean), and not
something specific to this project's XML — the six paragraphs have
the same tab-indented structure as every surrounding, correctly-
reconstructing paragraph. It looks like `itstool -m`'s own re-parse of
the live English source (a separate pass from the `-o` extraction that
built the POT) is, in this one isolated spot, computing a different
extraction key than the one stored in the compiled catalog — narrow
enough that no root cause was found within the time this deserved.

**Practical impact:** none on the live site today. Hugo builds from
the hand-maintained `content/<lang>/chapters/*.xml` files directly;
`translations.sh build <lang>` (PO → reconstructed XML) is a
maintainer tool for a *future* gettext-driven workflow, not the
current pipeline. Running it today would silently regress exactly
these six paragraphs back to English — a real trap for whoever
eventually flips that switch, worth knowing about in advance rather
than discovering via a diff nobody thought to run.

**How this was caught:** title-only diffing (`<title>` tags) is not
enough — it missed this entirely, since only `<para>` content is
affected here. The reconstruction-vs-authoritative comparison needs to
walk every translatable node, not just titles, to catch a gap this
narrow.

## What this report does not answer

Per the plan's own scope: no production code changed, no
`translations.sh` was written, no architecture decision locked in.
What's left before Phase A/B/D can be called fully "done":

1. Per-tag po4a wrap overrides, tested for real (or: drop po4a in
   favor of itstool and solve *its* diff-noise problem instead —
   still an open call, not made here).
2. A real, production-appropriate `development/conf.py` — resolve
   what to do about the Symfony extensions phpBB's own config
   declares but current content doesn't exercise.
3. Promote `fix_csv_table_headers.py` from POC scratch into this
   project's actual pipeline (its own script, run before Sphinx,
   alongside `convert_dev_docs_to_docbook.sh`'s existing
   Pandoc-output fixups) — the fix itself is done and verified;
   what's left is wiring it in for real, only worth doing once/if
   Sphinx is the adopted path.
4. Eyes-on review of the 47-file full-tree transform output beyond
   "it didn't crash" — `note`/`table`/code/list/heading templates are
   now in place and spot-verified on a few files, but a real
   correctness pass across the whole `development/` tree hasn't been
   done.
