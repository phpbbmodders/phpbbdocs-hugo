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

## TODO

Ideas not yet built, practical and speculative alike: [`docs/TODO.md`](docs/TODO.md).

## License

This entire repository — build tooling (shell scripts, XSLT stylesheets, Hugo site templates/CSS) and documentation content alike (the English source pulled from [phpbb/documentation](https://github.com/phpbb/documentation), and its translations) &copy; phpBB Limited — is licensed under the [CC Attribution-NonCommercial-ShareAlike 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/) license, matching the single-license convention of phpBB's own upstream documentation repository. See [LICENSE](LICENSE).
