#!/usr/bin/env python3
"""Real, assert-based test for the per-section search-index.json output.

No mocking, no pytest -- matches this repo's other test files. Copies the
real site config, layouts and i18n into a temp directory, adds a small
hand-written content tree, runs the real `hugo`, and checks the JSON
files the phpBB Documentation extension reads for visitors without
JavaScript.

Covers: one index per top-level section and language; every page of the
section (its own index, nested sections and regular pages) present with
a site-rooted URL, title and plain text; nested sections writing an empty
list; no site-wide or language-wide index.

Run directly: python3 tests/search_index_json/test_search_index_json.py
"""

import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
SITE = REPO_ROOT / "site"

FAILURES = []


def check(condition: bool, message: str) -> None:
    if condition:
        print("ok:", message)
    else:
        print("FAIL:", message)
        FAILURES.append(message)


def write(root: pathlib.Path, rel: str, title: str, body: str) -> None:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f'---\ntitle: "{title}"\n---\n\n{body}\n', encoding="utf-8")


def test_search_index():
    if shutil.which("hugo") is None:
        check(False, "hugo is on PATH")
        return

    # Under the repo's ignored build/ rather than /tmp: a snap-packaged
    # hugo can't read the system temp directory.
    scratch = REPO_ROOT / "build"
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="search_index_json_test_", dir=scratch) as tmp:
        site = pathlib.Path(tmp) / "site"
        site.mkdir()
        shutil.copy(SITE / "config.toml", site / "config.toml")
        shutil.copytree(SITE / "layouts", site / "layouts")
        shutil.copytree(SITE / "i18n", site / "i18n")
        content = site / "content"
        for lang in ("en", "de_x_sie"):
            write(content, f"{lang}/_index.md", "Home", "overview")
            write(content, f"{lang}/guide/_index.md", "Guide", "guide section")
            write(content, f"{lang}/guide/install.md", "Install", f"installation {lang}uniqueword")
            write(content, f"{lang}/guide/advanced/_index.md", "Advanced", "nested section")
            write(content, f"{lang}/guide/advanced/tuning.md", "Tuning", "nested page")

        public = pathlib.Path(tmp) / "public"
        result = subprocess.run(
            ["hugo", "--quiet", "--source", str(site), "--destination", str(public)],
            capture_output=True, text=True, check=False,
        )
        check(result.returncode == 0, f"hugo builds the fixture (stderr: {result.stderr.strip()})")

        for lang in ("en", "de_x_sie"):
            index = public / lang / "guide/search-index.json"
            check(index.is_file(), f"writes {lang}/guide/search-index.json")
            if not index.is_file():
                continue
            pages = json.loads(index.read_text(encoding="utf-8"))
            urls = sorted(page["url"] for page in pages)
            expected = sorted(f"/{lang}/guide/{rel}" for rel in ("", "install/", "advanced/", "advanced/tuning/"))
            check(urls == expected, f"{lang} index lists every page of the section ({urls})")
            install = next((page for page in pages if page["url"].endswith("/install/")), {})
            check(install.get("title") == "Install", f"{lang} index keeps page titles")
            check(f"{lang}uniqueword" in install.get("text", ""), f"{lang} index keeps plain page text")

            nested = public / lang / "guide/advanced/search-index.json"
            check(nested.is_file() and json.loads(nested.read_text()) == [],
                  f"{lang} nested section writes an empty list")
            check(not (public / lang / "search-index.json").exists(), f"{lang} has no language-wide index")

        check(not (public / "search-index.json").exists(), "no site-wide index")


if __name__ == "__main__":
    test_search_index()
    if FAILURES:
        print(f"\n{len(FAILURES)} failure(s)")
        sys.exit(1)
    print("\nall checks passed")
