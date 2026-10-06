#!/usr/bin/env python3
"""Real, assert-based test suite for build_search_index.sh.

No mocking, no pytest -- matches this repo's other test files. Runs the
real script, and so the real pinned Pagefind (a matching `pagefind`
binary on PATH, or npx), against a small hand-written built-site fixture
in a temp directory.

Covers: one bundle per language/section and none for images/ or for a
directory without its own index.html; Hugo language codes such as
de_x_sie indexed as their base language; stale bundle files removed;
stored result URLs rooted at the site (/<lang>/<section>/...); only
data-pagefind-body content indexed; and usage/exit codes for missing or
bad arguments.

Run directly: python3 tests/build_search_index/test_build_search_index.py
"""

import gzip
import json
import pathlib
import subprocess
import sys
import tempfile

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "build_search_index.sh"

FAILURES = []


def check(condition: bool, message: str) -> None:
    if condition:
        print("ok:", message)
    else:
        print("FAIL:", message)
        FAILURES.append(message)


def page(lang: str, body: str) -> str:
    """Return a minimal built Hugo page with nav text outside the body."""
    return (
        f'<!doctype html><html lang="{lang}"><head><title>T</title></head><body>'
        "<nav>sidebarnavigationword</nav>"
        f'<article data-pagefind-body><h1>Heading</h1><p>{body}</p></article>'
        "</body></html>"
    )


def write_fixture(root: pathlib.Path, files: dict) -> None:
    for rel, content in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


def fragments(bundle: pathlib.Path) -> list:
    """Decode every stored page fragment in a Pagefind bundle."""
    decoded = []
    for fragment in sorted((bundle / "fragment").glob("*.pf_fragment")):
        data = gzip.decompress(fragment.read_bytes())
        if data.startswith(b"pagefind_dcd"):
            data = data[len(b"pagefind_dcd"):]
        decoded.append(json.loads(data))
    return decoded


def run(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([str(SCRIPT), *args], capture_output=True, text=True, check=False)


def test_usage():
    result = run()
    check(result.returncode == 2, "no arguments exits 2")
    check("Usage:" in result.stdout, "no arguments prints usage")
    result = run("--help")
    check(result.returncode == 0 and "Usage:" in result.stdout, "--help prints usage and exits 0")
    result = run("/nonexistent/site/dir")
    check(result.returncode == 1, "missing site directory exits 1")


def test_bundles():
    with tempfile.TemporaryDirectory(prefix="search_index_test_") as tmp:
        root = pathlib.Path(tmp)
        write_fixture(
            root,
            {
                "index.html": page("en", "root"),
                "en/index.html": page("en", "overview"),
                "en/guide/index.html": page("en", "guide section"),
                "en/guide/install/index.html": page("en", "installation uniqueenglishword"),
                "en/images/index.html": page("en", "should not be indexed"),
                "en/notasection/page.html": page("en", "no section index"),
                "en/guide/pagefind/stale.txt": "left over from an earlier build",
                "de_x_sie/index.html": page("de-x-sie", "Übersicht"),
                "de_x_sie/guide/index.html": page("de-x-sie", "Anleitung"),
                "de_x_sie/guide/berechtigungen/index.html": page("de-x-sie", "Berechtigungen setzen"),
            },
        )

        result = run(str(root))
        check(result.returncode == 0, f"indexes the fixture site (stderr: {result.stderr.strip()})")

        en_bundle = root / "en/guide/pagefind"
        de_bundle = root / "de_x_sie/guide/pagefind"
        check((en_bundle / "pagefind.js").is_file(), "writes en/guide bundle")
        check((de_bundle / "pagefind.js").is_file(), "writes de_x_sie/guide bundle")
        check(not (root / "en/images/pagefind").exists(), "skips images/")
        check(not (root / "en/notasection/pagefind").exists(), "skips a directory without index.html")
        check(not (root / "pagefind").exists() and not (root / "en/pagefind").exists(),
              "writes no site-wide or language-wide bundle")
        check(not (en_bundle / "stale.txt").exists(), "removes stale bundle files")
        check(any(de_bundle.glob("pagefind.de_*.pf_meta")), "indexes de_x_sie as de")

        en_pages = fragments(en_bundle)
        urls = sorted(fragment["url"] for fragment in en_pages)
        check(urls == ["/en/guide/", "/en/guide/install/"], f"stores site-rooted URLs ({urls})")
        content = " ".join(fragment["content"] for fragment in en_pages)
        check("uniqueenglishword" in content, "indexes data-pagefind-body content")
        check("sidebarnavigationword" not in content, "ignores content outside data-pagefind-body")
        check("Übersicht" not in " ".join(f["content"] for f in fragments(de_bundle)),
              "leaves the language overview page out of section bundles")


if __name__ == "__main__":
    test_usage()
    test_bundles()
    if FAILURES:
        print(f"\n{len(FAILURES)} failure(s)")
        sys.exit(1)
    print("\nall checks passed")
