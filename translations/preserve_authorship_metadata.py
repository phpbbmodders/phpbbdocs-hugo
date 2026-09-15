#!/usr/bin/env python3
"""Fix up itstool's DocBook reconstruction so it matches this project's
translated-file conventions instead of blindly mirroring the English
source's authorship metadata.

itstool's PO/gettext pipeline only carries translatable prose; it has no
concept of chapter-level `<chapterinfo>`/`<abstract>` blocks being
deliberately omitted in translations, or of per-section `<sectioninfo>`
author/translator credits being different from the English original's.
Left alone, `itstool -m` reconstruction always reproduces the English
source's chapterinfo/abstract/sectioninfo verbatim, which:

  - reintroduces `<chapterinfo>`/`<abstract>` that translated chapters
    deliberately drop, and
  - overwrites a section's translator attribution (e.g.
    `<othername>Claude</othername>` for a fully Claude-retranslated
    section) with the English original's author usernames.

Each language's target file is the authoritative source for these
blocks, not the English original: some languages (e.g. German) keep a
translated `<chapterinfo>`/`<abstract>`, others (e.g. Danish) deliberately
drop them entirely, and per-section `<sectioninfo>` records translator
attribution that has no PO/gettext representation at all. This script
patches a freshly-reconstructed chapter in place so a rebuild can never
silently overwrite those choices:

  - The reconstruction's top-level `<chapterinfo>` and `<abstract>` are
    replaced with whatever the *previous* version of the target file
    had for them (verbatim) — including having neither, if the previous
    target had neither.
  - Each `<section id="...">`'s direct-child `<sectioninfo>` is likewise
    replaced with the corresponding block from the previous target,
    matched by section id.

Sections/blocks with no previous counterpart (newly added since the
last build) keep whatever itstool produced from the English source, since
there's nothing to preserve.

Usage: preserve_authorship_metadata.py <reconstructed.xml> [<previous_target.xml>]

Modifies <reconstructed.xml> in place. If <previous_target.xml> is
omitted or doesn't exist (e.g. a language's first build), nothing is
preserved: whatever itstool reconstructed from English is left as-is.
"""
import sys
from pathlib import Path

from lxml import etree


def restore_chapter_level_block(root, previous_root, tag):
    current = root.find(tag)
    previous = previous_root.find(tag) if previous_root is not None else None
    if previous is not None:
        if current is not None:
            root.replace(current, previous)
        else:
            # <title> is always the chapter's first real child; insert
            # chapterinfo/abstract immediately before it, matching
            # DocBook's expected element order.
            title = root.find("title")
            title.addprevious(previous) if title is not None else root.append(previous)
    elif current is not None:
        root.remove(current)


def collect_sectioninfo_by_id(root):
    by_id = {}
    for section in root.iter("section"):
        section_id = section.get("id")
        sectioninfo = section.find("sectioninfo")
        if section_id and sectioninfo is not None:
            by_id[section_id] = sectioninfo
    return by_id


def restore_sectioninfo(root, previous_by_id):
    for section in root.iter("section"):
        section_id = section.get("id")
        if not section_id or section_id not in previous_by_id:
            continue
        current = section.find("sectioninfo")
        replacement = previous_by_id[section_id]
        if current is not None:
            section.replace(current, replacement)
        else:
            section.insert(0, replacement)


def main():
    if len(sys.argv) not in (2, 3):
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    reconstructed_path = Path(sys.argv[1])
    previous_path = Path(sys.argv[2]) if len(sys.argv) == 3 else None

    parser = etree.XMLParser(remove_blank_text=False, strip_cdata=False)
    tree = etree.parse(str(reconstructed_path), parser)
    root = tree.getroot()

    previous_root = None
    if previous_path is not None and previous_path.exists():
        previous_root = etree.parse(str(previous_path), parser).getroot()

    for tag in ("chapterinfo", "abstract"):
        restore_chapter_level_block(root, previous_root, tag)

    if previous_root is not None:
        previous_by_id = collect_sectioninfo_by_id(previous_root)
        restore_sectioninfo(root, previous_by_id)

    tree.write(str(reconstructed_path), xml_declaration=True, encoding="utf-8")


if __name__ == "__main__":
    main()
