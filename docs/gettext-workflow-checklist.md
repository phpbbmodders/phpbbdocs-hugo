# gettext translation workflow: definition of done

A checklist of what should always happen when touching the PO/gettext
translation pipeline (`translations.sh`, PO catalogs in the sibling
`phpbbdocs-languages` repo, or `content/<lang>/chapters/*.xml`) —
without needing to be asked for each item individually. Compiled after
several of these were skipped or done ad hoc during the itstool bug
investigation and fixes on 2026-09-15 (see
`docs/phpbb-gettext-translation-poc-results.md`, Follow-up 3, and
`docs/TODO/todo-po-roundtrip-audit.md`).

## Before running `translations.sh build <lang>` (or anything that writes to `content/`)

- [ ] `git status` first. Confirm the working tree is clean so any bad
      output is trivially revertible.
- [ ] Use `translations/vendor/itstool-patched`, never the system
      `itstool` — `translations.sh` already does this, but a one-off
      manual `itstool -m` command needs it explicitly. The system
      version silently drops translations for certain placeholder
      paragraphs (fixed upstream report:
      [itstool/itstool#58](https://github.com/itstool/itstool/issues/58),
      not merged there — the vendored copy is the actual fix).

## After running `build`, or after editing a PO catalog by hand

- [ ] Round-trip verify: `./translations.sh audit <lang>` — not just
      `xmllint`/`translations.sh check` validity, which corrupted or
      stale content still passes. It's read-only and safe to run any
      time (see `docs/TODO/todo-po-roundtrip-audit.md`).
- [ ] If there's a real mismatch, don't assume either side is right by
      default. Check which one is actually correct (a native-language
      read, or cross-check against the real phpBB language pack) and
      fix **both** the hand file and the PO catalog to agree — leaving
      them to silently diverge again defeats the point of the catalog.
- [ ] If the mismatch is a translation error present identically in
      *both* the hand file and the PO catalog (nothing ever diverged,
      so nothing ever caught it), that's still a real bug — fix it, the
      same as a divergence.
- [ ] If a glossary term exists in the hand file but not the
      reconstruction (or vice versa), check whether it's a genuine gap
      or a permanent structural exception first — a term one language's
      glossary has that English's doesn't (like Danish's `CAPTCHA`
      entry) can never round-trip through PO, and that's expected, not
      a bug to chase.

## Any time a rebuild touches `content/<lang>/chapters/`

- [ ] `translations/preserve_authorship_metadata.py` must run before the
      reconstruction replaces the target file (`translations.sh build`
      already wires this in — don't call `itstool -m` directly against
      a live target file without it). Never let a rebuild silently:
  - reintroduce `<chapterinfo>`/`<abstract>` a language's file
    currently doesn't have (or drop ones it currently does — this is
    per-file, not a fixed per-language rule),
  - revert a section's `<sectioninfo>`/`<othername>` translator
    attribution back to the English original's authors.
- [ ] If a test build was only to verify a fix (not an actual content
      change being shipped), revert it — `git checkout --
      content/<lang>/chapters/` — rather than leaving it modified in the
      working tree.

## Attribution, every time

- [ ] "Claude" by name for any cross-checking, translating, or
      investigating an AI assistant actually did — never "I" as if a
      human did it personally, never "hand-translated"/"hand-verified".
- [ ] A fully Claude-retranslated section's `<sectioninfo>` uses
      `<othername>Claude</othername>`, not a stale original-translator
      username or the English doc's own author.

## Committing and shipping

- [ ] Small, focused, well-verified fixes (a grammar correction, a
      tooling bug fix) follow the normal push/PR/merge workflow without
      needing separate confirmation for the merge step — same as any
      other routine change in this project.
- [ ] Don't ship a PO catalog or pipeline change that has a known-broken
      piece, even a documented one, and don't ship something not yet
      wired into actual use as if it were done — fix it or hold off,
      don't ship with a caveat.
