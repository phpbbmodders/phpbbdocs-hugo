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

See also `docs/gettext-workflow-checklist.md` for the broader standing
checklist this audit is one part of (also covers authorship-metadata
preservation and attribution, not just the content diff below).

## Status: complete, all 35 combinations swept 2026-09-15

Every chapter × language combination this project has PO catalogs for is
now round-trip clean. Issues found and fixed along the way:

- **German (`de`) `upgrade_guide`**: 17 wrong-case article errors ("Der
  Datei" → "Die Datei", "Dem Verzeichnis" → "Das Verzeichnis") and a
  wrong verb conjugation ("finden du" → "findest du"), present in both
  the hand file and the PO catalog identically. Fixed in
  phpbbdocs-hugo#31 and phpbbdocs-languages#2.
- **German Formal (`de-x-sie`) `upgrade_guide`**: the same article-case
  errors, inherited into this register's hand file; its PO catalog
  already had the correct text (only the hand file needed fixing), plus
  one msgstr ("Dem Verzeichnis ext/") that was wrong in both.
- **French (`fr`) `upgrade_guide`**: the PO catalog was 0% translated
  (`align_existing_translation.py` had correctly refused to auto-align
  it — see its own docstring — because 3 `<important>`/`<itemizedlist>`
  blocks that English repeats once per update method, French had
  deliberately stated only once, before all 4 methods, rather than
  repeating verbatim). Restructured the hand file to match English's
  repetition (using the correct existing French text, copied to each of
  the 4 positions) so the catalog could align cleanly, then populated it
  — 132/141 entries filled, matching the same fill rate as this
  project's other 6 successfully-aligned French chapters.
- **Danish (`da`) `glossary`**: 12 definitions (ACP, ASCII, Binary,
  Database, DBAL, DBMS, FTP, Jabber, Listener, MD5, PHP, SMTP) had never
  been translated in the PO catalog despite the hand file already having
  correct Danish text for all of them — filled using the new
  `translations/align_glossary_by_term.py` (see Method below).
- **Danish `glossary`'s `CAPTCHA` entry** is a permanent, understood
  exception, not a bug: Danish's glossary has this term but English's
  doesn't, so it has no PO representation at all and will always read as
  "missing" in a reconstruction — there's nothing to fix here, since the
  PO/gettext model can only carry content that exists in the English
  source.

## Method

For each `<lang>`/`<chapter>` pair (all chapters except `glossary.xml`):

1. Build a `.mo` from the PO catalog: `msgfmt -o /tmp/x.mo <lang>/documentation/<chapter>.po`
2. Reconstruct: `itstool -m /tmp/x.mo -l <lang> -o /tmp/x.xml content/en/chapters/<chapter>.xml` (use `translations/vendor/itstool-patched`, not the system `itstool`)
3. Run `translations/preserve_authorship_metadata.py /tmp/x.xml content/<lang>/chapters/<chapter>.xml` so chapterinfo/abstract/sectioninfo don't produce false-positive noise
4. Extract every `<para>` from both the reconstruction and the current hand file, normalize whitespace/quotes/entities (including `&quot;`/`&gt;`/`&lt;` — a real false-positive source if skipped), and diff them index-by-index
5. For each real mismatch: check which side is actually correct (don't assume the PO catalog wins) and fix both to agree; if the divergence turns out to be a genuine structural choice (like French's deduplication above) rather than a translation gap, either restructure the hand file to match English (preferred, keeps the PO pipeline lossless) or document the exception clearly if restructuring isn't appropriate

**`glossary.xml` needs `translations/align_glossary_by_term.py` instead**
of the paragraph diff above — some languages (Danish) deliberately
resort their glossary alphabetically by the *translated* term, so a
positional comparison produces mass false positives. That script matches
terms by name (exact match, or the English term appearing parenthetically
in the target term) and fills PO gaps directly; run it with `--dry-run`
first to review matches before saving.

## Re-running this audit later

This is a point-in-time sweep, not a standing guarantee — a future PO
catalog update or hand-file edit could reintroduce a divergence. Re-run
the method above (a short script looping every chapter/language pair,
same shape as described here) whenever there's reason to suspect drift,
such as before trusting `translations.sh build` output for a language
that hasn't been checked recently.
