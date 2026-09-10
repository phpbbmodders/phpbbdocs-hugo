# Prompt: add or audit a phpbbdocs-hugo translation

A self-contained prompt for an AI coding assistant (or a human following
the same steps) to recreate the full translation-and-audit process this
project used for German (`de_x_sie`). Paste the section(s) below that
apply — adding a brand-new language needs all of them in order;
re-auditing an existing translation only needs "Exhaustive terminology
audit" onward.

---

## 0. Context to give the assistant

> You're working in `phpbbdocs-hugo`, a Hugo-based rebuild of the phpBB
> documentation pipeline. It pulls the current upstream English
> end-user docs and developer docs (converted from Sphinx/RST to
> DocBook), and adds hand-authored translations. Every per-language
> directory is named after phpBB's own ISO Code for that language pack
> (see `docs/phpbb-hugo-languages.md`) — underscored in `content/` and
> `dev-docs-docbook/` (e.g. `de_x_sie`), hyphenated everywhere else in
> the repo's own docs (e.g. `docs/TODO/de-x-sie/`). Read
> `docs/phpbb-hugo-languages.md` and `README.md`'s "Adding another
> language" section before starting.

## 1. Adding a brand-new language: the translation itself

1. Confirm the language's real phpBB ISO Code and register/variant
   (casual vs. formal honorifics, script variant, spelling variant —
   `docs/phpbb-hugo-languages.md` has the full phpBB→Hugo mapping).
2. Translate every end-user chapter: copy `content/en/chapters/*.xml`
   into `content/<code>/chapters/`, translate the prose, and follow
   `README.md` step 1's guidance — `proteus_doc_<lang>.xml`'s
   `<bookinfo>` needs hand-written title/abstract/authorgroup/copyright
   too, it isn't synced automatically for any language.
3. Translate the developer docs: follow `README.md`'s "Adding another
   language to the developer docs" section exactly — translate every
   `.dbk` file in `dev-docs-docbook/en/` into
   `dev-docs-docbook/<code>/`, preserving code samples, file paths,
   `<literal>` identifiers, `<ulink>` URLs, XML structure, and `id`
   attributes untouched. Validate each file (`xmllint --noout --nonet
   <file>`) and verify row/entry counts match the English source 1:1
   before building.
4. Build and verify: `./phpbbdocs_hugo.sh <code>` and
   `./phpbbdocs_hugo_devdocs.sh <code>`.
5. Run `./fill_translation_fallbacks.sh en <code> ...` (with every
   other language already in the project) so any page this new
   language doesn't have yet gets a flagged fallback instead of a
   broken language-switcher link.

## 2. Exhaustive terminology audit

The goal: verify every literal UI string (button, field, menu item,
page name) the translation quotes actually matches what the real phpBB
software calls it — not just that the prose reads fluently.

**Scope: "full review" means every end-user chapter (all seven —
`admin_guide.xml`, `user_guide.xml`, `moderator_guide.xml`,
`quick_start_guide.xml`, `upgrade_guide.xml`, `server_guide.xml`,
`glossary.xml`) *and* every file under `dev-docs-docbook/<code>/`, not
whichever subset is convenient or has the clearest tooling available.
Report progress as "N of M files done" while working, and don't report
the audit complete until every file — chapters and dev-docs alike —
has actually been covered, adapting the review method per file type
(string-matching for chapters, prose/technical-accuracy reading for
dev-docs) rather than skipping the files the easy method doesn't fit.**

1. **Get the real reference.** Find the authoritative language pack
   for this language and register (for German Formal Honorifics, that
   was `phpbb-de/phpbb-translation` on GitHub; other languages will
   have their own community-maintained repo, or you may need to work
   from the files listed at https://www.phpbb.com/languages/ directly).
   Fetch every `acp/*.php`, `root/*.php` (aliased from the base
   `language/<code>/` directory), and `help/*.php` file, plus the
   equivalent English files from `phpbb/phpbb`'s own `language/en/`
   tree (same relative paths). Aggregate all string *values* from the
   real translation into one file for fast diffing, and build a
   key→value map for both languages (a `'KEY' => 'Value',` regex over
   each `.php` file works — watch for keys appearing in more than one
   file, since context, not just key name, decides which value is the
   real match).
2. **Per chapter**, extract every `<guilabel>`/`<guimenuitem>`/`<title>`
   string: `grep -ohE '<guilabel>[^<]*</guilabel>|<guimenuitem>[^<]*</guimenuitem>|<title>[^<]*</title>' <file> | sed -E 's/<\/?(guilabel|guimenuitem|title)>//g' | sort -u`,
   then `comm -23` that against the aggregated real-values file to get
   the unmatched set.
3. **Pair each unmatched term with its English source line.** If the
   translated file's tag *count* matches the English file's tag count
   exactly (verify with `grep -c` on both), you can safely pair them
   positionally (`paste` the two ordered tag-content lists together).
   If the counts differ even by one, positional pairing silently
   drifts after the divergence point — find it first (`diff` the two
   files reduced to just their tag *types*, ignoring content) and pair
   anything past that point by hand via `grep -n` context instead of
   trusting the array position.
4. **Investigate each unmatched term individually.** For each one:
   look up its paired English string against the real English→key map;
   if a key matches, check the *file* it's defined in against the
   surrounding context (ACP vs. MCP vs. UCP settings can share
   identical English text for unrelated features — a key match isn't
   proof unless the file/context fits what the doc is describing).
   Then categorize:
   - **Genuine mismatch** → fix the document to match the real value,
     verify with a real build (`./phpbbdocs_hugo.sh <code>` or the
     devdocs equivalent) afterward.
   - **Confirmed-correct false positive** → the crude string
     comparison missed it: inline `<code>`/`<em>` markup in the PHP
     source, curly vs. straight quotes, or a label built by
     concatenating two separate real keys. No fix needed.
   - **Grammatical case form** of an already-correct term (declension,
     plural used in enumerating prose vs. singular in a literal quote)
     — will never match the pack's dictionary form. No fix needed.
   - **English-source paraphrase** — if the English text at that spot
     is itself *not* a literal quote of the real string (a descriptive
     heading, a shortened summary), and the translation mirrors that
     same non-literal style, that's not a bug.
   - **Untranslated technical string by design** — product names, file
     paths, template placeholder tokens, bare acronyms. No fix needed.
   - **Pre-existing issue shared with the English source** — if the
     English original has the identical problem (checked against the
     real key/value the same way), don't silently fix only the
     translation; that would fork it from an equally-wrong source.
     Flag it for a separate upstream report instead.
   - **Genuinely unconfirmed** — no matching key found anywhere in the
     fetched reference files. Add it to that language's supplementary
     glossary (see below) rather than guessing.
5. **Dev-docs get a different check.** They rarely quote literal UI
   strings (`grep -l '<guilabel>\|<guimenuitem>' dev-docs-docbook/<code>/**/*.dbk`
   to confirm), so the review there is translation fidelity and
   technical accuracy against the English `.dbk` source, not
   string-matching. If a numeric, factual, or logical error appears
   identically in both languages, it's a pre-existing English-source
   issue — flag it, don't silently diverge the translation from its
   source.
6. This is exhaustive, not sampled: every unmatched string reaches one
   of the categories above before the audit is reported done. A
   residual "still unmatched but probably fine" count is unfinished
   work, not a stopping point.

## 3. Write up the results

Create `docs/TODO/<hyphenated-code>/` with:

- **`README.md`** — index linking the files below (see
  `docs/TODO/de-x-sie/README.md` for the pattern).
- **`todo-<language>-<hyphenated-code>-terminology-audit.md`** — the
  audit's methodology and results: what was fixed (with real examples),
  what's clean, and the reasoning for each category of non-issue left
  unmatched. Include a "How to do this" section so the process is
  repeatable without re-deriving it.
- **`todo-<language>-<hyphenated-code>-translation-human-review.md`** —
  a separate document for a native speaker to do a qualitative prose
  read-through (content that's never been read, judgment calls worth
  double-checking) — this is a different task from the mechanical
  audit above and needs a different reviewer skill, so keep it a
  separate file, not a merged one. Link to the audit doc and glossary
  for status numbers rather than restating them.
- **`<language>-<hyphenated-code>-supplementary-glossary.md`** — one
  fillable table (English source, current translation, exact location,
  why it's unconfirmed, blank columns for agreed term / confirmed by /
  date in `YYYY-MM-DD` format) for every genuinely-unconfirmed term.
  Don't split this into a separate "reference" doc and a separate
  "fillable" doc — one file with a reasoning column plus the fillable
  columns is enough.

Then wire it in:
- Add the language to `docs/TODO/language.md`'s index.
- `docs/TODO.md` needs no new line — it already points at
  `docs/TODO/language.md` for every language.
- Check `README.md` and `docs/phpbb-hugo-languages.md` for staleness:
  does the new language need adding to workflow examples, or does
  descriptive prose there already say "translations" generically
  rather than enumerating? (Prefer the generic phrasing — don't add
  another name to a list that'll need editing again next time.)

## 4. Writing conventions to follow throughout

- Attribute work accurately: if an AI assistant did the cross-checking,
  translating, or investigating, say so by name ("Claude cross-checked
  every string," "Claude-translated static source") — never "I" as if
  a human did it personally, and never "hand-translated"/"hand-verified"
  for something an AI assistant actually did.
- Write status docs as one coherent statement of the current state, not
  a layered log of "a later pass fixed X, then Y was also fixed" —
  rewrite the affected section fresh rather than appending to it.
- When reporting back conversationally, summarize what was reviewed and
  its completeness — not a fix-by-fix list. Commit messages are where
  the itemized detail belongs.
