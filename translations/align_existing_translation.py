"""Align an itstool-extracted English POT with an itstool-extracted
translated POT of the ALREADY-translated equivalent document, to migrate
an existing hand-translation into a PO catalog (Phase H: existing
translation migration).

itstool's own POT output deduplicates identical msgids across multiple
locations into one entry with multiple '#:' references — which breaks
naive positional pairing when duplicate counts differ between two
documents' unique-string sets. This instead expands every entry back
out to one (line, text) pair per '#:' reference, sorts by line number
to recover true document order (including duplicates), and pairs the
two documents positionally on THAT ordered list — which only requires
matching TOTAL occurrence counts, not matching unique-entry counts.

Usage: python3 align_existing_translation.py en.pot target.pot out.po
       <lang> en.xml target.xml
(en.pot/target.pot from `itstool -o` against the English and existing-
translation source files respectively; en.xml/target.xml are those same
two source files again, used only to compute chapterinfo/abstract
exclusion ranges — see excluded_line_ranges below.)

Proven against the real content/fr/chapters/ vs content/en/chapters/
pair this tool was built for: 6 of 7 chapters aligned cleanly (90-99.6%
of entries filled per chapter; the remainder are genuine cases with no
1:1 correspondence, not tool failures); the 7th (upgrade_guide) hit a
genuine COUNT MISMATCH the tool correctly refused to force-align —
traced to 3 whole <important>/<itemizedlist> blocks present in English
but missing from French entirely, real content that needs a human
translator, not something an alignment script should paper over.

Known exclusions baked in (see excluded_line_ranges): French's existing
chapters deliberately drop <chapterinfo> (releaseinfo/copyright) and
<abstract> entirely, present in every English chapter — both excluded
from alignment so they don't masquerade as content gaps. A different
existing language's translation may have different omission patterns;
re-verify excluded_line_ranges' assumptions before reusing this against
German/Danish/Italian's existing content/<lang>/chapters/.
"""
import re
import sys
import polib


def excluded_line_ranges(xml_path):
    """(start, end) line ranges to exclude from alignment: <chapterinfo>
    (releaseinfo/copyright/author metadata) — confirmed present in
    English chapters but deliberately dropped in French's, so it's
    never translatable content to align, only ever a source of count
    mismatches. Same reasoning proteus_hugo_devdocs.xsl already
    applies when excluding articleinfo from dev-docs body content.

    <sectioninfo> (per-section authorgroup/othername translator
    credits) is excluded for the same reason: its block COUNT matches
    1:1 between English and a translation (confirmed across all 7
    chapters), but the number of <othername> entries inside each block
    varies freely — a translated section is usually credited to
    whoever translated it, not to however many original English
    authors are listed, which is never a real count-mismatch signal
    about missing content. Discovered via Danish's glossary.xml, which
    credits 1 translator across sectioninfo where English lists 4
    original authors."""
    text = open(xml_path, encoding='utf-8').read()
    ranges = []
    for pattern in (r'<chapterinfo>.*?</chapterinfo>', r'<abstract>.*?</abstract>', r'<sectioninfo>.*?</sectioninfo>'):
        for m in re.finditer(pattern, text, re.S):
            start = text[:m.start()].count('\n') + 1
            end = text[:m.end()].count('\n') + 1
            ranges.append((start, end))
    return ranges


def ordered_occurrences(pot_path, exclude_ranges=()):
    po = polib.pofile(pot_path)
    occurrences = []
    for entry in po:
        if entry.msgid == "translator-credits":
            continue
        for occ_file, occ_line in entry.occurrences:
            try:
                line = int(occ_line)
            except (TypeError, ValueError):
                line = 0
            if any(start <= line <= end for start, end in exclude_ranges):
                continue
            occurrences.append((line, entry.msgid))
    occurrences.sort(key=lambda x: x[0])
    return [text for _, text in occurrences]


def align(en_pot_path, target_pot_path, out_po_path, lang, en_xml_path=None, target_xml_path=None):
    en_exclude = excluded_line_ranges(en_xml_path) if en_xml_path else ()
    target_exclude = excluded_line_ranges(target_xml_path) if target_xml_path else ()
    en_order = ordered_occurrences(en_pot_path, en_exclude)
    target_order = ordered_occurrences(target_pot_path, target_exclude)

    if len(en_order) != len(target_order):
        print(
            f"COUNT MISMATCH: en={len(en_order)} target={len(target_order)} "
            f"for {en_pot_path} / {target_pot_path}",
            file=sys.stderr,
        )
        return False

    en_po = polib.pofile(en_pot_path)
    translations = {}
    for en_text, target_text in zip(en_order, target_order):
        translations.setdefault(en_text, []).append(target_text)

    consumed = {}
    filled = 0
    for entry in en_po:
        if entry.msgid == "translator-credits":
            continue
        idx = consumed.get(entry.msgid, 0)
        candidates = translations.get(entry.msgid, [])
        if idx < len(candidates):
            entry.msgstr = candidates[idx]
            consumed[entry.msgid] = idx + 1
            filled += 1

    en_po.metadata['Language'] = lang
    en_po.save(out_po_path)
    print(f"{out_po_path}: {filled}/{len(en_po)} entries filled")
    return True


if __name__ == '__main__':
    en_pot, target_pot, out_po, lang, en_xml, target_xml = sys.argv[1:7]
    ok = align(en_pot, target_pot, out_po, lang, en_xml, target_xml)
    sys.exit(0 if ok else 1)
