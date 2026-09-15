# PO round-trip content audit

Now that `translations/vendor/itstool-patched` and
`translations/preserve_authorship_metadata.py` make `translations.sh
build <lang>` actually trustworthy (see
`docs/phpbb-gettext-translation-poc-results.md`, Follow-up 3), rebuilding
a chapter from its PO catalog and diffing every `<para>` against the
hand-maintained `content/<lang>/chapters/*.xml` is a cheap way to catch
two different kinds of pre-existing problems that have nothing to do with
the build tooling itself:

- **Divergence** between the hand file and the PO catalog (one was edited
  without the other being kept in sync).
- **Shared errors** present identically in both (so nothing ever flagged
  them) — e.g. a translation mistake that was in the original text and
  got faithfully carried into the PO catalog.

This was done for German's `upgrade_guide.xml` on 2026-09-15 and found 17
wrong-case article errors ("Der Datei" → "Die Datei", "Dem Verzeichnis" →
"Das Verzeichnis") and a wrong verb conjugation ("finden du" → "findest
du"), fixed in both phpbbdocs-hugo#31 and phpbbdocs-languages#2. That was one
chapter out of the 35 chapter × language combinations this project has PO
catalogs for — the rest haven't been swept this way.

See also `docs/gettext-workflow-checklist.md` for the broader standing
checklist this audit is one part of (also covers authorship-metadata
preservation and attribution, not just the content diff below).

## Method

For each `<lang>`/`<chapter>` pair:

1. Build a `.mo` from the PO catalog: `msgfmt -o /tmp/x.mo <lang>/documentation/<chapter>.po`
2. Reconstruct: `itstool -m /tmp/x.mo -l <lang> -o /tmp/x.xml content/en/chapters/<chapter>.xml` (use `translations/vendor/itstool-patched`, not the system `itstool`)
3. Run `translations/preserve_authorship_metadata.py /tmp/x.xml content/<lang>/chapters/<chapter>.xml` so chapterinfo/abstract/sectioninfo don't produce false-positive noise
4. Extract every `<para>` from both the reconstruction and the current hand file, normalize whitespace/quotes/entities, and diff them index-by-index
5. For each real mismatch: check which side is actually correct (don't assume the PO catalog wins) and fix both to agree
6. **`glossary.xml` needs a different comparison method** — Danish's glossary is deliberately resorted alphabetically by the *translated* term, not English's order, so a positional paragraph diff produces mass false positives there. Match by term name instead (see the term-name-keyed approach used for Danish's glossary earlier in the gettext migration work), and check whether other languages' glossaries have the same deliberate resorting before assuming English order applies.

## Status

| Chapter | da | de | de-x-sie | fr | it |
|---|---|---|---|---|---|
| admin_guide | | | | | |
| user_guide | | | | | |
| moderator_guide | | | | | |
| quick_start_guide | | | | | |
| upgrade_guide | | ✅ 2026-09-15 | | | |
| server_guide | | | | | |
| glossary | | | | | (needs term-keyed method, see above) |

Mark a cell ✅ with the date once swept and clean (or once found issues are fixed and it re-verifies clean). 34 of 35 combinations remain.
