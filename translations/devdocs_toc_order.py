#!/usr/bin/env python3
"""Determines the real reading order of dev-docs chapters and pages by
parsing the actual `.. toctree::` directives in the upstream RST source,
instead of an alphabetical directory walk (what both the old DocBook
pipeline and this project's `cmd_devdocs_build` used before this file
existed).

Order is a structural property of the RST source itself -- identical
across every language -- so this only ever reads the English upstream
checkout (`upstream-phpbb-documentation/development/`), never a `.po`
catalog, and never needs to run more than once regardless of how many
languages are being built.

Confirmed by direct inspection of the real corpus before writing this
(see docs/TODO/todo-sphinx-devdocs-spike.md and the live-site-cutover
plan that added this file): every chapter has its own curated toctree
in its `index.rst` (`cli/index.rst`, `extensions/index.rst`, etc.), the
top-level `development/index.rst` toctree also establishes chapter
order (by which directory each entry's docname belongs to, in
first-occurrence order), and some toctrees (`language/index.rst`,
`migrations/tools/index.rst`) use a bare `*` glob entry -- Sphinx
expands that to every RST file in that toctree's own directory not
already explicitly listed, sorted.

One confirmed real case this has to handle correctly, not just in
theory: `db/structured_conditionals.rst` is not referenced by any
toctree anywhere in the real corpus (matches Sphinx's own build
warning: "document isn't included in any toctree"). Any docname
`sphinx_to_hugo.discover_known_docnames` finds that never appears in
any toctree is treated the same general way -- appended at the end of
its chapter's page list, sorted alphabetically among any other orphans
in that chapter, with a diagnostic printed to stderr. This is meant to
be loud, not silent, matching this project's established discipline
for unresolved references elsewhere in the converter (e.g. the XSLT's
own diagnostics for an unresolvable :doc:/:ref: target).
"""

import argparse
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import sphinx_to_hugo  # noqa: E402  (path insert must precede this import)


def _parse_toctree_entries(rst_path: pathlib.Path) -> list:
    """Every entry listed across all `.. toctree::` blocks in one RST
    file, in document order, as raw strings exactly as written (docname
    entries like "development/processes", or the literal "*" glob
    marker -- resolving either kind against the filesystem is the
    caller's job, this function only reads the directive's own text).

    Recognizes a block by its directive line, then treats every
    following line at or above the first content line's indentation as
    part of that block (blank lines don't end a block; a line back at
    the directive's own indentation, or lower, does), skipping option
    lines (`:maxdepth:`, `:glob:`, ...) and collecting everything else.
    This is deliberately just enough RST parsing to handle toctree
    blocks specifically -- not a general RST parser -- matching the
    same "small, fixed, itemized" philosophy already used for DocBook
    inline-markup normalization elsewhere in this project's tooling.
    """
    lines = rst_path.read_text(encoding="utf-8").splitlines()
    entries = []
    i = 0
    n = len(lines)
    while i < n:
        stripped = lines[i].strip()
        if not stripped.startswith(".. toctree::"):
            i += 1
            continue
        directive_indent = len(lines[i]) - len(lines[i].lstrip(" "))
        i += 1
        block_indent = None
        while i < n:
            line = lines[i]
            if not line.strip():
                i += 1
                continue
            indent = len(line) - len(line.lstrip(" "))
            if indent <= directive_indent:
                break
            if block_indent is None:
                block_indent = indent
            elif indent < block_indent:
                break
            content = line.strip()
            if not content.startswith(":"):
                entries.append(content)
            i += 1
    return entries


def _resolve_entry_docnames(entry: str, host_docname: str, source_root: pathlib.Path) -> list:
    """One raw toctree entry -> one or more real docnames (relative to
    source_root), resolved against the directory the *host* file (the
    file whose toctree this entry came from) lives in -- matching
    Sphinx's own toctree path resolution, where entries are relative to
    the referencing document, not to source_root.
    """
    host_dir = pathlib.PurePosixPath(host_docname).parent
    if entry == "*":
        # Every RST file in the host's own directory, sorted -- minus
        # the host document itself (an index.rst never globs itself).
        host_fs_dir = source_root / host_dir if str(host_dir) != "." else source_root
        siblings = sorted(
            (host_dir / p.stem).as_posix() if str(host_dir) != "." else p.stem
            for p in host_fs_dir.glob("*.rst")
        )
        return [s for s in siblings if s != host_docname]
    resolved = (host_dir / entry).as_posix() if str(host_dir) != "." else entry
    # Collapse a leading "./" that as_posix() can leave when host_dir is ".".
    if resolved.startswith("./"):
        resolved = resolved[2:]
    return [resolved]


def compute_order(source_root: pathlib.Path) -> dict:
    """Walks the real toctree structure depth-first from
    `development/index.rst`, returning
    {"chapters": [chapter, ...], "pages": [(chapter, docname, weight), ...]}
    -- `pages` weights are 1-indexed per chapter, toctree-derived pages
    first in DFS order, then any orphan docnames for that chapter
    appended alphabetically. `chapters` is in first-DFS-occurrence
    order of each docname's first path segment; a chapter that only
    ever has orphan pages (none reached via any toctree) is appended
    at the end, sorted alphabetically among any other such chapters,
    same spirit as the per-page orphan handling.
    """
    known = set(sphinx_to_hugo.discover_known_docnames(source_root))

    visit_order = []
    visited = set()

    def visit(docname):
        if docname in visited:
            return
        visited.add(docname)
        if docname != "index":
            visit_order.append(docname)
        rst_path = source_root / (docname + ".rst")
        if not rst_path.is_file():
            return
        for entry in _parse_toctree_entries(rst_path):
            for child in _resolve_entry_docnames(entry, docname, source_root):
                if child in known:
                    visit(child)
                # A toctree entry that doesn't match any real known
                # docname would be a genuine content bug (a typo'd
                # cross-reference in the RST source) -- silently
                # skipping it here would hide that. Real corpus has none;
                # if one ever appears, surface it rather than guess.
                elif child not in known:
                    print(
                        f"WARNING: toctree entry {child!r} in {docname}.rst "
                        f"does not match any known docname -- ignored",
                        file=sys.stderr,
                    )

    visit("index")

    orphans = sorted(known - visited - {"index"})
    for orphan in orphans:
        print(
            f"ORPHAN: {orphan} not referenced by any toctree — appended at end of its chapter",
            file=sys.stderr,
        )

    def chapter_of(docname):
        return docname.split("/", 1)[0]

    chapters = []
    for docname in visit_order + orphans:
        chapter = chapter_of(docname)
        if chapter not in chapters:
            chapters.append(chapter)

    pages = []
    for chapter in chapters:
        toctree_pages = [d for d in visit_order if chapter_of(d) == chapter]
        orphan_pages = sorted(d for d in orphans if chapter_of(d) == chapter)
        for weight, docname in enumerate(toctree_pages + orphan_pages, start=1):
            pages.append((chapter, docname, weight))

    return {"chapters": chapters, "pages": pages}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "source_root",
        type=pathlib.Path,
        help="Root of the Sphinx/RST dev-docs source tree (e.g. upstream-phpbb-documentation/development).",
    )
    args = parser.parse_args()
    source_root = args.source_root.resolve()
    if not source_root.is_dir():
        sys.exit(f"--source-root not found or not a directory: {source_root}")

    order = compute_order(source_root)
    for chapter, docname, weight in order["pages"]:
        print(f"{chapter}\t{docname}\t{weight}")


if __name__ == "__main__":
    main()
