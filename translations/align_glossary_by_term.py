#!/usr/bin/env python3
"""Fill gaps in an existing glossary PO catalog by matching terms by
NAME instead of by document position.

glossary.xml is a special case for translation-existing-content
migration (see align_existing_translation.py, which this complements):
some languages resort their glossary alphabetically by the *translated*
term rather than keeping English's ordering (Danish does this — see
docs/gettext-workflow-checklist.md). Positional pairing between the
English and target POT files is unsafe there, since entry N in one
document doesn't correspond to entry N in the other.

This script instead pairs each glossary term/definition by matching the
target-language term text against the English term text (exact,
case-insensitive, or the English term appearing parenthetically in the
target term, e.g. Danish "Binaer (Binary)" against English "Binary").
Terms that don't match any of those patterns are left alone and listed
as unmatched, for a human/native-speaker to confirm the pairing by hand.

Typical use: after align_existing_translation.py (or an update cycle)
leaves some glossary entries untranslated despite the target-language
content/<lang>/chapters/glossary.xml already having them, in a
different position, because of this resorting.

Usage:
    python3 align_glossary_by_term.py <en_glossary.xml> <target_glossary.xml> <target.po> [--overwrite] [--dry-run]

Arguments:
    en_glossary.xml       Path to content/en/chapters/glossary.xml
    target_glossary.xml   Path to content/<lang>/chapters/glossary.xml
    target.po             The language's glossary.po catalog to fill in
                           (edited in place unless --dry-run is given)

Options:
    --overwrite   Also replace entries that already have a msgstr, not
                  just currently-untranslated ones. Off by default so a
                  normal run can't clobber existing translations.
    --dry-run     Report what would change without writing target.po.
"""
import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import polib


def extract_term_pairs(glossary_xml_path):
    """Run itstool -o against glossary_xml_path and pair each
    varlistentry/term message with the listitem/para message that
    immediately follows it in the extracted POT — safe regardless of
    how the <varlistentry> elements are ordered in the source XML,
    since term and definition are always adjacent within one entry.

    Returns a list of (term_text, definition_text) tuples, in POT
    (extraction) order.
    """
    glossary_xml_path = Path(glossary_xml_path)
    with tempfile.NamedTemporaryFile(suffix=".pot", delete=False) as tmp:
        pot_path = Path(tmp.name)
    try:
        subprocess.run(
            ["itstool", "-o", str(pot_path), glossary_xml_path.name],
            cwd=glossary_xml_path.parent,
            check=True, capture_output=True,
        )
        po = polib.pofile(str(pot_path))
    finally:
        pot_path.unlink(missing_ok=True)

    pairs = []
    pending_term = None
    for entry in po:
        comment = entry.comment or ""
        if "path: varlistentry/term" in comment:
            pending_term = entry.msgid
        elif "path: listitem/para" in comment and pending_term is not None:
            pairs.append((pending_term, entry.msgid))
            pending_term = None
        else:
            pending_term = None
    return pairs


def strip_tags(text):
    return re.sub(r"<[^>]+>", "", text).strip()


def matches_english_term(target_term, en_term):
    """True if target_term (from the translated glossary) should be
    paired with en_term (from the English glossary): exact match
    (case-insensitive), or en_term appears parenthetically at the end
    of target_term (e.g. "Binaer (Binary)" against "Binary")."""
    target_plain = strip_tags(target_term).lower()
    en_plain = strip_tags(en_term).lower()
    if target_plain == en_plain:
        return True
    paren = re.search(r"\(([^)]+)\)\s*$", strip_tags(target_term))
    return bool(paren and paren.group(1).strip().lower() == en_plain)


def main():
    parser = argparse.ArgumentParser(
        description="Fill gaps in a glossary PO catalog by matching terms by name, "
                    "not by document position (safe for alphabetically-resorted glossaries).",
    )
    parser.add_argument("en_glossary_xml", help="Path to content/en/chapters/glossary.xml")
    parser.add_argument("target_glossary_xml", help="Path to content/<lang>/chapters/glossary.xml")
    parser.add_argument("target_po", help="The language's glossary.po catalog to fill in")
    parser.add_argument("--overwrite", action="store_true",
                         help="Also replace entries that already have a msgstr, not just untranslated ones")
    parser.add_argument("--dry-run", action="store_true",
                         help="Report what would change without writing target_po")
    args = parser.parse_args()

    en_pairs = extract_term_pairs(args.en_glossary_xml)
    target_pairs = extract_term_pairs(args.target_glossary_xml)

    target_def_by_term = dict(target_pairs)

    po = polib.pofile(args.target_po)
    filled, unmatched = [], []

    for en_term, en_def in en_pairs:
        entry = po.find(en_def)
        if entry is None:
            continue
        if entry.msgstr and not args.overwrite:
            continue
        matched_target_term = next(
            (t for t in target_def_by_term if matches_english_term(t, en_term)), None)
        if matched_target_term is None:
            unmatched.append(en_term)
            continue
        entry.msgstr = target_def_by_term[matched_target_term]
        filled.append((en_term, matched_target_term))

    print(f"{len(filled)} definitions filled by term-name match:")
    for en_term, target_term in filled:
        print(f"  {strip_tags(en_term)!r} <- {strip_tags(target_term)!r}")
    if unmatched:
        print(f"\n{len(unmatched)} English terms had no matching target term (left untranslated):")
        for term in unmatched:
            print(f"  {strip_tags(term)!r}")

    if not args.dry_run and filled:
        po.save(args.target_po)
        print(f"\nSaved {args.target_po}")
    elif args.dry_run and filled:
        print("\n--dry-run: not saved")


if __name__ == "__main__":
    sys.exit(main())
