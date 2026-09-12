# Danish (da) terminology audit

This audit cross-references UI terms across all seven end-user chapters
(`admin_guide.xml`, `user_guide.xml`, `moderator_guide.xml`,
`quick_start_guide.xml`, `upgrade_guide.xml`, `server_guide.xml`,
`glossary.xml`) against phpBB's real Danish language pack
(`scootergrisen/phpbb_da`, `language/da/`). `dev-docs-docbook/da/`
(55 files) has also been checked for the same
translation-completeness issue — see "Dev-docs" below; it is in good
shape and needed no fixes.

## Translation-completeness gap found and fixed

Before any terminology comparison could be meaningful, a more basic
problem turned up: checking each chapter's density of Danish-specific
characters (æ/ø/å) as a proxy for "was this genuinely translated"
showed that **`server_guide.xml` and `upgrade_guide.xml` contained
zero Danish characters** — they were the English source content
copied into the `da/` directory verbatim, never actually translated,
despite sitting alongside five chapters that clearly were. This was
caught while investigating why `upgrade_guide.xml`'s unmatched terms
looked like English prose rather than translation drift.

Both chapters have since been fully translated into Danish and
validated (`xmllint --noout`), reusing established terminology from
the other five chapters and real language-pack values looked up
directly (`Opdater`, `Indsend`, `Ja`, `Nej`, `Konverter`, `Fortsæt
konvertering`, `Administratorkontrolpanel`, `Udvidelser`, `Vedligehold`).

## Methodology

Every `<guilabel>`/`<guimenuitem>`/`<title>` string across all seven
chapters was extracted and compared against the real pack
(`acp/`, `help/`, and root-level `.php` language files, ~5,159 keys
parsed). Tag-count parity between English and Danish versions of each
chapter was checked first and found to drift significantly in more
than one chapter, confirming (as with the German and French audits)
that positional English/Danish pairing is unsafe — real-pack-key
lookup was used instead of positional comparison throughout.

## A systematic drift found and fixed: "smilies" vs. "smileys"

The existing five chapters consistently spelled the feature
"smilies" (English plural spelling) throughout prose and
`<guilabel>`/`<guimenuitem>` tags, but the real Danish pack
consistently spells it **"smileys"** (`SMILIES` → `Smileys`,
`DISABLE_SMILIES` → `Anvend ikke smileys`, `EDIT_SMILIES` → `Ret
smileys`, `ACP_SMILIES` → `Smileys`, `SMILIES_PATH` → `Smiley-mappens
placering`, and a dozen more). This was a genuine, consistent
mismatch, not a stylistic choice, and has been fixed across all
affected chapters (`admin_guide.xml`, `user_guide.xml`,
`moderator_guide.xml`, `upgrade_guide.xml`) in both UI-quoted tags and
surrounding prose. The literal directory path `/images/smilies/` (the
real phpBB installation directory, spelled the same regardless of UI
language) and the DocBook section anchor IDs (`posting_smilies`,
`acp_posting_smilies`, internal cross-reference targets, not
user-visible text) were deliberately left unchanged.

## Current state per chapter

| Chapter | `<guilabel>`/`<guimenuitem>` occurrences | Unmatched |
|---|---|---|
| `admin_guide.xml` | 757 | 163 |
| `user_guide.xml` | 123 | 23 |
| `quick_start_guide.xml` | 75 | 22 |
| `moderator_guide.xml` | 35 | 14 |
| `upgrade_guide.xml` | 14 | 5 |
| `server_guide.xml` | 0 | 0 |
| `glossary.xml` | 0 | 0 |

The smilies fix above and the one confirmed ACP-tab mismatch in the
newly-translated `upgrade_guide.xml` (`Vedligeholdelse` →
`Vedligehold`, matching the real `ACP_CAT_MAINTENANCE` key already
used correctly elsewhere in `admin_guide.xml`) are the confirmed real
fixes from this pass.

Of the remaining unmatched terms, roughly 40% are `TITLE`-only
(descriptive section headings that don't correspond to a literal UI
string and aren't expected to match a language-pack key — the same
non-issue category established in the German and French audits).

**`admin_guide.xml` (163 unmatched) and, to a lesser extent,
`user_guide.xml` (23) and `quick_start_guide.xml` (22), are not yet
resolved to the same exhaustive per-term standard as the smaller
chapters** — this mirrors exactly where the French audit left off for
its two largest chapters. Real fixes were applied wherever a
confirmed key match was found (the smilies family above), but the
full remaining set has only been triaged at a category level
(colon/case/apostrophe artifact, untranslated technical term,
descriptive title, or genuine residue with no key found) rather than
each individual string hand-verified. The genuine residue is listed in
[`danish-da-supplementary-glossary.md`](danish-da-supplementary-glossary.md).
Finishing these three chapters to the same standard as the rest is the
open item here.

## A significant open terminology-choice question

Unlike the smilies spelling drift, two very widely-used words in the
existing translation are **not typos** — they're plausible Danish
synonyms that simply don't match the real pack's chosen wording:

- **"kodeord" vs. "adgangskode"** (password) — the real pack
  consistently uses `Adgangskode` (`PASSWORD` → `Adgangskode`,
  `NEW_PASSWORD` → `Ny adgangskode`), but the existing translation uses
  "kodeord" 36 times across `admin_guide.xml`, `quick_start_guide.xml`,
  `user_guide.xml`, and `glossary.xml`.
- **"email" vs. "e-mail"** — the real pack consistently hyphenates
  (`EMAIL_ADDRESS` → `E-mailadresse`), but the existing translation
  uses the unhyphenated form 128 times, overwhelmingly in
  `admin_guide.xml` (107 occurrences) and `user_guide.xml` (16).

Both are legitimate Danish words/spellings, not obviously wrong the
way "smilies" was — this needs a native Danish speaker's judgment
call before any project-wide find/replace, the same way the German
audit's "Ausdünnen" and the French audit's "sticky"/"Note" cases were
deliberately left as open questions rather than force-changed. See
[`danish-da-supplementary-glossary.md`](danish-da-supplementary-glossary.md)
for the full breakdown and a place to record the decision.

## Dev-docs

`dev-docs-docbook/da/` (55 files) has been checked using the same
character-density method that caught the two untranslated end-user
chapters. Three files (`index.dbk`, `extensions/index.dbk`,
`files/index.dbk`) initially showed zero Danish-specific characters,
but each turned out to be a genuine, correct translation that simply
happens to be short and use words without æ/ø/å (e.g. "Filupload",
"Indhold", "Velkommen til phpBB's udviklingsvejledning...") — confirmed
by diffing against the English source line by line, not assumed. No
actual translation gap exists.

None of the 55 files use `<guilabel>`/`<guimenuitem>` tags (same as
the German and French dev-docs), so there is no terminology-matching
work to do here — this was purely a translation-completeness check.
All 55 files validate as well-formed XML. A spot check of a
lower-density file (`extensions/tutorial_parsing_text.dbk`, 2.74%,
mostly diluted by code blocks and identifiers) confirmed genuine,
fluent Danish translation throughout, including the correct "smileys"
spelling already in use there (no drift found in dev-docs, unlike the
end-user chapters).

## How to continue this audit

For each remaining unmatched `<guilabel>`/`<guimenuitem>`/`<title>`
string in `admin_guide.xml`, `user_guide.xml`, or
`quick_start_guide.xml`, identify the real phpBB language key it
corresponds to (grep the relevant `language/da/` or `language/da/acp/`
file from [scootergrisen/phpbb_da](https://github.com/scootergrisen/phpbb_da)
by its English string first, via `language/en/`, to find the key, then
check the Danish value) and fix the document if it differs. Watch for
false positives from crude string matching: curly vs. straight
apostrophes and trailing colons account for a share of "unmatched"
strings that are actually correct. Verify with a real
`./phpbbdocs_hugo.sh da` build afterward.
