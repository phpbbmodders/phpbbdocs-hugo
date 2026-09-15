# phpBB Documentation Gettext Translation Pipeline Plan

## 1. Objective

Build a Git-first gettext translation architecture for the phpBB 3.3 documentation maintained by `phpbbdocs-hugo`.

The project has two fundamentally different upstream documentation sources:

1. **User/admin documentation:** DocBook 4 XML.
2. **Developer documentation:** Sphinx/reStructuredText.

Both should expose standard gettext PO files to translators, while retaining the native upstream formats and using Hugo as the final publishing system.

The target architecture is:

```text
                         TRANSLATORS
                             ↕
                             PO
                    ┌────────┴────────┐
                    │                 │
               DocBook 4           Sphinx/RST
                    │                 │
                    ↓                 ↓
             localized XML     localized Sphinx XML
                    │                 │
                    └────────┬────────┘
                             ↓
                            Hugo
```

The official `phpbb/documentation` repository is upstream and **READ ONLY**.

Do not modify upstream.

---

# 2. Design Principles

The translation system should follow these rules:

- English upstream sources remain canonical source content.
- PO files become canonical translation data in the sibling repository `phpbbdocs-languages`.
- POT files are generated artifacts, consumed indirectly when the helper creates or updates PO catalogs.
- Keep publishing tools in `phpbbdocs-hugo` and translation content in `phpbbdocs-languages`.
- Translators work primarily with PO, not DocBook, RST, XSLT or generated Markdown.
- Generated translated XML/DocBook/Hugo content is build output.
- Git and GitHub are the primary contribution and review system.
- Web-based translation software is optional future infrastructure.
- Use native/mature gettext tooling instead of writing custom parsers.
- Preserve the existing Hugo publishing model.
- Do not force the two upstream formats through the same parser simply to make the architecture look uniform.
- Prefer deterministic, reproducible generation over checked-in generated translation trees.

---

# 3. Expected Translators

Most likely contributors are:

- international phpBB support-site team members;
- phpBB extension authors;
- existing phpBB contributors;
- technically experienced translators.

Most are expected to already understand Git and GitHub.

Therefore, Git should be the official translation workflow.

Do not make Weblate or another translation server a dependency.

A web translation platform can be added later because standard PO files remain compatible with such systems.

---

# 4. Translator-Facing Architecture

The translator should see:

```text
English changed
      ↓
./translations.sh update <lang>
      ↓
PO updated (POT generated internally)
      ↓
Translator edits PO
      ↓
Validation
      ↓
Git commit / PR
      ↓
CI
      ↓
Generated translated documentation
```

The translator should not normally need to know about:

- DocBook;
- XInclude;
- Sphinx internals;
- XSLT;
- Pandoc;
- Docutils XML;
- Hugo front matter;
- generated build trees.

---

# 5. Proposed Translation Repository Structure

Conceptually:

```text
phpbbdocs-languages/
├── README.md
├── LICENSE
├── metadata/
│   └── source.json
├── terminology/
│   ├── phpbb.csv
│   └── README.md
├── fr/
│   ├── language.toml
│   ├── documentation/
│   │   ├── quick_start_guide.po
│   │   ├── upgrade_guide.po
│   │   ├── admin_guide.po
│   │   ├── moderator_guide.po
│   │   ├── user_guide.po
│   │   ├── server_guide.po
│   │   └── glossary.po
│   │
│   └── development/
│       └── <Sphinx-generated catalogs>
│
├── de/
├── it/
└── ...
```

Do not finalize the developer catalog layout until actual Sphinx gettext output has been examined.

Prefer Sphinx's natural catalog organization rather than creating unnecessary custom mapping.

## Repository responsibilities and checkout configuration

`phpbbdocs-hugo` owns upstream synchronization, extraction, POT generation, PO update orchestration, reconstruction, Sphinx localization, XSLT/conversion, Hugo builds, preview tooling and integration validation. `phpbbdocs-languages` owns canonical PO catalogs, language metadata, source-revision metadata, terminology, translator documentation and translation-specific QA configuration. Carry the applicable documentation license and attribution into the languages repository.

Use sibling checkouts without requiring Git submodules:

```text
repos/
├── phpbbdocs-hugo/
│   ├── translations.sh
│   ├── translation.conf
│   └── build/gettext/       # generated POT, ignored by Git
└── phpbbdocs-languages/
    ├── metadata/source.json
    ├── terminology/
    └── fr/
```

Configure the path once in `translation.conf` or an appropriate existing project configuration file:

```bash
LANGUAGES_REPO=../phpbbdocs-languages
```

Resolve the configured relative path against the tooling repository, consistently across commands. Allow an environment override for CI and other checkout layouts:

```bash
LANGUAGES_REPO=/tmp/phpbbdocs-languages ./translations.sh build fr
```

Ordinary commands read the configuration automatically, including `./translations.sh build fr`. Translators should not need a repeated repository-path argument.

## Per-language metadata

Each language has a minimal file such as `fr/language.toml`:

```toml
code = "fr"
name = "French"
native_name = "Français"
locale = "fr_FR"
status = "active"
```

Allow `active`, `experimental` and `inactive` status values. Optional fields include `maintainers = []` and `screenshot_locale = "fr"`. Avoid duplicating data reliably available in PO headers. Validate metadata and locale conventions during initialization and checks.

---

# 6. User Documentation Source

Official user documentation is native DocBook 4.

The upstream book consists of seven major components:

```text
quick_start_guide.xml
upgrade_guide.xml
admin_guide.xml
moderator_guide.xml
user_guide.xml
server_guide.xml
glossary.xml
```

These provide natural translation boundaries.

The desired translation architecture is:

```text
English DocBook 4
       ↓
gettext extraction
       ↓
      POT
       ↓
       PO
       ↓
translation merge
       ↓
Translated DocBook 4
       ↓
existing XSLT
       ↓
Hugo
```

---

# 7. DocBook Translation Engine Candidates

Do not select an engine merely because it successfully generates POT.

Compare three mature candidates against the actual phpBB DocBook.

## Candidate A — po4a

`po4a` is the leading candidate for the complete translation lifecycle.

Its advantage is that it is designed specifically for maintaining documentation translations through PO catalogs over time.

Evaluate:

- DocBook extraction;
- PO management;
- source updates;
- fuzzy matching;
- translated document reconstruction;
- multiple-document management;
- configuration complexity.

## Candidate B — poxml

Test KDE `poxml`.

Important commands:

```text
xml2pot
po2xml
```

Extraction:

```bash
xml2pot admin_guide.xml > admin_guide.pot
```

Reconstruction:

```bash
po2xml admin_guide.xml admin_guide.po > admin_guide_fr.xml
```

Validation:

```bash
xmllint --noout --nonet admin_guide_fr.xml
```

`po2xml` consumes:

```text
original English XML
        +
translated PO
        ↓
translated XML
```

The POT itself is not supplied to `po2xml`.

## Candidate C — itstool

Test `itstool` as an ITS/XML-based gettext solution.

It deserves a real comparison because it is used by existing documentation projects for DocBook/gettext translation workflows.

---

# 8. DocBook Proof of Concept

Use the actual phpBB `admin_guide.xml`.

Test all three engines using the same source and equivalent test translations.

The pipeline for each must reach:

```text
admin_guide.xml
      ↓
POT
      ↓
test PO
      ↓
translated XML
      ↓
xmllint
      ↓
existing phpBB XSLT
      ↓
Hugo
```

Do not modify production scripts during this experiment.

---

# 9. DocBook Test Coverage

Translate representative strings containing:

- normal paragraphs;
- headings;
- `<guilabel>`;
- `<acronym>`;
- links;
- xrefs;
- lists;
- notes;
- warnings;
- commands;
- literal/code content;
- filenames;
- images;
- tables;
- inline formatting;
- entities where present.

The test must not consist solely of simple paragraphs.

---

# 10. DocBook Structural Validation

Translation must preserve:

- XML IDs;
- element hierarchy;
- `linkend`;
- xref targets;
- XInclude structure;
- image paths;
- required attributes;
- code structure;
- URLs unless intentionally localized;
- non-translatable metadata.

Run:

```bash
xmllint --noout --nonet translated.xml
```

Where practical, also validate against the appropriate local DocBook 4 DTD/catalog.

Then run the translated document through the existing XSLT/Hugo build.

Producing well-formed XML alone is not sufficient.

---

# 11. Inspect Extraction Quality

Compare POT output from:

```text
po4a
poxml
itstool
```

Evaluate what the translator actually sees.

Good translation units should resemble:

```text
Click on the <guilabel>Administration Control Panel</guilabel>
link to visit the <acronym>ACP</acronym>.
```

The translator should have enough inline context to translate correctly without being exposed to unnecessary XML structure.

Pay particular attention to extraction of metadata such as:

```text
$Id$
copyright years
author names
organization names
revision metadata
```

Classify extracted content as:

```text
TRANSLATE
OPTIONAL
DO NOT TRANSLATE
```

Avoid brittle post-processing unless it is genuinely required.

## Source references and translator comments

Preserve useful gettext source references in PO catalogs, including source paths and line numbers where supported:

```po
#: documentation/content/en/admin_guide.xml:123
#: development/extensions/index.rst:45
```

These are illustrative references; generated references must point to the actual source revision used for extraction. Do not strip them merely to reduce file size.

Preserve translator-authored comments through updates. Add extracted context comments where terms such as board/forum, topic/post, rank/role, group/permission, style/theme or extension/module are ambiguous. Explain the meaning without prescribing grammar. Keep any project-owned context annotations outside the read-only upstream tree and test their association with messages during updates.

---

# 12. DocBook Engine Decision

Score each candidate on:

```text
Extraction quality
Inline markup readability
DocBook 4 compatibility
Round-trip fidelity
ID/xref preservation
Table handling
Code handling
Image handling
Update behavior
Fuzzy matching
Configuration complexity
Git friendliness
Maintenance activity
Custom scripting required
```

Select the tool based on actual phpBB results.

Current candidates:

```text
1. po4a
2. poxml
3. itstool
```

Do not choose based solely on theoretical capabilities.

---

# 13. Translate Toolkit

Evaluate upstream Translate Toolkit:

```text
https://github.com/translate/translate
```

Do not initially treat it as another competing DocBook engine.

Instead evaluate it as the PO QA, analysis and terminology layer.

Potentially useful tools include:

```text
pofilter
poconflicts
pomerge
pogrep
pocount
posegment
poterminology
```

Possible architecture:

```text
DocBook translation engine
           ↓
          PO
           │
           ├── pofilter
           ├── poconflicts
           ├── pocount
           └── poterminology
                  ↑
          Translate Toolkit
```

Prefer mature existing QA tools over implementing equivalent checks ourselves.

---

# 14. Developer Documentation Source

Developer documentation is Sphinx/reStructuredText.

Do not treat it as native DocBook.

The current project uses:

```text
RST
 ↓
Pandoc
 ↓
DocBook 4
 ↓
XSLT
 ↓
Hugo
```

The translation project creates an opportunity to simplify this.

---

# 15. Sphinx Native Gettext

Use Sphinx's native gettext builder for developer translation extraction.

Conceptually:

```text
RST
 ↓
Sphinx gettext
 ↓
POT
 ↓
PO
```

Typical extraction:

```bash
sphinx-build -b gettext development/ build/gettext/
```

Verify the exact invocation against the actual phpBB Sphinx configuration before putting it into production tooling.

Do not write a custom RST parser.

Do not use Pandoc merely to extract translatable strings.

## Deliberate catalog-layout testing

Test `gettext_compact = False` first, then compare it with default compact grouping and any project-specific domain arrangement. Inspect real phpBB output before choosing a layout. Compare catalog size, source context, file count and churn when pages move; avoid both oversized catalogs and unnecessary fragmentation.

## Sphinx UUID proof of concept

Compare extraction and update runs with `gettext_uuid` enabled and disabled. Test edited paragraphs, moved text, reorganized sections, renamed documents and headings moved between files. Measure retained translations, fuzzy matches, newly untranslated messages, catalog churn and runtime.

Test both warm-cache and clean-checkout runs, and record any dependence on persisted Sphinx state. UUID support is a POC candidate, not a guarantee of translation retention. Adopt it only if the measured benefit and reproducibility justify it.

## Conservative gettext targets

Inspect `gettext_additional_targets` against the actual phpBB Sphinx configuration during the POC. Prose, headings and useful captions should be translatable. Code blocks, commands and literal data should normally remain unchanged. Do not globally expose literal/code blocks merely because Sphinx supports additional targets. Expand targets only for demonstrated missing translatable content, and verify that technical examples survive localization.

---

# 16. Updating Developer PO Catalogs

Investigate `sphinx-intl` for standard catalog management.

Conceptually:

```bash
sphinx-intl update \
    -p build/gettext \
    -l fr
```

The resulting structure is normally similar to:

```text
locale/
└── fr/
    └── LC_MESSAGES/
        ├── auth.po
        ├── cli.po
        ├── extensions.po
        └── ...
```

Determine whether retaining this conventional Sphinx structure directly is preferable to relocating catalogs into a custom translation tree.

Prefer convention when there is no compelling reason otherwise.

The canonical developer PO files must still live in `phpbbdocs-languages`. Resolve the final catalog-domain and `locale_dirs` mapping during the POC. If Sphinx requires a conventional locale tree for builds, stage a generated copy and compiled MO files under the tooling build directory rather than maintaining a second editable PO tree. The illustrative command above needs that project-specific path configuration before production use.

---

# 17. Do Not Generate Translated RST

Do not design:

```text
PO
 ↓
translated .rst
 ↓
Pandoc
```

unless native Sphinx localization proves unusable.

Sphinx's normal model is:

```text
English RST
    +
translated PO
    ↓
localized Sphinx doctree
    ↓
builder
```

This is desirable.

The English RST remains canonical and PO remains the canonical translation.

---

# 18. Sphinx XML Builder

Investigate using Sphinx's built-in XML builder as the bridge from localized Sphinx content to Hugo.

Target:

```text
English RST
    +
French PO
    ↓
Sphinx
    ↓
localized doctree
    ↓
Sphinx XML builder
    ↓
French Docutils/Sphinx XML
```

Example concept:

```bash
sphinx-build \
    -b xml \
    -D language=fr \
    development/ \
    build/xml/fr/
```

Verify exact configuration against phpBB.

The resulting XML should already contain localized text because localization occurs during Sphinx processing.

---

# 19. Developer Documentation Target Architecture

If the POC succeeds, prefer:

```text
                       ┌── gettext builder → POT ↔ PO
                       │
English RST → Sphinx ──┤
                       │
                       └── XML builder
                              ↑
                         selected language
                              ↓
                       localized XML
                              ↓
                    Sphinx-XML→Hugo XSLT
                              ↓
                            Hugo
```

This would eliminate the need to generate translated RST.

It may also eliminate Pandoc entirely from the developer-documentation production path.

---

# 20. Sphinx XML Is Not DocBook

This distinction is important.

Sphinx's XML builder emits Docutils/Sphinx XML.

It is not DocBook 4.

Therefore:

```text
proteus_hugo_devdocs.xsl
```

cannot simply be assumed to work against Sphinx XML.

Create a dedicated transformation if the POC succeeds:

```text
Sphinx XML
    ↓
new developer-doc XSLT/converter
    ↓
Hugo Markdown
```

Do not force Sphinx XML into DocBook merely to preserve the current XSLT if doing so adds unnecessary complexity.

---

# 21. Potential Pandoc Removal

If Sphinx XML provides everything required by the Hugo site, investigate retiring Pandoc from the developer-documentation path.

This would remove current concerns involving:

- external Pandoc binary download;
- pinned Pandoc version;
- architecture-specific binary;
- checksum handling;
- `<br>` repair;
- `&nbsp;` repair;
- Pandoc RST interpretation;
- generated English DocBook tree;
- generated translated DocBook trees;
- stale generated `.dbk` files.

Do not remove Pandoc until output equivalence has been demonstrated.

---

# 22. Sphinx Translation POC

Use several representative real phpBB developer RST pages.

Select pages containing:

- headings;
- ordinary paragraphs;
- Sphinx roles;
- cross-references;
- internal links;
- external links;
- code blocks;
- literal blocks;
- lists;
- tables;
- directives;
- nested sections.

Run:

```text
RST
 ↓
Sphinx gettext
 ↓
POT
 ↓
small test PO
 ↓
Sphinx localized XML build
 ↓
inspect XML
```

Verify that translated strings appear in the generated XML.

---

# 23. Sphinx Structural Tests

Verify preservation of:

- reference targets;
- links;
- Sphinx roles;
- code;
- directives;
- section hierarchy;
- IDs;
- navigation relationships;
- tables;
- literal blocks.

Translation must not silently damage Sphinx semantics.

Capture all Sphinx warnings.

Do not suppress warnings during the POC.

---

# 24. Sphinx XML → Hugo POC

Before replacing the existing developer pipeline, transform a small set of generated Sphinx XML files into Hugo-compatible Markdown.

Compare against the current output generated through:

```text
RST
 ↓
Pandoc
 ↓
DocBook
 ↓
proteus_hugo_devdocs.xsl
 ↓
Hugo
```

Compare:

- page titles;
- section hierarchy;
- links;
- code formatting;
- tables;
- navigation;
- IDs/anchors;
- generated URLs;
- Hugo front matter;
- translation keys.

The new output does not have to be byte-for-byte identical.

It must be semantically equivalent or better.

---

# 25. Root Sphinx index.rst

Do not automatically create a rendered page from the current root `index.dbk` simply because it exists.

The existing Hugo developer build intentionally generates its Development landing page from top-level documentation sections.

However, the native Sphinx path gives us an opportunity to inspect the original:

```text
index.rst
```

and its `toctree`.

Investigate whether Sphinx navigation metadata can provide better Hugo ordering.

Do not change navigation behavior until this is understood.

---

# 26. Unified Translation Architecture

If both POCs succeed, the final architecture becomes:

```text
USER / ADMIN DOCUMENTATION
==========================

Official DocBook 4
        │
        ├── gettext extraction
        │
        ↓
       POT
        ↕
       PO
        │
        ↓
selected DocBook translation engine
        │
        ↓
translated DocBook 4
        │
        ↓
existing proteus_hugo.xsl
        │
        ↓
       Hugo


DEVELOPER DOCUMENTATION
=======================

Official RST
        │
        ├── Sphinx gettext
        │        ↓
        │       POT
        │        ↕
        │       PO
        │
        ↓
localized Sphinx doctree
        │
        ↓
Sphinx XML builder
        │
        ↓
localized Sphinx XML
        │
        ↓
developer XML→Hugo transformation
        │
        ↓
       Hugo
```

The formats differ internally.

The translator-facing format is the same:

```text
PO
```

That is the useful form of unification.

---

# 27. Canonical Data

If both pipelines prove reliable:

```text
Canonical source:
    upstream English DocBook/RST

Canonical translations:
    PO in phpbbdocs-languages

Generated:
    POT
    translated DocBook
    Sphinx XML
    Hugo Markdown
    Hugo public site
```

Do not maintain generated translated XML/DocBook as independently editable translations.

POT catalogs belong in the ignored `phpbbdocs-hugo/build/gettext/` tree. Do not normally commit POT files to `phpbbdocs-languages`; translators consume their contents indirectly through `./translations.sh update <lang>` and `./translations.sh init <lang>`. Generated MO files, localized XML, Markdown and site output are also build artifacts.

---

# 28. English Source Updates

The translation system must preserve work when upstream changes.

Expected gettext behavior:

```text
unchanged English
    → retain translation

changed English
    → retain candidate as fuzzy where possible

new English
    → untranslated

removed English
    → obsolete
```

Do not silently discard fuzzy or obsolete translations.

Preserve previous msgids (`#|` history) when merging changed messages, along with fuzzy flags, obsolete entries and translator comments. Test the selected wrappers' merge behavior rather than assuming they retain this context. Do not clear fuzzy status automatically or prune obsolete entries as routine cleanup. Keep removed catalogs recoverable when upstream files disappear.

## Automated catalog refresh and source metadata

`./translations.sh update fr` should:

1. Resolve and validate `LANGUAGES_REPO`.
2. Synchronize/read the intended upstream English branch and resolve its exact commit.
3. Generate fresh DocBook and Sphinx POT catalogs internally.
4. Merge those templates into the French PO catalogs while retaining translator history.
5. Automatically record the source revision for the catalogs successfully refreshed.
6. Report affected paths, catalog changes and message-count changes.

Store generated source metadata in `phpbbdocs-languages/metadata/source.json`. Record repository, branch and full resolved commit, with per-language and per-source-family tracking so updating French does not mark German as current. A conceptual shape is:

```json
{
  "upstream": {
    "repository": "phpbb/documentation",
    "branch": "3.3.x"
  },
  "languages": {
    "fr": {
      "documentation": {"commit": "<full resolved commit>"},
      "development": {"commit": "<full resolved commit>"}
    }
  }
}
```

Translators should never need to edit source-revision metadata manually. Do not advance a catalog's recorded revision when its update fails. Record separate revisions if the two source families differ. Avoid timestamp-only churn on no-op updates.

Status and CI compare the recorded revisions with the resolved current upstream revision and report changed source files for each family. Distinguish source changes that affect catalogs from unrelated upstream commits. If upstream cannot be checked, report freshness as unknown rather than current.

The update report must clearly identify writes to the sibling repository. For example:

```text
Updating French catalogs in ../phpbbdocs-languages/fr
Upstream: phpbb/documentation 3.3.x
Source: abc123 -> def456

User documentation
admin_guide.po       updated
user_guide.po        unchanged

Developer documentation
extensions.po        updated
request.po           unchanged

New messages:        14
Changed/fuzzy:        6
Removed/obsolete:     3
Retained translations and changed catalog paths: reported per catalog
Source metadata updated: ../phpbbdocs-languages/metadata/source.json
```

The hashes and counts above are illustrative. Report actual before/after counts, including retained translations, and list created or retired catalogs. Updating catalogs must not silently commit or push either repository.

---

# 29. Update Testing

For both DocBook and Sphinx pipelines, simulate:

1. paragraph edited;
2. paragraph moved;
3. paragraph added;
4. paragraph removed;
5. heading changed;
6. section moved;
7. file renamed;
8. file added;
9. file removed;
10. punctuation changed;
11. inline markup changed;
12. reference changed.

Regenerate catalogs and measure translator churn.

Prefer standard gettext merging behavior.

Include previous-msgid retention, translator comments, obsolete catalogs, source-reference accuracy and per-language revision metadata in these tests. Compare UUID and compact-domain choices using the same source changes. Repeat an update without source changes to check for unnecessary diffs.

---

# 30. phpBB Terminology

Existing official phpBB translations should be used as terminology references.

Prefer established translations for:

- ACP;
- MCP;
- UCP;
- permissions;
- groups;
- users;
- forums;
- posts;
- topics;
- interface labels;
- administration terminology;
- moderation terminology;
- phpBB-specific features.

Do not blindly overwrite translator choices.

Provide terminology as context/reference.

Investigate using existing phpBB language packs plus Translate Toolkit's terminology tooling to generate useful translator resources.

Maintain translator resources under `phpbbdocs-languages/terminology/`, initially `phpbb.csv` and a `README.md` explaining provenance, language coverage and usage. TBX can be evaluated later if needed. Include reviewed translator decisions and links or references to the relevant official language-pack versions. Use `poterminology` to help discover recurring terms and `poconflicts` to flag inconsistent translations for review; never automatically replace translator wording.

---

# 31. Translation Status

Provide:

```bash
./translations.sh status fr
```

Example:

```text
French Translation Status
=========================

User Documentation
------------------
Translated:      1842
Fuzzy:             21
Untranslated:      37
Completion:      96.9%

Developer Documentation
-----------------------
Translated:      2103
Fuzzy:             14
Untranslated:      94
Completion:      95.1%
```

Also identify catalogs needing work.

Report obsolete entries separately from active translated/fuzzy/untranslated counts. Show failing QA checks, recorded and current source revisions, source drift, changed upstream catalogs/files and the catalogs needing attention. Separate user and developer documentation totals, and state that completion excludes obsolete entries and counts fuzzy entries as needing review. Include actionable next steps such as updating catalogs or reviewing a specific fuzzy entry.

---

# 32. Translation Validation

Provide:

```bash
./translations.sh check fr
```

Use existing gettext/Translate Toolkit tools where possible rather than reimplementing everything.

Validate:

- PO syntax;
- fuzzy entries;
- untranslated entries;
- placeholder consistency;
- inline markup;
- conflicts;
- reconstructed DocBook;
- XML well-formedness;
- Sphinx localized build;
- Sphinx warnings;
- broken references;
- Hugo generation.

Use:

```text
ERROR
WARNING
INFO
```

Incomplete translations should normally generate warnings/status rather than fail the build.

Structural corruption should fail.

Use Translate Toolkit `pofilter` for applicable placeholder, escaping, markup and language checks; use `poconflicts` and `pocount` for consistency and reporting. Choose and document the QA filters after testing real catalogs. Structural errors fail CI; capitalization, punctuation and terminology preferences generally produce review warnings. Preserve legitimate language-specific differences and report the catalog/message for each finding. A fuzzy or untranslated entry is not itself a structural error.

---

# 33. Screenshots

Screenshots are not gettext strings.

Track localized screenshots separately.

Example:

```text
French

Text translation:       98%
Translation review:     94%
Localized screenshots:  7/12
```

Missing localized screenshots should fall back to English where appropriate.

Do not block textual translation because screenshots are incomplete.

---

# 34. English Fallback

Missing translations should fall back to English wherever the selected gettext/build tooling supports that naturally.

Do not maintain duplicate English fallback files unnecessarily.

Determine the native fallback behavior separately for:

```text
DocBook translation engine
Sphinx gettext
```

Use custom fallback copying only where native gettext fallback is insufficient.

---

# 35. Translation CLI

After the architecture is proven, provide a simple contributor/maintainer interface.

Target:

```bash
./translations.sh extract

./translations.sh update fr
./translations.sh update-all

./translations.sh status fr
./translations.sh status-all

./translations.sh check fr
./translations.sh check-all

./translations.sh build fr
./translations.sh build-all
```

Also provide:

```bash
./translations.sh init fr
./translations.sh context fr admin_guide "Manage users"
```

`init <lang>` validates the language code, creates its directory and `language.toml`, generates current templates, initializes PO catalogs with appropriate gettext headers, records source metadata, runs initial validation and reports created files. It must not overwrite an existing language's work.

`context <lang> <catalog> <text>` locates matching source messages and displays their source references, nearby English text and relevant translator comments. Show multiple matches when ambiguous. Resolve context against the catalog's recorded source revision and identify stale references instead of silently displaying unrelated current text.

`extract` is a maintainer command; normal translators obtain fresh templates through `init` or `update`. `build fr` reads the configured sibling repository and handles reconstruction, Sphinx localization and Hugo generation. Keep catalog mutation explicit in `init`/`update`; a preview build should not silently rewrite canonical PO files or their revision metadata.

Do not add commands without a real use case.

---

# 36. Git Contributor Workflow

Expected workflow:

```bash
# Run from phpbbdocs-hugo with the sibling path configured once.
git pull --ff-only
git -C ../phpbbdocs-languages pull --ff-only
git -C ../phpbbdocs-languages checkout -b translation/fr-update

./translations.sh update fr
./translations.sh status fr

# Edit ../phpbbdocs-languages/fr/**/*.po

./translations.sh check fr

# Optional preview
./translations.sh build fr

git -C ../phpbbdocs-languages diff
git -C ../phpbbdocs-languages add fr metadata/source.json
git -C ../phpbbdocs-languages commit -m "Update French documentation translation"
git -C ../phpbbdocs-languages push -u origin translation/fr-update
```

Submit normal GitHub PR.

GitHub remains responsible for:

- authentication;
- attribution;
- review;
- discussion;
- permissions;
- history;
- approval;
- merging.

Submit the translation PR to `phpbbdocs-languages`. The example assumes the default sibling layout; use the configured path for other layouts. Review the staged metadata changes alongside the PO changes. Tooling changes belong in separate `phpbbdocs-hugo` PRs.

---

# 37. CI

Translation PRs should run automatic validation.

Example report:

```text
French Translation Validation
==============================

✓ PO syntax valid
✓ Translation checks passed
✓ DocBook reconstruction successful
✓ DocBook XML valid
✓ Sphinx localization successful
✓ Sphinx references valid
✓ Hugo build successful

User Documentation
------------------
Translated:    1842
Fuzzy:           21
Untranslated:    37

Developer Documentation
-----------------------
Translated:    2103
Fuzzy:           14
Untranslated:    94
```

Structural/build failures should fail CI.

Incomplete translation should normally not fail CI.

## CI across both repositories and source drift

Run lightweight PO/metadata/terminology QA in `phpbbdocs-languages`. Integration CI checks out the translation PR, a known `phpbbdocs-hugo` revision and the intended phpBB 3.3 upstream source revision, then runs reconstruction, Sphinx localization and the Hugo build. Record the resolved commits for reproducibility.

Automatically compare per-language source metadata with current upstream. Report the recorded and current revisions, changed source files and affected catalogs. Regenerate templates and test merges in a disposable checkout to detect catalog drift without modifying the contributor's branch. Missing or inconsistent metadata must be reported explicitly. Separate stale-catalog findings from translation incompleteness; establish the stale-catalog gate during CI implementation, while structural/build corruption remains a failure.

## Pseudo-localization

After the POCs, add a generated pseudo-language for build QA. Transform translatable prose with visible accents/markers and expansion to expose missing extraction, clipped headings and layout problems. Preserve placeholders, markup, IDs, links, commands and code/literal data. Keep pseudo catalogs and output in the build tree rather than asking translators to maintain them. Build both documentation families and inspect the rendered Hugo pages; a successful build alone cannot detect clipping.

---

# 38. Existing Translation Migration

Existing translations represent significant work.

Do not delete them when implementing PO.

Migration must follow:

```text
existing translation
        ↓
extract/import translation into PO
        ↓
generate translated document from PO
        ↓
compare
        ↓
build
        ↓
verify
        ↓
only then retire old canonical translation
```

Preserve Git history.

Move the verified canonical PO catalogs to `phpbbdocs-languages` as part of migration, retaining attribution and the applicable documentation license. Keep the old translations available until reconstruction and comparison pass. Do not leave two independently editable canonical copies after the verified cutover.

---

# 39. Developer Translation Drift

Existing translated developer DocBook trees have already shown file-count differences from current English generated output.

This demonstrates why generated translated document trees should not become long-term canonical translation storage.

Before migration, detect:

- missing files;
- extra files;
- path differences;
- structural differences.

Report extra translated files just as clearly as missing files.

---

# 40. Upstream Branch

Explicitly lock upstream synchronization to the intended phpBB 3.3 documentation branch.

Do not rely on whatever branch happens to be checked out in the shared sparse checkout.

Upstream remains READ ONLY.

---

# 41. Production Build Cleanup

After the translation architecture is proven, address stale generated output separately.

For user documentation:

- clean obsolete generated Markdown safely;
- preserve the separate developer subtree;
- synchronize images so removed upstream images do not remain indefinitely.

For developer documentation:

- if Sphinx XML replaces Pandoc/DocBook, remove generated DocBook handling only after equivalence testing.

Do not mix these changes into the translation POCs.

---

# 42. Implementation Order

## Phase A — DocBook Tool Comparison

Test:

```text
po4a
poxml
itstool
```

against the same real phpBB `admin_guide.xml`.

For each:

```text
DocBook
 ↓
POT
 ↓
PO
 ↓
translated DocBook
 ↓
xmllint
 ↓
existing XSLT
 ↓
Hugo
```

Select the best engine.

Do not change production yet.

---

## Phase B — Sphinx Gettext POC

Use real phpBB RST.

Test:

```text
RST
 ↓
Sphinx gettext
 ↓
POT
 ↓
PO
 ↓
localized Sphinx build
```

Verify extraction quality and translation application. Compare `gettext_compact` layouts, `gettext_uuid` enabled/disabled, source references and conservative additional gettext targets.

---

## Phase C — Sphinx XML POC

Test:

```text
RST + PO
 ↓
Sphinx
 ↓
localized XML
```

Verify:

- translated text;
- IDs;
- references;
- roles;
- code;
- tables;
- directives;
- navigation.

---

## Phase D — Sphinx XML → Hugo POC

Create the smallest practical transformation.

Test several representative pages.

Compare against current Pandoc→DocBook→Hugo output.

Determine whether Sphinx XML can replace the Pandoc intermediate cleanly.

---

## Phase E — Gettext Update Testing

Test source changes against both pipelines.

Measure:

- previous msgids, comments and source references retained;
- retained translations;
- fuzzy translations;
- untranslated additions;
- obsolete entries;
- unnecessary churn.

---

## Phase F — Architecture Decision

Only after both source families pass should PO formally become canonical translation storage.

---

## Phase G — Translation CLI

Implement the unified:

```text
translations.sh
```

interface, including configured sibling paths, `init`, `context`, automatic per-language source metadata and actionable update/status reports.

---

## Phase H — Existing Translation Migration

Migrate current translated content to PO.

Verify reconstruction before retiring old canonical translation copies.

---

## Phase I — CI

Add translation validation, source-revision drift detection and full Hugo build testing across both repositories. Add generated pseudo-localization once the regular localized builds are stable.

---

## Phase J — Cleanup

Only after migration is stable:

- retire obsolete translation mechanisms;
- retire generated translated source trees where appropriate;
- potentially retire Pandoc from developer docs;
- update `.gitignore`;
- update project documentation;
- remove obsolete Crowdin-specific infrastructure where appropriate.

---

# 43. Do Not Do

Do NOT:

- modify upstream phpBB documentation;
- require Weblate;
- invent a custom translation format;
- write a custom RST parser;
- use Pandoc to extract RST translations when Sphinx gettext exists;
- generate translated RST unless absolutely necessary;
- translate generated Hugo Markdown as canonical content;
- maintain PO and translated XML as independent canonical translations;
- change DocBook 4 to DocBook 5 casually;
- discard fuzzy translations;
- automatically discard obsolete translations;
- require 100% translation to build;
- expose translators to build-system internals unnecessarily;
- render root developer `index.dbk` merely because it exists;
- remove Pandoc before Sphinx XML output is proven equivalent or better;
- replace production scripts during the POC;
- delete existing translations before migration verification.

---

# 44. Immediate Claude Code Task

Do not implement the final architecture yet.

Run two independent proofs of concept.

## POC 1 — DocBook

Using the real `admin_guide.xml`, compare:

```text
po4a
poxml
itstool
```

For each:

1. extract POT;
2. inspect translation units;
3. create equivalent test PO translations;
4. reconstruct translated XML;
5. validate XML;
6. structurally compare source/translation;
7. run existing XSLT;
8. build Hugo;
9. document differences.

Return:

```text
DocBook Translation POC
=======================

                po4a    poxml    itstool
Extraction
PO quality
Inline markup
Round trip
IDs/xrefs
Tables
Code
XML validation
Hugo build
Update handling
Configuration
Maintenance
```

Recommend one.

Do not migrate production.

## POC 2 — Sphinx

Using representative real phpBB developer RST:

1. run Sphinx gettext;
2. generate POT;
3. create a small test PO;
4. build using the translated language;
5. use Sphinx's XML builder;
6. confirm translated text appears in generated XML;
7. inspect references, roles, code, tables and directives;
8. determine the minimum transformation needed for Hugo;
9. compare with current Pandoc/DocBook output;
10. compare `gettext_compact` layouts and `gettext_uuid` update behavior;
11. verify source references, comments, previous msgids, fuzzy and obsolete history;
12. verify conservative code/literal targets and record the canonical PO-to-Sphinx locale mapping.

Return:

```text
Sphinx Translation POC
======================

Gettext extraction:       PASS / CONCERNS / FAIL
PO quality:               PASS / CONCERNS / FAIL
Translation application:  PASS / CONCERNS / FAIL
XML generation:           PASS / CONCERNS / FAIL
References:               PASS / CONCERNS / FAIL
Code/directives:          PASS / CONCERNS / FAIL
Tables:                   PASS / CONCERNS / FAIL
Hugo feasibility:         PASS / CONCERNS / FAIL

Pandoc replacement:
YES / POSSIBLY / NO

Recommendation:
GO / GO WITH CHANGES / NO-GO
```

Stop after reporting the results.

Do not begin production migration without approval.

---

# 45. Desired End State

The final system should make the complexity invisible to translators:

```text
                     phpBB English Sources
                            │
              ┌─────────────┴─────────────┐
              │                           │
          DocBook 4                      RST
              │                           │
       po4a/poxml/itstool          Sphinx gettext
              │                           │
              ↓                           ↓
             POT                         POT
              ↕                           ↕
              PO ←──── TRANSLATORS ─────→ PO
              │                           │
              ↓                           ↓
      translated DocBook          Sphinx localized
              │                      doctree/XML
              │                           │
              ↓                           ↓
       existing DocBook          Sphinx XML→Hugo
          XSLT→Hugo                 transformation
              │                           │
              └─────────────┬─────────────┘
                            ↓
                       Hugo website
```

Canonical PO catalogs live in `phpbbdocs-languages`; generated POT and publishing output remain build artifacts. `phpbbdocs-hugo` supplies the configured helper commands, automatic source tracking and validation.

**English native sources in, standard PO files for translators, Hugo site out.**
