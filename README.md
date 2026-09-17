# phpbbdocs-hugo

A self-contained second copy of the phpBB documentation build pipeline (`phpbbdocs-hugo`, née `proteus-duex` — "Proteus 2"), independent of the project root's own `xsl/`, `content/`, and `proteus_doc_*.xml`. It started as a plain copy of the Hugo pipeline and grew from there: a way to pull the *current* upstream phpBB documentation, extend the site with the developer documentation (which the original pipeline never covered), and add translations of both. See [`docs/phpbb-hugo-languages.md`](docs/phpbb-hugo-languages.md) for which languages are currently supported.

Nothing in this folder touches the project root — the two pipelines are fully separate copies.

## Scripts, in the order you'd actually run them

### 1. `pull_upstream_docs.sh` — sync the end-user docs source from upstream

```bash
./pull_upstream_docs.sh
```

Upstream is the source of truth for the English end-user docs, not a locally-maintained copy: this syncs `content/en/chapters/` and `content/en/images/` straight from the `documentation/` subtree of the official [phpbb/documentation](https://github.com/phpbb/documentation) repo (via a cached sparse checkout at `upstream-phpbb-documentation/`), overwriting local changes and removing anything upstream no longer has. `content/da/`, `content/fr/`, and `proteus_doc_<lang>.xml` (this project's own multi-language book wrapper — not present upstream in this form) are untouched.

**Run this before step 2** to make sure the build reflects current upstream content. `proteus_doc_<lang>.xml`'s `<bookinfo>` (title/abstract/authorgroup/copyright) is hand-maintained, not synced by this script — check it against `upstream-phpbb-documentation/documentation/proteus_doc.xml` by hand if upstream's book metadata changes.

### 2. `phpbbdocs_hugo.sh` — build the end-user docs

```bash
./phpbbdocs_hugo.sh [language|all] [destination_dir]
```

Transforms `proteus_doc_<lang>.xml` (via `xsl/proteus_hugo.xsl`) into Hugo Markdown under `site/content/<lang>/`, copies that language's images, then runs `hugo`. `language` defaults to `all` (every `proteus_doc_*.xml` found — currently `en`, `da`, `fr`, `de_x_sie`, `de`, and `it`); `destination_dir` defaults to `site/public`.

**No prerequisite script for `da`/`fr`/`de_x_sie`/`de`/`it`** — those are Claude-translated static source. For `en`, run step 1 first so it reflects current upstream rather than whatever was last synced.

### 3. `convert_dev_docs_to_docbook.sh` — pull and convert the developer docs (old pipeline, no longer part of this recipe)

```bash
./convert_dev_docs_to_docbook.sh [output_dir]
```

Pulls the `development/` subtree (Sphinx/reStructuredText developer docs — coding guidelines, extension tutorials, DBAL reference, etc.) from the same upstream repo, and converts every `.rst` file to DocBook 4 XML via a pinned pandoc 3.11 (downloaded once into a local cache) with two fix-ups pandoc's own DocBook writer needs (see the script's header comment for the specifics — an unclosed `<br>` tag and an invalid `&nbsp;` entity). Output defaults to `dev-docs-docbook/en/`.

**No longer a prerequisite for anything in this recipe** — step 4 below builds the developer docs a different way now. This script (and the `dev-docs-docbook/` content it feeds) still exists in the repo but gets no further maintenance; see [`docs/TODO/todo-old-devdocs-pipeline-cleanup.md`](docs/TODO/todo-old-devdocs-pipeline-cleanup.md).

**Only produces English**, and is now **run automatically by step 4 whenever `language` is `en`** — there's no automated translation step, so `da`/`fr` still work as before (see "Adding another language" below for how those versions actually came about). Run this script directly only if you want the raw DocBook output on its own, e.g. as a starting point for a new translation.

### 4. `translations.sh devdocs-build` — build the developer docs

```bash
./translations.sh devdocs-build <language> site/content/<language>/development
```

Reconstructs translated dev-docs Markdown for one language directly into the real site content tree, using that language's PO catalogs (in the sibling `phpbbdocs-languages` repo) plus the real upstream Sphinx/RST source (`upstream-phpbb-documentation/development/`, a separate checkout from `pull_upstream_docs.sh`'s own — `translations.sh devdocs-extract` manages it). Chapter and page order come from the real `.. toctree::` structure in the upstream RST (`translations/devdocs_toc_order.py`), not an alphabetical directory walk. Run once per language you want in the build — currently `en`, `da`, `fr`, `de_x_sie`, `de`, and `it` (an `en` build works the same way as any other: `devdocs-init en`/`devdocs-check en` first, matching every other language, with `msginit` auto-filling `msgstr = msgid` for the same-language case).

Unlike `phpbbdocs_hugo.sh`, this command doesn't run `hugo` itself — it only writes content, matching `translations.sh`'s existing scope for the end-user `documentation` family too. Follow it with `./phpbbdocs_hugo.sh all` (step 2 above) to fold the result into a real build. Omit the second argument to write into `build/devdocs-preview/<language>/development/` instead — a disposable preview location, useful for checking a translation's output before trusting it in the real site.

This replaces the old `phpbbdocs_hugo_devdocs.sh`/`dev-docs-docbook/`/Pandoc pipeline as the documented dev-docs build path (see [`docs/TODO/todo-sphinx-devdocs-spike.md`](docs/TODO/todo-sphinx-devdocs-spike.md) for that migration's own history). The old scripts and content still exist in this repo but get no further maintenance and aren't part of this recipe anymore — see [`docs/TODO/todo-old-devdocs-pipeline-cleanup.md`](docs/TODO/todo-old-devdocs-pipeline-cleanup.md) for their eventual removal.

### 5. `fill_translation_fallbacks.sh` — fill translation gaps with the source-language content

```bash
./fill_translation_fallbacks.sh <source_lang> [target_lang ...]
```

For every page that exists in `source_lang`'s content but has no counterpart at the same path in a target language, copies the source page over verbatim, flagged with `fallback: true` front matter. The site's `single.html` template checks that flag and shows a "this page hasn't been translated yet" notice (in the *reader's* language — `i18n/<lang>.toml`'s `fallbackNotice` key — even though the body content underneath is still in the source language). Without this, a page missing from one language's tree just has no language-switcher link to it at all; with it, the link exists, points at real (if untranslated) content, and says so.

`target_lang` defaults to every other `content/<lang>/` directory found if omitted. Safe to re-run anytime — a real translation is never overwritten (only files still carrying `fallback: true` get refreshed), and a fallback page that's since gotten a real translation is left alone on the next run since the real file already occupies that path.

**Run this last**, after whichever of steps 2/4 you just ran — it only fills gaps in whatever's already on disk, it doesn't build or pull anything itself.

## Common workflows

**Full site, all languages, from scratch:**
```bash
./pull_upstream_docs.sh                  # syncs content/en/ from upstream
./phpbbdocs_hugo.sh all
./translations.sh devdocs-build en site/content/en/development
./translations.sh devdocs-build da site/content/da/development
./translations.sh devdocs-build fr site/content/fr/development
./translations.sh devdocs-build de_x_sie site/content/de_x_sie/development
./translations.sh devdocs-build de site/content/de/development
./translations.sh devdocs-build it site/content/it/development
./fill_translation_fallbacks.sh en da fr de_x_sie de it
./phpbbdocs_hugo.sh all                    # rebuild once more so the fallback/dev-docs pages are in the built site
```
(each `devdocs-build` above assumes that language's dev-docs PO catalogs already exist and are up to date — run `./translations.sh devdocs-check <lang>` first if you're not sure; see "Adding another language to the developer docs" below for a language that doesn't have catalogs yet.)

**Just want the latest end-user docs content?** `./pull_upstream_docs.sh && ./phpbbdocs_hugo.sh all` — the sync pulls current upstream chapters/images into `content/en/`, then the build picks them up. Follow with `./fill_translation_fallbacks.sh en da fr de_x_sie de it && ./phpbbdocs_hugo.sh all` if the sync introduced pages a translation doesn't have yet.

**Just want the latest developer docs?** `./translations.sh devdocs-build en site/content/en/development` (and the same per other language you want refreshed) followed by `./phpbbdocs_hugo.sh all` to fold it into a real build. A fresh English upstream pull doesn't automatically update translated catalogs — that's `./translations.sh devdocs-update <lang>`, a separate, still-manual-translation step.

## Adding another language to the developer docs

```bash
./translations.sh devdocs-init <lang>        # creates empty PO catalogs mirroring the RST tree
# hand-translate <languages-repo>/<lang>/development/**/*.po
./translations.sh devdocs-check <lang>       # validates every catalog and its reconstruction
./translations.sh devdocs-build <lang> site/content/<lang>/development
./phpbbdocs_hugo.sh all
```

For the end-user-docs side of adding a language (which follows a
different, DocBook-based process) — plus the terminology audit and
TODO writeup that followed for German — see
[`docs/translation-process-prompt.md`](docs/translation-process-prompt.md).

`convert_dev_docs_to_docbook.sh` only ever produces English (`dev-docs-docbook/en/`) — it pulls straight from upstream, which has no other language for the developer docs. `dev-docs-docbook/da/`, `dev-docs-docbook/fr/`, `dev-docs-docbook/de_x_sie/`, `dev-docs-docbook/de/`, and `dev-docs-docbook/it/` were each produced by translating the English DocBook source directly (prose translated; code samples, file paths, `<literal>` technical identifiers, and `<ulink>` URLs left untouched; XML structure and `id` attributes preserved exactly), then verified for well-formedness and structural completeness (row/entry counts compared 1:1 against the English source) before building.

To add a language `<lang>`:
1. Translate every file in `dev-docs-docbook/en/` into `dev-docs-docbook/<lang>/`, mirroring the exact subdirectory structure and filenames, following the same translate-prose/preserve-code rules above.
2. Validate each translated file: `xmllint --noout --nonet <file>`.
3. `./phpbbdocs_hugo_devdocs.sh <lang>`.

Every page gets a `translationKey` (`development-<chapter>-<slug>`, stable across languages) so Hugo's language switcher can link a translated page back to its original — this only works if the translated files keep the exact same filenames/subdirectory layout as the English source, since the key is derived from that.

## `index.dbk` isn't built into the site

`dev-docs-docbook/en/index.dbk` (and its Danish, French, and Italian translations) — the developer docs' own master table-of-contents page, converted from `development/index.rst` — sits at the root of each language's source tree rather than inside a chapter subdirectory. `phpbbdocs_hugo_devdocs.sh` only walks chapter subdirectories, so this file stays inert plaintext alongside the source tree rather than content the build picks up, even though it's been pulled and translated. The auto-generated `/development/` landing page (listing every chapter) stands in for it.

## TODO

Ideas not yet built, practical and speculative alike: [`docs/TODO.md`](docs/TODO.md).

## License

This entire repository — build tooling (shell scripts, XSLT stylesheets, Hugo site templates/CSS) and documentation content alike (the English source pulled from [phpbb/documentation](https://github.com/phpbb/documentation), and its translations) &copy; phpBB Limited — is licensed under the [CC Attribution-NonCommercial-ShareAlike 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/) license, matching the single-license convention of phpBB's own upstream documentation repository. See [LICENSE](LICENSE).
