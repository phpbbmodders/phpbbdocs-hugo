#!/usr/bin/env python3
"""Real, assert-based test suite for translations/sphinx_to_hugo.py.

No mocking, no pytest dependency (this repo has no test infrastructure
yet -- a plain top-to-bottom script matches the project's existing
lightweight-tool convention, e.g. fix_csv_table_headers.py,
translations/align_glossary_by_term.py). Every check here runs the
real tools (sphinx-build, xsltproc, hugo) against real content and
asserts on their real output -- never "did it exit 0".

Two kinds of coverage:

  1. The full pipeline against the real fixture project
     (tests/sphinx_devdocs/fixtures/ -- three frozen files from the
     real upstream phpBB dev-docs corpus, sharing one index.rst
     toctree so cross-file :doc: resolution can be tested against a
     real target, not a mocked one), including a real `hugo build` of
     the converted output in a temp site -- the same verification
     discipline the two prior spikes used (see
     docs/TODO/todo-sphinx-devdocs-spike.md).
  2. Targeted unit checks, run directly through xsltproc against small
     hand-written Docutils XML snippets, for edge cases that don't
     happen to occur anywhere in the three real fixture files: a
     backtick inside inline code, a triple-backtick run inside a code
     block, a pipe inside a table cell, a quote inside a title, and a
     deliberately-unhandled element.

Run directly: python3 tests/sphinx_devdocs/test_sphinx_to_hugo.py
"""

import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
FIXTURES = pathlib.Path(__file__).resolve().parent / "fixtures"
CONVERTER = REPO_ROOT / "translations" / "sphinx_to_hugo.py"
XSL_PATH = REPO_ROOT / "xsl" / "proteus_sphinx_hugo.xsl"

FAILURES = []


def check(condition: bool, message: str) -> None:
    if condition:
        print("ok:", message)
    else:
        print("FAIL:", message)
        FAILURES.append(message)


def run(cmd, **kwargs):
    result = subprocess.run(cmd, capture_output=True, text=True, **kwargs)
    return result


def run_ok(cmd, **kwargs):
    result = run(cmd, **kwargs)
    if result.returncode != 0:
        raise RuntimeError(
            "command failed ({}): {}\n--- stdout ---\n{}\n--- stderr ---\n{}".format(
                result.returncode, " ".join(str(c) for c in cmd), result.stdout, result.stderr
            )
        )
    return result


# ===================== fixture-project setup: real POT/PO catalogs =====================

CONF_PY = """
extensions = []
smartquotes = False
master_doc = "index"
exclude_patterns = ["_build"]
gettext_compact = False
"""


def build_synthetic_catalogs(work_dir: pathlib.Path) -> pathlib.Path:
    """Runs a real `sphinx-build -b gettext` against the fixture project,
    then fills every extracted msgid with a synthetic "[XX] "-prefixed
    translation via polib (same method both prior spikes used, so the
    result answers "does the pipeline work", not "is this translation
    any good") and compiles it. Returns the directory containing the
    .po catalogs, one per fixture RST file.
    """
    import polib

    conf_dir = work_dir / "conf"
    conf_dir.mkdir()
    (conf_dir / "conf.py").write_text(CONF_PY, encoding="utf-8")

    gettext_dir = work_dir / "gettext"
    run_ok(
        [
            "sphinx-build", "-b", "gettext", "-q",
            "-c", str(conf_dir),
            str(FIXTURES), str(gettext_dir),
        ]
    )

    po_dir = work_dir / "po"
    for pot in gettext_dir.rglob("*.pot"):
        rel = pot.relative_to(gettext_dir)
        po_path = po_dir / rel.with_suffix(".po")
        po_path.parent.mkdir(parents=True, exist_ok=True)
        pot_file = polib.pofile(str(pot))
        po = polib.POFile()
        po.metadata = pot_file.metadata
        for entry in pot_file:
            po.append(polib.POEntry(msgid=entry.msgid, msgstr="[XX] " + entry.msgid, occurrences=entry.occurrences))
        po.save(str(po_path))
    return po_dir


# ===================== full-pipeline checks against the real fixtures =====================

def convert(work_dir, rst_path, po_dir, output):
    po_catalog = po_dir / pathlib.PurePosixPath(rst_path).with_suffix(".po")
    run_ok(
        [
            sys.executable, str(CONVERTER),
            "--source-root", str(FIXTURES),
            rst_path,
            str(po_catalog),
            "--language", "xx",
            "--output", str(output),
        ]
    )
    return output.read_text(encoding="utf-8")


def test_full_pipeline(work_dir: pathlib.Path, po_dir: pathlib.Path) -> dict:
    out_dir = work_dir / "converted"
    git_md = convert(work_dir, "development/git.rst", po_dir, out_dir / "git.md")
    testing_index_md = convert(work_dir, "testing/index.rst", po_dir, out_dir / "testing_index.md")
    unit_testing_md = convert(work_dir, "testing/unit_testing.rst", po_dir, out_dir / "unit_testing.md")
    db_types_md = convert(work_dir, "extensions/database_types_list.rst", po_dir, out_dir / "db_types.md")

    check("[XX] Git" in git_md.splitlines()[1], "front matter title carries the [XX] translation marker")
    check("weight: 1" in git_md, "front matter includes weight")

    # Angle-bracket regression: escaped in the raw Markdown, not dropped.
    check("&lt;category&gt;/&lt;user&gt;/&lt;name-or-id&gt;" in git_md,
          "angle-bracket placeholder text is HTML-escaped in prose, not lost")
    # ...but literal/code content must stay unescaped (context-aware, not blanket).
    check("`git clone git://github.com/<my_github_name>/phpbb.git`" in git_md,
          "angle brackets inside inline code stay literal (unescaped)")

    # block_quote + literal_block: every code line carries the blockquote prefix.
    check("> ```" in git_md and "> git pull upstream master" in git_md,
          "block_quote-nested code fence lines all carry the '> ' prefix")

    # Toctree suppression: the raw converted Markdown for testing/index.rst
    # must not contain any of the toctree-only navigation text/links.
    check("Running Unit Tests" not in testing_index_md,
          "toctree-generated subsection links are absent from testing/index's own converted output")

    # Cross-file internal reference: resolved to a real relref shortcode
    # pointing at testing/index's own docname, not a bare/broken path.
    check('{{< relref "development/testing/index" >}}' in git_md,
          "the :doc: reference to ../testing/index resolves to a real cross-file relref target")
    check("[UNRESOLVED LINK" not in git_md,
          "no internal reference in git.rst is reported unresolved")

    # Headerless csv-table (Commands: Pull/Commit/Push/Sync) promotes its
    # first row to a header and keeps the right column count. (The cell
    # text itself is "**Pull**" verbatim, not re-rendered bold: Sphinx's
    # own translation-merge only reparses RST markup when a translated
    # paragraph mixes plain and marked-up text, not when the whole
    # paragraph is a single marked-up word -- confirmed against real
    # Sphinx output, not a bug in this converter's own table handling.)
    check(re.search(r"\|[^|]*Pull[^|]*\|[^|]*Grab the updates from upstream[^|]*\|", git_md) is not None,
          "the headerless csv-table's first row becomes a valid 2-column Markdown table row")

    # A real :header-rows: table keeps its own header and column count (3).
    check(re.search(r"\|[^|]*Command[^|]*\|[^|]*MySQL Equivalent[^|]*\|[^|]*Storage Range", db_types_md) is not None,
          "the list-table's real header row survives with all 3 columns")

    check("[UNSUPPORTED:" not in git_md and "[UNSUPPORTED:" not in unit_testing_md and "[UNSUPPORTED:" not in db_types_md,
          "no element in any of the three real fixture files hits the unsupported-content catch-all")

    return {
        "git.md": git_md,
        "testing_index.md": testing_index_md,
        "unit_testing.md": unit_testing_md,
        "db_types.md": db_types_md,
        "out_dir": out_dir,
    }


# ===================== real Hugo build of the converted pages =====================

def test_hugo_build(work_dir: pathlib.Path, converted: dict) -> None:
    """Builds the converted pages with a real `hugo build`, reusing this
    project's actual site config/layouts/theme, and asserts on the real
    rendered HTML -- not just that Hugo exited 0. Snap-confined Hugo
    can't write outside $HOME-rooted paths, so this runs from a real
    temporary directory under $HOME (tempfile.mkdtemp with dir=home,
    always removed in the `finally` below), never under /tmp and never
    at a fixed path inside the repository -- a fixed in-repo path would
    both collide across concurrent runs and leave the tree dirty for
    anyone (including a read-only review) inspecting `git status` while
    a run was interrupted.
    """
    site_dir = pathlib.Path(tempfile.mkdtemp(prefix="phpbbdocs_hugo_test_", dir=str(pathlib.Path.home())))
    try:
        for item in ("config.toml", "layouts", "i18n", "static", "images"):
            src = REPO_ROOT / "site" / item
            if src.exists():
                if src.is_dir():
                    shutil.copytree(src, site_dir / item)
                else:
                    shutil.copy2(src, site_dir / item)

        content_root = site_dir / "content" / "en" / "development"
        pages = {
            "development/git": converted["git.md"],
            "testing/index": converted["testing_index.md"],
            "testing/unit_testing": converted["unit_testing.md"],
            "extensions/database_types_list": converted["db_types.md"],
        }
        # A synthetic page exercising two edge cases the three real
        # fixtures don't happen to contain: a block_quote-nested code
        # block with a BLANK line in the middle of the code (not just
        # multiple lines with content), and a nested bullet list --
        # both real bugs found and fixed in this XSLT, checked here
        # against real rendered HTML/DOM structure, not just the raw
        # Markdown text.
        edge_case_md, _ = run_xslt_snippet(
            '<section ids="s"><title>T</title>'
            '<block_quote><literal_block xml:space="preserve" language="default">'
            "line1\n\nline2</literal_block></block_quote>"
            '<bullet_list bullet="-"><list_item><paragraph>Parent</paragraph>'
            '<bullet_list bullet="-"><list_item><paragraph>Child</paragraph></list_item></bullet_list>'
            "</list_item></bullet_list>"
            "</section>"
        )
        pages["edge-cases/blank-line-and-nesting"] = edge_case_md

        for docname, md in pages.items():
            page_dir = content_root / docname
            page_dir.mkdir(parents=True, exist_ok=True)
            (page_dir / "index.md").write_text(md, encoding="utf-8")
        for section in ("", "development", "testing", "extensions", "edge-cases"):
            section_dir = content_root / section if section else content_root
            section_dir.mkdir(parents=True, exist_ok=True)
            (section_dir / "_index.md").write_text('---\ntitle: "Development"\n---\n', encoding="utf-8")

        public_dir = site_dir / "public"
        result = run_ok(["hugo", "--source", str(site_dir), "--destination", str(public_dir)])
        check(result.returncode == 0, "hugo build exits successfully against the converted pages")

        git_html = (public_dir / "en" / "development" / "development" / "git" / "index.html").read_text(encoding="utf-8")
        testing_index_html = (public_dir / "en" / "development" / "testing" / "index" / "index.html").read_text(encoding="utf-8")
        edge_case_html = (public_dir / "en" / "development" / "edge-cases" / "blank-line-and-nesting" / "index.html").read_text(encoding="utf-8")

        check("&lt;category&gt;/&lt;user&gt;/&lt;name-or-id&gt;" in git_html,
              "angle-bracket placeholder renders literally in the built HTML, not silently dropped by Goldmark")

        m = re.search(r'<a href="([^"]*)">Testing</a>', git_html)
        check(m is not None and "/en/development/testing/index/" in m.group(1),
              "the resolved cross-file relref becomes a real, correct href in the built HTML")

        check("git pull upstream master" in git_html and "<blockquote>" in git_html,
              "the block_quote-nested code block survives the real Markdown round-trip inside a <blockquote>")

        check("Running Unit Tests" not in testing_index_html,
              "no toctree-derived link/text leaks into testing/index's own rendered HTML")

        # Stable heading anchor: the [XX]-translated "Basics" heading's
        # real id in the built HTML must be the ORIGINAL Sphinx id
        # ("basics"), not Goldmark's auto-slug of the translated text
        # ("xx-basics") -- and the same-document reference to it must
        # use that same id, so the link actually resolves.
        m = re.search(r'<h2 id="([^"]+)">\[XX\] Basics', git_html)
        check(m is not None and m.group(1) == "basics",
              "a translated heading keeps its original, stable Sphinx id in the rendered HTML")
        check(re.search(r'<a href="[^"]*#basics">', git_html) is not None,
              "the same-document reference to that heading points at the stable id")

        # Blank-line-in-blockquote DOM containment: real rendered HTML,
        # not just Markdown text -- "line1" and "line2" (either side of
        # the blank line in the source) must both be inside the SAME
        # <blockquote><pre><code> subtree, not two separate blockquotes
        # split apart by the blank line breaking the quote.
        bq_match = re.search(r"<blockquote>.*?</blockquote>", edge_case_html, re.DOTALL)
        check(
            bq_match is not None and "line1" in bq_match.group(0) and "line2" in bq_match.group(0),
            "a blank line inside a quoted code block stays inside one contiguous <blockquote>, not split into two",
        )

        # Nested list structure: real rendered HTML must show "Child"
        # as an actual descendant <li> of "Parent"'s <li> (a nested
        # <ul>), not two sibling top-level <li> elements.
        parent_li = re.search(r"<li>\s*<p>Parent</p>\s*<ul>.*?</ul>\s*</li>", edge_case_html, re.DOTALL)
        check(
            parent_li is not None and "Child" in parent_li.group(0),
            "a nested list item renders as a real descendant <li> under its parent, not a flat sibling",
        )
    finally:
        shutil.rmtree(site_dir, ignore_errors=True)


# ===================== targeted XSLT edge-case checks =====================

DOC_HEADER = (
    '<document xmlns:c="https://www.sphinx-doc.org/">'
)


def run_xslt_snippet(xml_body: str, **stringparams) -> str:
    with tempfile.NamedTemporaryFile("w", suffix=".xml", delete=False) as f:
        f.write(DOC_HEADER + xml_body + "</document>")
        xml_path = f.name
    try:
        cmd = ["xsltproc", "--nonet"]
        for key, value in stringparams.items():
            cmd += ["--stringparam", key, value]
        cmd += [str(XSL_PATH), xml_path]
        result = run_ok(cmd)
        return result.stdout, result.stderr
    finally:
        pathlib.Path(xml_path).unlink(missing_ok=True)


def test_backtick_in_inline_literal() -> None:
    out, _ = run_xslt_snippet(
        '<section ids="s"><title>T</title>'
        '<paragraph>See <literal>a`b</literal> here.</paragraph>'
        "</section>"
    )
    check("``a`b``" in out, "a backtick inside inline literal content gets a longer (double) backtick fence")


def test_triple_backtick_in_code_block() -> None:
    out, _ = run_xslt_snippet(
        '<section ids="s"><title>T</title>'
        '<literal_block xml:space="preserve" language="default">code```fence</literal_block>'
        "</section>"
    )
    check("````" in out and "code```fence" in out,
          "a triple-backtick run inside a code block gets a 4-backtick fence")


def test_pipe_in_table_cell() -> None:
    out, _ = run_xslt_snippet(
        '<section ids="s"><title>T</title>'
        '<table><tgroup cols="1"><colspec colwidth="1"/><tbody>'
        "<row><entry><paragraph>a|b</paragraph></entry></row>"
        "</tbody></tgroup></table>"
        "</section>"
    )
    check("a\\|b" in out, "a literal pipe inside a table cell is escaped to \\|")


def test_quote_in_title() -> None:
    out, _ = run_xslt_snippet('<section ids="s"><title>Say "Hi"</title></section>')
    check('title: "Say \\"Hi\\""' in out, "a literal double quote inside the page title is escaped in front matter")


def test_unsupported_element_is_loud() -> None:
    out, err = run_xslt_snippet(
        '<section ids="s"><title>T</title>'
        "<footnote><paragraph>orphan content</paragraph></footnote>"
        "</section>"
    )
    check("[UNSUPPORTED: footnote]" in out, "an unhandled element gets a visible inline diagnostic marker")
    check("orphan content" in out, "an unhandled element still recurses into its children best-effort")
    check("unsupported Sphinx XML element" in err and "footnote" in err,
          "an unhandled element triggers an xsl:message warning naming it")


def test_pipe_inside_inline_code_in_table_cell() -> None:
    out, _ = run_xslt_snippet(
        '<section ids="s"><title>T</title>'
        '<table><tgroup cols="1"><colspec colwidth="1"/><tbody>'
        "<row><entry><paragraph><literal>a|b</literal></paragraph></entry></row>"
        "</tbody></tgroup></table>"
        "</section>"
    )
    check("`a\\|b`" in out, "a literal pipe inside inline code within a table cell is also escaped (not bypassed)")


def test_nested_nonflat_internal_link_matches_hugo_slug_convention() -> None:
    out, _ = run_xslt_snippet(
        '<section ids="s"><title>T</title>'
        '<paragraph><reference internal="True" refuri="tools/index">Tools</reference></paragraph>'
        "</section>",
        **{"doc-dir": "migrations", "known-docnames": "migrations/tools/index"}
    )
    check('{{< relref "development/migrations/tools-index" >}}' in out,
          "a nested (more-than-one-level) internal link is flattened via hyphen, matching "
          "phpbbdocs_hugo_devdocs.sh's real chapter/slug convention, not left as a nested path")


def test_empty_refuri_is_diagnosed_not_silently_self_linked() -> None:
    out, err = run_xslt_snippet(
        '<section ids="s"><title>T</title>'
        '<paragraph><reference internal="True" refuri="">Missing</reference></paragraph>'
        "</section>"
    )
    check("[Missing](#)" not in out, "a genuinely empty internal refuri does not become a silent self-link to '#'")
    check("[UNRESOLVED LINK: empty refuri]" in out,
          "a genuinely empty internal refuri gets a visible diagnostic instead")
    check("empty refuri" in err, "a genuinely empty internal refuri triggers an xsl:message warning")


def test_absolute_rst_path_rejected() -> None:
    result = run(
        [
            sys.executable, str(CONVERTER),
            "--source-root", str(FIXTURES),
            "/etc/passwd", "/dev/null",
            "--language", "xx", "--output", "/tmp/should-not-be-written.md",
        ]
    )
    check(result.returncode != 0 and "must be relative" in result.stderr,
          "an absolute rst_path is rejected before any path is joined or written")


def test_traversal_rst_path_rejected() -> None:
    result = run(
        [
            sys.executable, str(CONVERTER),
            "--source-root", str(FIXTURES),
            "../../../../../../etc/passwd", "/dev/null",
            "--language", "xx", "--output", "/tmp/should-not-be-written.md",
        ]
    )
    check(result.returncode != 0 and "escapes --source-root" in result.stderr,
          "a relative rst_path that walks out of --source-root via '..' is rejected")


def test_sphinx_missing_reference_warning_is_surfaced() -> None:
    """A real Sphinx build succeeds (exit 0) even when a page contains a
    :doc: reference to a page that doesn't exist -- Sphinx just warns.
    Before the fix this regresses, that warning was captured and then
    discarded (the driver only printed subprocess output on a nonzero
    exit); run() now always prints stderr, so the warning must reach
    the CLI's own stderr on a real, successful, real Sphinx build.
    """
    with tempfile.TemporaryDirectory(prefix="missing_ref_fixture_") as tmp:
        source_root = pathlib.Path(tmp) / "src"
        source_root.mkdir()
        # sphinx-build always needs a master document (matching this
        # driver's synthesized conf.py, master_doc = "index") to exist
        # under the source root, even when only one other file is the
        # actual conversion target.
        (source_root / "index.rst").write_text("Index\n=====\n", encoding="utf-8")
        (source_root / "broken.rst").write_text(
            "Broken\n======\n\nSee :doc:`nonexistent-page` for details.\n", encoding="utf-8"
        )
        po_path = pathlib.Path(tmp) / "broken.po"
        po_path.write_text(
            'msgid "Broken"\nmsgstr "[XX] Broken"\n\n'
            'msgid "See :doc:`nonexistent-page` for details."\n'
            'msgstr "[XX] See :doc:`nonexistent-page` for details."\n',
            encoding="utf-8",
        )
        output_path = pathlib.Path(tmp) / "broken.md"
        result = run(
            [
                sys.executable, str(CONVERTER),
                "--source-root", str(source_root),
                "broken.rst", str(po_path),
                "--language", "xx", "--output", str(output_path),
            ]
        )
        check(result.returncode == 0, "a build with a real missing cross-reference still succeeds (Sphinx only warns)")
        check("nonexistent-page" in result.stderr,
              "the Sphinx missing-reference warning reaches the CLI's own stderr instead of being discarded")


def test_unsafe_language_rejected() -> None:
    result = run(
        [
            sys.executable, str(CONVERTER),
            "--source-root", str(FIXTURES),
            "development/git.rst", "/dev/null",
            "--language", "../evil", "--output", "/tmp/should-not-be-written.md",
        ]
    )
    check(result.returncode != 0 and "must contain only letters, digits" in result.stderr,
          "a --language value that isn't a safe path component is rejected")


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="sphinx_devdocs_test_") as tmp:
        work_dir = pathlib.Path(tmp)
        po_dir = build_synthetic_catalogs(work_dir)
        converted = test_full_pipeline(work_dir, po_dir)
        test_hugo_build(work_dir, converted)

    test_backtick_in_inline_literal()
    test_triple_backtick_in_code_block()
    test_pipe_in_table_cell()
    test_pipe_inside_inline_code_in_table_cell()
    test_quote_in_title()
    test_unsupported_element_is_loud()
    test_nested_nonflat_internal_link_matches_hugo_slug_convention()
    test_empty_refuri_is_diagnosed_not_silently_self_linked()
    test_absolute_rst_path_rejected()
    test_traversal_rst_path_rejected()
    test_unsafe_language_rejected()
    test_sphinx_missing_reference_warning_is_surfaced()

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
