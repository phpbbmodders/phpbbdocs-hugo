#!/usr/bin/env python3
"""Converts one localized Sphinx/RST developer-docs page to Hugo Markdown.

Given one .rst file under a Sphinx source tree and an already-translated
.po catalog for it (produced separately -- extracting/updating that
catalog is out of scope here, matching translations.sh's DocBook-side
extract/update subcommands, which this pipeline has no development-family
equivalent of yet), this compiles the catalog, runs a real Sphinx build to
get Docutils XML with the translated strings substituted in, and
transforms that XML into a Hugo-ready Markdown page via
xsl/proteus_sphinx_hugo.xsl.

Every build intermediate (the synthesized conf.py, the compiled .mo
catalog, the localized XML, Sphinx's .doctrees cache) lives under a
tempfile.mkdtemp()-style temporary directory that is removed when this
script exits -- nothing is ever written into --source-root or the
current working directory.

The synthesized conf.py deliberately does not reuse a project's own
conf.py (real upstream phpBB dev-docs content ships one at
development/conf.py): that file declares extensions
(sensio.sphinx.refinclude, sphinxcontrib.phpdomain, sphinx_multiversion,
sphinx_rtd_theme) that are not installed in every environment this script
needs to run in and, confirmed by grepping all 55 real upstream .rst
files for every role/directive those extensions provide, are not
actually used by any current content -- see
docs/TODO/todo-sphinx-devdocs-spike.md for that verification. Revisit
only if future upstream content actually starts using PHP-domain roles.

Before pointing this at real upstream content beyond the test fixtures,
run fix_csv_table_headers.py (repo root) against a disposable copy of
the source tree first: several real upstream .rst files use a
headerless csv-table with a custom :delim: line in a way Sphinx's
parser rejects outright (a Pandoc-specific tolerance the existing
DocBook pipeline doesn't need to work around) -- see
docs/TODO/todo-sphinx-devdocs-spike.md for the confirmed file list.
This script does not run that fix itself, since it operates on
whatever --source-root already contains rather than assuming any
particular preparation step happened first.
"""

import argparse
import pathlib
import posixpath
import re
import subprocess
import sys
import tempfile

# A single safe path component: letters, digits, underscore, hyphen --
# matching translations.sh's own language-code validation
# (`case "$lang" in *[!A-Za-z0-9_-]*|'')`) for consistency across this
# project's tooling, and specifically excluding "/" and "." so this
# can never be combined with another path segment to escape a
# directory it's joined under.
_SAFE_LANGUAGE_RE = re.compile(r"^[A-Za-z0-9_-]+$")

CONF_PY = '''"""Minimal Sphinx configuration synthesized by sphinx_to_hugo.py.

See that script's own module docstring for why this doesn't reuse a
source tree's own conf.py.
"""

extensions = []
smartquotes = False
master_doc = "index"
exclude_patterns = ["_build"]

# One .po/.mo catalog per source file, matching this script's
# one-RST-file-to-one-catalog contract, instead of Sphinx's default of
# grouping catalogs by top-level directory.
gettext_compact = False
'''


def discover_known_docnames(source_root: pathlib.Path) -> list:
    """Every RST file under source_root, as a source-root-relative docname
    (posix path, no .rst extension) -- the set of valid internal-link
    targets the XSLT transform will resolve :doc:/:ref: references against.
    """
    return sorted(
        rst.relative_to(source_root).with_suffix("").as_posix()
        for rst in source_root.rglob("*.rst")
    )


def run(cmd: list) -> subprocess.CompletedProcess:
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(
            "command failed: {}\n--- stdout ---\n{}\n--- stderr ---\n{}".format(
                " ".join(cmd), result.stdout, result.stderr
            )
        )
    # A zero exit status does not mean sphinx-build (or any other tool
    # run here) had nothing to say -- a missing-reference warning, for
    # instance, is emitted on stderr without failing the build. Surface
    # it rather than discarding it: the XSLT's own diagnostics can only
    # warn about a reference it actually receives, not one Sphinx
    # already silently degraded before the stylesheet ever saw it.
    if result.stderr.strip():
        print(result.stderr, file=sys.stderr)
    return result


def convert(
    source_root: pathlib.Path,
    rst_path: pathlib.PurePosixPath,
    po_catalog: pathlib.Path,
    language: str,
    output: pathlib.Path,
    weight: str,
    translation_key: str,
    hugo_section: str,
) -> None:
    docname = rst_path.with_suffix("").as_posix()
    doc_dir = posixpath.dirname(docname)
    known_docnames = discover_known_docnames(source_root)
    xsl_path = pathlib.Path(__file__).resolve().parent.parent / "xsl" / "proteus_sphinx_hugo.xsl"

    with tempfile.TemporaryDirectory(prefix="sphinx_to_hugo_") as tmp:
        tmp_path = pathlib.Path(tmp)

        conf_dir = tmp_path / "conf"
        conf_dir.mkdir()
        (conf_dir / "conf.py").write_text(CONF_PY, encoding="utf-8")

        locale_root = tmp_path / "locale"
        mo_path = locale_root / language / "LC_MESSAGES" / rst_path.with_suffix(".mo")
        mo_path.parent.mkdir(parents=True)
        run(["msgfmt", str(po_catalog), "-o", str(mo_path)])

        xml_dir = tmp_path / "xml"
        doctrees_dir = tmp_path / "doctrees"
        run(
            [
                "sphinx-build",
                "-b",
                "xml",
                "-q",
                "-c",
                str(conf_dir),
                "-D",
                "language={}".format(language),
                "-D",
                "locale_dirs={}".format(locale_root),
                "-d",
                str(doctrees_dir),
                str(source_root),
                str(xml_dir),
                str(source_root / rst_path),
            ]
        )

        xml_file = xml_dir / rst_path.with_suffix(".xml")
        if not xml_file.is_file():
            raise RuntimeError(
                "expected Sphinx XML output not found: {} "
                "(sphinx-build produced no output for {})".format(xml_file, rst_path)
            )

        output.parent.mkdir(parents=True, exist_ok=True)
        run(
            [
                "xsltproc",
                "--nonet",
                "--stringparam",
                "page.weight",
                weight,
                "--stringparam",
                "page.translationKey",
                translation_key,
                "--stringparam",
                "doc-dir",
                doc_dir,
                "--stringparam",
                "known-docnames",
                " ".join(known_docnames),
                "--stringparam",
                "hugo-section",
                hugo_section,
                "--output",
                str(output),
                str(xsl_path),
                str(xml_file),
            ]
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert one localized Sphinx/RST dev-docs page to a Hugo Markdown page."
    )
    parser.add_argument(
        "--source-root",
        required=True,
        type=pathlib.Path,
        help="Root directory of the Sphinx/RST source tree (e.g. the upstream development/ checkout).",
    )
    parser.add_argument(
        "rst_path",
        type=pathlib.Path,
        help="Path to the .rst file to convert, relative to --source-root.",
    )
    parser.add_argument(
        "po_catalog",
        type=pathlib.Path,
        help="Path to the already-translated .po catalog for this file.",
    )
    parser.add_argument(
        "--language",
        required=True,
        help="Target language code, matching the catalog's own language (e.g. 'de', 'fr').",
    )
    parser.add_argument(
        "--output",
        required=True,
        type=pathlib.Path,
        help="Path to write the generated Hugo Markdown page to.",
    )
    parser.add_argument(
        "--weight",
        default="1",
        help="Hugo front-matter 'weight' value for this page (default: 1).",
    )
    parser.add_argument(
        "--translation-key",
        default="",
        help="Hugo front-matter 'translationKey' value (default: omitted from front matter).",
    )
    parser.add_argument(
        "--hugo-section",
        default="development",
        help=(
            "Hugo content section a resolved internal link is published under, "
            "matching phpbbdocs_hugo_devdocs.sh's own content/<lang>/<section>/<chapter>/<slug>/ "
            "convention (default: 'development'; pass '' to emit a bare docname with no section prefix)."
        ),
    )
    args = parser.parse_args()

    # rst_path must be relative and stay inside --source-root: joining
    # source_root / an ABSOLUTE rst_path silently discards source_root
    # entirely (a pathlib join with an absolute right-hand side drops
    # the left side), and a relative path with enough ".." segments can
    # walk back out of source_root even without being absolute --
    # either way, every path this script later derives from rst_path
    # (most importantly the compiled .mo catalog's path) would then
    # land outside the temp directory, contradicting this script's own
    # "nothing is ever written outside the temp directory" contract.
    # Rejecting both cases up front, before any path is joined or
    # written to, is simpler and more robust than trying to re-validate
    # every path derived from rst_path afterward.
    if args.rst_path.is_absolute():
        sys.exit("rst_path must be relative to --source-root, got an absolute path: {}".format(args.rst_path))
    if not _SAFE_LANGUAGE_RE.match(args.language):
        sys.exit(
            "--language must contain only letters, digits, '_' and '-' (got {!r}) -- "
            "it becomes a path component under the temp locale directory".format(args.language)
        )

    source_root = args.source_root.resolve()
    if not source_root.is_dir():
        sys.exit("--source-root not found or not a directory: {}".format(source_root))
    rst_file = (source_root / args.rst_path).resolve()
    if not rst_file.is_relative_to(source_root):
        sys.exit(
            "rst_path escapes --source-root via '..' segments: {} resolves to {}, "
            "which is not inside {}".format(args.rst_path, rst_file, source_root)
        )
    if not rst_file.is_file():
        sys.exit("RST file not found under source root: {}".format(rst_file))
    if not args.po_catalog.is_file():
        sys.exit("PO catalog not found: {}".format(args.po_catalog))
    output_resolved = args.output.resolve() if args.output.exists() else None
    for existing_input, label in ((rst_file, "the source RST file"), (args.po_catalog.resolve(), "the PO catalog")):
        if output_resolved is not None and output_resolved == existing_input:
            sys.exit("--output must not overwrite {}: {}".format(label, args.output))

    rst_posix_path = pathlib.PurePosixPath(args.rst_path.as_posix())

    try:
        convert(
            source_root=source_root,
            rst_path=rst_posix_path,
            po_catalog=args.po_catalog,
            language=args.language,
            output=args.output,
            weight=args.weight,
            translation_key=args.translation_key,
            hugo_section=args.hugo_section,
        )
    except RuntimeError as exc:
        sys.exit(str(exc))


if __name__ == "__main__":
    main()
