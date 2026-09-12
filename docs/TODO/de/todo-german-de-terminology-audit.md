# German (de) terminology audit

This audit covers `content/de/chapters/*.xml` (all seven end-user
chapters) and all 50 developer-doc files under `dev-docs-docbook/de/`
against phpBB's real German casual (Du) language pack
(`phpbb-de/phpbb-translation`, `language/de/`).

## Methodology: why this isn't a fresh string-by-string audit

Unlike the `de_x_sie` (Formal/Sie) translation, which was translated
from English and then exhaustively cross-checked term by term, the
German casual (`de`) translation was produced by converting the
already-audited `de_x_sie` content to the Du register — the two
registers are otherwise identical in content, and this reuses all the
verified terminology work from the `de_x_sie` audit instead of
re-deriving it from English.

This means the terminology-matching status from the `de_x_sie` audit
carries over directly, for a concrete reason: phpBB's real UI
button/field labels (`<guilabel>`/`<guimenuitem>` values) don't change
between the formal and casual registers — "Absenden" (Submit), "Ja"/"Nein"
(Yes/No), and similar labels are register-invariant. The Sie→Du
conversion only changes surrounding prose (pronouns, possessives, verb
conjugation), not the quoted UI strings themselves.

This was verified two ways, not assumed:

1. **Diffing every chapter's extracted `<guilabel>`/`<guimenuitem>`/`<title>`
   strings** between `content/de_x_sie/chapters/*.xml` and
   `content/de/chapters/*.xml`. Four of the seven chapters
   (`moderator_guide.xml`, `upgrade_guide.xml`, `server_guide.xml`,
   `glossary.xml`) came back with **zero** differences. The other
   three had only the expected handful of differences — cases where a
   `<guilabel>` happened to embed a full conjugated sentence rather
   than a bare button label (e.g. "Ihr Konto wurde erstellt..." →
   "Dein Konto wurde erstellt...", "Wählen Sie ein Modul" → "Wähle ein
   Modul") — confirmed as correct register conversions, not new
   mismatches.
2. **Spot-checking real `de` (casual) pack values** for the keys the
   `de_x_sie` audit found most interesting, including the two
   pre-existing English-source bugs phpBB dev team lead Marc
   confirmed (see the supplementary glossary): `MIN_THUMB_FILESIZE` →
   `'Minimale Vorschaubild-Dateigröße'` and `RECOMPILE_STYLES` →
   `'Rekompilieren veralteter Style-Komponenten'` — identical to the
   `de_x_sie` pack's values for the same keys.

Given both checks confirm the underlying real-string values are
identical between registers, the `de_x_sie` audit's findings — the
~75 genuine mismatches already fixed in `admin_guide.xml` and
`user_guide.xml`, the 144 categorized non-issues, and the residual
genuinely-unconfirmed terms — all apply equally to `de`. Nothing
further needed re-deriving from scratch.

## What the Sie→Du conversion itself needed checking for (not a
terminology-matching question)

Converting formal to casual register introduced its own class of
possible errors, unrelated to whether a term matches the real
language pack: verb agreement (`Sie können` → `du kannst`, not
`du können`), reflexive pronoun case (`sich` → `dich`/`dir`), and a
German-specific ambiguity where capitalized "Sie"/"Ihr" mid-document
can mean either formal "you" or third-person "it/she" (referring to a
feminine noun like *die Datei*) — indistinguishable by capitalization
alone at a sentence start. All of `content/de/` and
`dev-docs-docbook/de/` were checked for this category of error
directly (not via language-pack comparison), including a systematic
scan cross-referencing the original `de_x_sie` source's sentence
structure to catch cases where "Sie"/"Ihr" genuinely meant "it/its"
(e.g. "Die zweite neue Datei heißt `ext.php`. Sie kann verwendet
werden..." — describing the file, not addressing the reader) and had
been mechanically misconverted to "Du"/"dein". These were individually
verified and fixed; this is a translation-quality concern, not a
terminology-audit one, so it isn't repeated here — see the commit
history for `content/de/` and `dev-docs-docbook/de/` for the specifics.

## Dev-docs

All 50 dev-docs files inherit the same "no fresh audit needed"
reasoning: `dev-docs-docbook/de_x_sie/` doesn't use
`<guilabel>`/`<guimenuitem>` tags at all (per the `de_x_sie` audit), so
there was no language-pack cross-checking to redo in the first place —
the `de_x_sie` dev-docs pass was purely a translation-fidelity read,
and that fidelity carries over through the grammatical conversion the
same way the end-user chapters' terminology does.

## Genuinely unconfirmed items

Same terms as the `de_x_sie` audit, for the same reason (identical
underlying strings, no matching real-pack key found for either
register). Listed with Du-form wording in
[`german-de-supplementary-glossary.md`](german-de-supplementary-glossary.md).

**Where this applies to future edits:** if a future edit to
`content/de/` or `dev-docs-docbook/de/` introduces a new literal
phpBB UI string, check it against the real `language/de/` pack the
same way the original `de_x_sie` audit did (see
[`docs/translation-process-prompt.md`](../../translation-process-prompt.md)
for the full methodology) — the "convert from de_x_sie" shortcut only
applies to content that already existed in `de_x_sie` at the time of
this audit.
