# phpbbdocs-hugo

A self-contained second copy of the phpBB documentation build pipeline (`phpbbdocs-hugo`, née `proteus-duex` — "Proteus 2"), independent of the project root's own `xsl/`, `content/`, and `proteus_doc_*.xml`. It started as a plain copy of the Hugo pipeline and grew from there: a way to pull the *current* upstream phpBB documentation, extend the site with the developer documentation (which the original pipeline never covered), and add translations of both. See [`docs/phpbb-hugo-languages.md`](docs/phpbb-hugo-languages.md) for which languages are currently supported.

Nothing in this folder touches the project root — the two pipelines are fully separate copies.

## Building and publishing

Four scripts pull upstream content, build translated Hugo Markdown for
every language, and publish the static site:
`pull_upstream_docs.sh`, `phpbbdocs_hugo.sh`, `translations.sh
devdocs-build`, and `fill_translation_fallbacks.sh`. Detailed
documentation for running and operating this project now lives on the
repo Wiki, not here:

- **[Build & Publish Workflow](https://github.com/phpbbmodders/phpbbdocs-hugo/wiki/Build-Workflow)**
  — the scripts in the order you'd run them, and the common
  full-site-rebuild recipes.
- **[Script Reference](https://github.com/phpbbmodders/phpbbdocs-hugo/wiki/Script-Reference)**
  — every script's exact command syntax, with real examples.
- **[Translator Workflow](https://github.com/phpbbmodders/phpbbdocs-hugo/wiki/Translator-Workflow)**
  — adding or updating one language's translation, end to end.

## Documentation search

Full-text search uses [Pagefind](https://pagefind.app/) 1.5.2.
`phpbbdocs_hugo.sh` and `phpbbdocs_hugo_devdocs.sh` run
`build_search_index.sh` after Hugo, which writes one Pagefind bundle per
language and top-level section to `site/public/<lang>/<section>/pagefind/`.
Install the `pagefind` 1.5.2 binary on `PATH` for fast builds; otherwise the
script falls back to `npx`, which needs Node.js.

Each language's search page, `/<lang>/search.html`, merges that language's
section bundles in the browser and needs JavaScript. The phpBB Documentation
extension serves only the bundles for sections a user may read, so keep
sections in separate bundles. It ships a copy of
`site/static/js/documentation-search.js`; keep the two copies in sync. The
sidebar **Filter** is separate and still filters page titles only.

The search page shows up to `searchMaxResults` results (in `site/config.toml`,
10-200, default 50). Each result loads its own excerpt, so a higher limit
makes searches with many matches slower.

Hugo also writes `<lang>/<section>/search-index.json` for each top-level
section: every page's site-rooted URL, title and plain text. The phpBB
Documentation extension searches these on the server for visitors without
JavaScript, reading only the sections a user may see. Nested sections get an
empty list.

## Documentation tooltips

Normal Hugo builds add tooltip definitions through
`site/layouts/partials/documentation-content.html`. The browser displays
explanations for the Events List headings and the first occurrence of ACP,
MCP, CLI, and DBAL on each page. Links and code are left alone. Hover,
keyboard focus, and tapping show the explanation; Escape dismisses it.
Without JavaScript, the original page text is unchanged.

Definitions live in `site/i18n/en.toml`. Other Hugo language files can
translate those keys; missing translations use Hugo's English fallback.
No imported Markdown or `.po` files need edits, and future builds need no AI.

Images with non-empty alt text also show that description as a tooltip.
The image render hook supplies missing descriptions for four known
developer documentation images using the `imageAlt*` language keys.
Existing descriptions take precedence; unknown or decorative empty-alt
images remain unchanged. Real alt attributes are present even without JavaScript.

The documentation extension ships copies of
`site/static/js/documentation-tooltips.js` and
`site/static/css/documentation-tooltips.css`. Keep those copies in sync when
changing tooltip behaviour or styling; changing definitions only needs a rebuild.

## TODO

Ideas not yet built, practical and speculative alike: [`docs/TODO.md`](docs/TODO.md).

## License

This entire repository — build tooling (shell scripts, XSLT stylesheets, Hugo site templates/CSS) and documentation content alike (the English source pulled from [phpbb/documentation](https://github.com/phpbb/documentation), and its translations) &copy; phpBB Limited — is licensed under the [CC Attribution-NonCommercial-ShareAlike 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/) license, matching the single-license convention of phpBB's own upstream documentation repository. See [LICENSE](LICENSE).
