#!/usr/bin/env python3
"""Real, assert-based test suite for translations/devdocs_toc_order.py.

No mocking, no pytest -- matches this repo's other test files
(tests/sphinx_devdocs/test_sphinx_to_hugo.py, tests/translations_sh/test_devdocs_workflow.py).
Every check here runs the real module against small, real, hand-written
RST fixture trees written to a temp directory -- never a mocked
filesystem or a stubbed toctree parser.

Covers the three shapes the real corpus was confirmed (during the
live-site-cutover plan that added this module) to actually need:
depth-first order across a multi-entry top-level toctree, recursive
resolution into a nested chapter's own toctree (including one using a
bare "*" glob, like migrations/tools/index.rst and language/index.rst
really do), and a genuine orphan docname -- one `discover_known_docnames`
finds but no toctree anywhere references, matching the real corpus's
db/structured_conditionals.rst case -- appended at the end of its
chapter, sorted, with a diagnostic on stderr rather than silently
dropped or silently included in the main order.

Run directly: python3 tests/translations_sh/test_devdocs_toc_order.py
"""

import pathlib
import sys
import tempfile

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "translations"))
import devdocs_toc_order  # noqa: E402

FAILURES = []


def check(condition: bool, message: str) -> None:
    if condition:
        print("ok:", message)
    else:
        print("FAIL:", message)
        FAILURES.append(message)


def write_fixture(root: pathlib.Path, files: dict) -> None:
    for rel, content in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


def test_dfs_order_and_chapter_order():
    with tempfile.TemporaryDirectory(prefix="toc_order_test_") as tmp:
        root = pathlib.Path(tmp)
        write_fixture(
            root,
            {
                # Deliberately lists "bbb" before "aaa" -- opposite of
                # alphabetical -- so chapter order can only pass this
                # check if it really comes from the toctree.
                "index.rst": (
                    "Title\n=====\n\n.. toctree::\n   :maxdepth: 2\n\n   bbb/one\n   aaa/two\n"
                ),
                "bbb/one.rst": "One\n===\n",
                "aaa/two.rst": "Two\n===\n",
            },
        )
        order = devdocs_toc_order.compute_order(root)
        check(order["chapters"] == ["bbb", "aaa"], "chapter order follows the toctree, not alphabetical directory names")
        check(
            order["pages"] == [("bbb", "bbb/one", 1), ("aaa", "aaa/two", 1)],
            "each single-page chapter gets its one page at weight 1, in toctree-derived chapter order",
        )


def test_recursive_toctree_and_glob():
    with tempfile.TemporaryDirectory(prefix="toc_order_test_") as tmp:
        root = pathlib.Path(tmp)
        write_fixture(
            root,
            {
                "index.rst": "Title\n=====\n\n.. toctree::\n   :maxdepth: 2\n\n   chapter/index\n",
                "chapter/index.rst": (
                    "Chapter\n=======\n\n.. toctree::\n   :maxdepth: 1\n   :glob:\n\n   *\n"
                ),
                # Glob-matched files, written so their filesystem sort
                # order (alpha_first, zeta_last) matches what a bare "*"
                # should produce -- both starting with different
                # letters so an accidental non-glob-aware "just list
                # everything found" bug would still coincidentally pass
                # a same-order check; the real assertion is on the
                # actual weight sequence below, not just presence.
                "chapter/alpha_first.rst": "Alpha\n=====\n",
                "chapter/zeta_last.rst": "Zeta\n====\n",
            },
        )
        order = devdocs_toc_order.compute_order(root)
        check(order["chapters"] == ["chapter"], "the nested chapter is the only chapter")
        check(
            order["pages"]
            == [
                ("chapter", "chapter/index", 1),
                ("chapter", "chapter/alpha_first", 2),
                ("chapter", "chapter/zeta_last", 3),
            ],
            "DFS visits the chapter-index page itself first, then its own glob-toctree children in sorted order",
        )


def test_orphan_appended_with_diagnostic():
    with tempfile.TemporaryDirectory(prefix="toc_order_test_") as tmp:
        root = pathlib.Path(tmp)
        write_fixture(
            root,
            {
                "index.rst": "Title\n=====\n\n.. toctree::\n   :maxdepth: 2\n\n   chapter/known\n",
                "chapter/known.rst": "Known\n=====\n",
                # Never referenced by any toctree -- the orphan.
                "chapter/orphan.rst": "Orphan\n======\n",
            },
        )
        order = devdocs_toc_order.compute_order(root)
        check(
            order["pages"] == [("chapter", "chapter/known", 1), ("chapter", "chapter/orphan", 2)],
            "an orphan docname is appended after its chapter's real toctree-ordered pages, not silently dropped or interleaved",
        )

        import io
        import contextlib

        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            devdocs_toc_order.compute_order(root)
        check(
            "ORPHAN: chapter/orphan" in stderr.getvalue(),
            "a diagnostic naming the orphan docname is printed to stderr, not a silent skip",
        )


def test_orphan_only_chapter_still_gets_a_chapter_entry():
    with tempfile.TemporaryDirectory(prefix="toc_order_test_") as tmp:
        root = pathlib.Path(tmp)
        write_fixture(
            root,
            {
                "index.rst": "Title\n=====\n\n.. toctree::\n   :maxdepth: 2\n\n   known/page\n",
                "known/page.rst": "Page\n====\n",
                # An entire chapter that only exists via an orphan page
                # -- never reached by any toctree at all, not even
                # indirectly through a sibling in the same directory.
                "orphanchapter/page.rst": "Orphan Chapter Page\n====================\n",
            },
        )
        order = devdocs_toc_order.compute_order(root)
        check(
            order["chapters"] == ["known", "orphanchapter"],
            "a chapter reached only through an orphan page still appears in the chapter list, appended after every toctree-reached chapter",
        )
        check(
            ("orphanchapter", "orphanchapter/page", 1) in order["pages"],
            "the orphan-only chapter's page is still assigned a real weight",
        )


def main() -> int:
    test_dfs_order_and_chapter_order()
    test_recursive_toctree_and_glob()
    test_orphan_appended_with_diagnostic()
    test_orphan_only_chapter_still_gets_a_chapter_entry()

    print()
    if FAILURES:
        print("{} check(s) FAILED:".format(len(FAILURES)))
        for message in FAILURES:
            print(" -", message)
        return 1
    print("All checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
