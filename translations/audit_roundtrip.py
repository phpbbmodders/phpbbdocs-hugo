#!/usr/bin/env python3
"""Diff a freshly-reconstructed chapter against its hand-maintained XML,
paragraph by paragraph, to catch real content problems that `translations.sh
check` doesn't: `check` only validates that a PO catalog compiles and
reconstructs to well-formed XML, not that the reconstruction actually
says the same thing as the file already committed to content/<lang>/chapters/.

Two kinds of real problems this catches (see
docs/TODO/todo-po-roundtrip-audit.md for the full writeup and worked
examples from 2026-09-15):

  - Divergence between the hand file and the PO catalog (one was edited
    without the other being kept in sync).
  - Shared errors present identically in both (so nothing ever flagged
    them) -- a translation mistake that was in the original text and got
    faithfully carried into the PO catalog.

glossary.xml needs different handling than every other chapter: some
languages (Danish) deliberately resort it alphabetically by the
*translated* term rather than keeping English's order, so a positional
paragraph diff produces mass false positives there. This script matches
glossary entries by term name instead (see match logic in
align_glossary_by_term.py, which this mirrors) when the chapter name is
"glossary".

Usage:
    python3 audit_roundtrip.py <chapter> <hand.xml> <recon.xml>

Exit status: 0 if no real mismatches found, 1 otherwise. Prints every
mismatch found either way.
"""
import re
import sys


def normalize(text):
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    text = re.sub(r"\s+", " ", text).strip()
    text = re.sub(r"\s+/>", "/>", text)
    text = text.replace("class='", 'class="').replace("'>", '">')
    text = (text.replace("&gt;", ">").replace("&lt;", "<")
                .replace("&quot;", '"').replace("&#39;", "'").replace("&apos;", "'"))
    return text


def paragraphs(path):
    text = open(path, encoding="utf-8").read()
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    return [normalize(p) for p in re.findall(r"<para>(.*?)</para>", text, re.S)]


def glossary_terms(path):
    text = open(path, encoding="utf-8").read()
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    entries = re.findall(
        r"<varlistentry>\s*<term>(.*?)</term>\s*<listitem>\s*<para>(.*?)</para>",
        text, re.S)

    def strip_and_norm(s):
        return normalize(re.sub(r"<[^>]+>", "", s))

    return {strip_and_norm(t): strip_and_norm(d) for t, d in entries}


def audit_glossary(hand_path, recon_path):
    hand = glossary_terms(hand_path)
    recon = glossary_terms(recon_path)
    mismatches = []
    for term, hand_def in hand.items():
        recon_def = recon.get(term)
        if recon_def is not None and recon_def != hand_def:
            mismatches.append((term, hand_def, recon_def))
    missing_in_recon = sorted(set(hand) - set(recon))
    missing_in_hand = sorted(set(recon) - set(hand))
    return mismatches, missing_in_recon, missing_in_hand


def audit_paragraphs(hand_path, recon_path):
    hand = paragraphs(hand_path)
    recon = paragraphs(recon_path)
    # A reconstruction may carry one extra leading paragraph the hand
    # file omits by convention (a chapterinfo/abstract intro sentence
    # some languages drop) -- tolerate exactly that one-paragraph offset.
    offset = 1 if len(recon) == len(hand) + 1 and recon[1:] and recon[1] == hand[0] else 0
    recon = recon[offset:]
    n = min(len(hand), len(recon))
    mismatches = [(i, hand[i], recon[i]) for i in range(n) if hand[i] != recon[i]]
    return mismatches, len(hand), len(recon)


def main():
    if len(sys.argv) != 4:
        print(__doc__, file=sys.stderr)
        return 2
    chapter, hand_path, recon_path = sys.argv[1:4]

    if chapter == "glossary":
        mismatches, missing_in_recon, missing_in_hand = audit_glossary(hand_path, recon_path)
        real_problem = bool(mismatches) or bool(missing_in_recon) or bool(missing_in_hand)
        for term, hand_def, recon_def in mismatches:
            print(f"MISMATCH term={term!r}")
            print(f"  hand : {hand_def[:150]!r}")
            print(f"  recon: {recon_def[:150]!r}")
        if missing_in_recon:
            print(f"Terms in hand file with no reconstruction match: {missing_in_recon}")
            print("  (a term the hand file has that English's glossary doesn't is a "
                  "permanent, expected gap -- confirm that's what this is, not a "
                  "genuine PO catalog problem)")
        if missing_in_hand:
            print(f"Terms in reconstruction with no hand-file match: {missing_in_hand}")
        if not real_problem:
            print(f"{chapter}: clean, {len(glossary_terms(hand_path))} terms match")
    else:
        mismatches, hand_n, recon_n = audit_paragraphs(hand_path, recon_path)
        for i, hand_p, recon_p in mismatches:
            print(f"MISMATCH paragraph #{i}")
            print(f"  hand : {hand_p[:150]!r}")
            print(f"  recon: {recon_p[:150]!r}")
        real_problem = bool(mismatches) or hand_n != recon_n
        if hand_n != recon_n and not mismatches:
            print(f"{chapter}: paragraph count differs (hand={hand_n} recon={recon_n}) "
                  "beyond the one-paragraph intro exception -- investigate structurally, "
                  "don't assume this is just a diff-offset artifact")
        if not real_problem:
            print(f"{chapter}: clean, {hand_n} paragraphs match")

    return 1 if real_problem else 0


if __name__ == "__main__":
    sys.exit(main())
