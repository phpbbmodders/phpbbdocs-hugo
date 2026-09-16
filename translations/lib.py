"""Shared helpers for translations.sh: config loading, language metadata,
and PO status reporting. Extraction/merging itself is done by itstool and
standard gettext tools (msgmerge, msgcat) invoked from translations.sh —
this module intentionally doesn't reimplement that.
"""
import os
import re
import sys
import json
import subprocess
from pathlib import Path

import polib
import toml

DOCBOOK_CHAPTERS = [
    "admin_guide",
    "user_guide",
    "moderator_guide",
    "quick_start_guide",
    "upgrade_guide",
    "server_guide",
    "glossary",
]

HUGO_ROOT = Path(__file__).resolve().parent.parent

# The "development" family's real, separate upstream checkout (a real
# sparse-cloned phpbb/documentation repo, unlike the "documentation"
# family's English source, which is hand-authored directly in this repo
# with no upstream checkout of its own -- see current_hugo_commit() vs
# current_devdocs_commit() below). DEVDOCS_UPSTREAM_CHECKOUT env var
# overrides, mirroring translations.sh's own override of the same name
# for its devdocs_checkout_dir -- mainly so tests can point both the
# bash and Python sides at the same small local checkout consistently.
DEVDOCS_UPSTREAM_CHECKOUT = Path(os.environ.get("DEVDOCS_UPSTREAM_CHECKOUT", str(HUGO_ROOT / "upstream-phpbb-documentation")))
DEVDOCS_SOURCE_SUBDIR = "development"
DEVDOCS_BUILD_DIR = HUGO_ROOT / "build" / "gettext" / "development"


def load_translation_conf():
    """Resolve LANGUAGES_REPO: env var override, else translation.conf,
    relative to the phpbbdocs-hugo repo root either way."""
    env_override = os.environ.get("LANGUAGES_REPO")
    if env_override:
        return Path(env_override).resolve()

    conf_path = HUGO_ROOT / "translation.conf"
    if not conf_path.exists():
        print(f"error: {conf_path} not found and LANGUAGES_REPO not set", file=sys.stderr)
        sys.exit(1)

    value = None
    for line in conf_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("LANGUAGES_REPO="):
            value = line.split("=", 1)[1].strip()
            break
    if value is None:
        print(f"error: LANGUAGES_REPO not set in {conf_path}", file=sys.stderr)
        sys.exit(1)

    return (HUGO_ROOT / value).resolve()


LANG_CODE_RE = re.compile(r"^[a-z]{2,3}(-[a-z0-9]+)*(_x_[a-z]+)?$")


def validate_lang_code(code):
    """phpBB ISO codes: lowercase, hyphen-separated, with an occasional
    '_x_<variant>' private-use suffix (e.g. de_x_sie). Doesn't check
    against phpBB's actual code list — just rejects obviously malformed
    input before it becomes a directory name."""
    if not LANG_CODE_RE.match(code):
        print(
            f"error: {code!r} doesn't look like a phpBB language code "
            "(expected lowercase, e.g. 'fr', 'de_x_sie', 'es-x-tu')",
            file=sys.stderr,
        )
        sys.exit(1)
    return code


def lang_dir(languages_repo, lang):
    return languages_repo / lang


def language_toml_path(languages_repo, lang):
    return lang_dir(languages_repo, lang) / "language.toml"


def read_language_toml(languages_repo, lang):
    path = language_toml_path(languages_repo, lang)
    if not path.exists():
        return None
    return toml.load(path)


def write_language_toml(languages_repo, lang, name, native_name, locale, status="active"):
    path = language_toml_path(languages_repo, lang)
    path.parent.mkdir(parents=True, exist_ok=True)
    data = {
        "code": lang,
        "name": name,
        "native_name": native_name,
        "locale": locale,
        "status": status,
    }
    with open(path, "w", encoding="utf-8") as f:
        toml.dump(data, f)
    return path


def source_json_path(languages_repo):
    return languages_repo / "metadata" / "source.json"


def migrate_upstream_metadata(data):
    """Upgrades a legacy flat "upstream": {"repository": ..., "branch": ...}
    object (written before the "development" family existed, when there
    was only ever one family to record an upstream label for) into the
    per-family shape {"documentation": {"repository": ..., "branch": ...}}
    -- "development" has a genuinely different, real external upstream
    (an actual sparse-cloned checkout) from "documentation"'s label-only
    entry, so a single flat object can no longer represent both.
    Idempotent: does nothing if "upstream" is already per-family shaped
    or empty/absent. Mutates and returns data in place so callers can
    treat this as a normalizing pass over whatever was just read."""
    upstream = data.get("upstream")
    if upstream and "repository" in upstream and "branch" in upstream:
        data["upstream"] = {"documentation": dict(upstream)}
    return data


def read_source_metadata(languages_repo):
    path = source_json_path(languages_repo)
    if not path.exists():
        return {"upstream": {}, "languages": {}}
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return migrate_upstream_metadata(data)


def write_source_metadata(languages_repo, data):
    path = source_json_path(languages_repo)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)
        f.write("\n")


def current_hugo_commit():
    """The commit of content/en/chapters/*.xml as tracked in this repo
    (the DocBook end-user docs are hand-authored directly in this repo,
    not pulled from a separate upstream checkout the way the Sphinx-based
    dev-docs are) — used as the 'documentation' family's source revision."""
    result = subprocess.run(
        ["git", "-C", str(HUGO_ROOT), "log", "-1", "--format=%H", "--",
         "content/en/chapters"],
        capture_output=True, text=True, check=True,
    )
    return result.stdout.strip()


def current_devdocs_commit():
    """The commit upstream-phpbb-documentation/ was last pulled from --
    a real external phpbb/documentation commit, unlike
    current_hugo_commit(), which reads THIS repo's own history because
    the documentation family's English source has no separate upstream
    checkout of its own. Used as the 'development' family's source
    revision."""
    checkout = DEVDOCS_UPSTREAM_CHECKOUT
    if not (checkout / ".git").is_dir():
        print(
            f"error: {checkout} not found -- run "
            "'./translations.sh devdocs-extract' first",
            file=sys.stderr,
        )
        sys.exit(1)
    result = subprocess.run(
        ["git", "-C", str(checkout), "log", "-1", "--format=%H", "--", DEVDOCS_SOURCE_SUBDIR],
        capture_output=True, text=True, check=True,
    )
    return result.stdout.strip()


def write_devdocs_conf_py(conf_dir):
    """Writes sphinx_to_hugo.py's own synthesized minimal Sphinx conf.py
    verbatim into conf_dir -- reused rather than a second, driftable
    copy of that string, so POT extraction (this module) and per-file
    conversion (sphinx_to_hugo.py) parse the same RST under identical
    Sphinx settings."""
    import sphinx_to_hugo

    conf_dir = Path(conf_dir)
    conf_dir.mkdir(parents=True, exist_ok=True)
    (conf_dir / "conf.py").write_text(sphinx_to_hugo.CONF_PY, encoding="utf-8")


def devdocs_discover_docnames(source_root):
    """Every known dev-docs docname under source_root -- delegates to
    sphinx_to_hugo's own discovery function rather than reimplementing
    the same rglob("*.rst") logic a second time, so this module and the
    converter always agree on what counts as a docname."""
    import sphinx_to_hugo

    return sphinx_to_hugo.discover_known_docnames(Path(source_root))


def devdocs_po_path(languages_repo, lang, docname):
    """docname may itself contain "/" (e.g. "migrations/tools/config")
    -- Path handles the extra segments with no special-casing, mirroring
    the RST tree exactly rather than flattening it (see translations.sh's
    devdocs-* commands for why: avoids importing Hugo's own
    chapter/slug-flattening collision history into canonical PO
    storage)."""
    return lang_dir(languages_repo, lang) / "development" / f"{docname}.po"


def devdocs_pot_path(docname):
    return DEVDOCS_BUILD_DIR / f"{docname}.pot"


def devdocs_source_path(source_root, docname):
    return Path(source_root) / f"{docname}.rst"


def po_stats(po_path):
    """Return (translated, fuzzy, untranslated, obsolete) counts for a
    PO file. Matches gettext's own conventions: an obsolete entry
    (#~) is never counted as translated/fuzzy/untranslated."""
    po = polib.pofile(str(po_path))
    translated = len(po.translated_entries())
    fuzzy = len(po.fuzzy_entries())
    untranslated = len(po.untranslated_entries())
    obsolete = len(po.obsolete_entries())
    return translated, fuzzy, untranslated, obsolete


def docbook_po_path(languages_repo, lang, chapter):
    return lang_dir(languages_repo, lang) / "documentation" / f"{chapter}.po"


def docbook_source_path(chapter):
    return HUGO_ROOT / "content" / "en" / "chapters" / f"{chapter}.xml"


UPSTREAM_DEFAULTS = {
    "documentation": {"repository": "phpbb/documentation", "branch": "3.3.x"},
    "development": {"repository": "phpbb/documentation", "branch": "3.3.x", "path": "development"},
}


if __name__ == "__main__":
    # Minimal CLI so translations.sh can call into this module for the
    # pieces that are awkward in bash (TOML/JSON writing, PO stats)
    # without needing a second interpreter's worth of glue for every call.
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)

    p = sub.add_parser("validate-lang", help="Validate a phpBB language code")
    p.add_argument("lang", help="Language code to validate, e.g. fr")

    p = sub.add_parser("write-language-toml", help="Create/overwrite <lang>/language.toml")
    p.add_argument("lang", help="Language code")
    p.add_argument("--name", required=True, help="English name, e.g. French")
    p.add_argument("--native-name", required=True, help="Native name, e.g. Français")
    p.add_argument("--locale", required=True, help="Locale tag, e.g. fr_FR")

    p = sub.add_parser("po-stats", help="Print translated/fuzzy/untranslated/obsolete counts for a PO file")
    p.add_argument("po_path", help="Path to the .po file")

    p = sub.add_parser("record-source", help="Record the resolved source commit for a language/family after a successful update")
    p.add_argument("lang", help="Language code")
    p.add_argument("family", choices=["documentation", "development"], help="Source family")
    p.add_argument("commit", help="Resolved commit hash")

    p = sub.add_parser("read-source", help="Print the recorded source commit for a language/family, or 'unknown'")
    p.add_argument("lang", help="Language code")
    p.add_argument("family", choices=["documentation", "development"], help="Source family")

    p = sub.add_parser("list-devdocs-docnames", help="Print every known dev-docs docname under a source root, one per line")
    p.add_argument("source_root", help="Root of the Sphinx/RST dev-docs source tree")

    p = sub.add_parser("extract-devdocs-pot", help="Extract POT templates for every dev-docs file into build_dir")
    p.add_argument("source_root", help="Root of the Sphinx/RST dev-docs source tree")
    p.add_argument("build_dir", help="Directory to write extracted .pot files into")

    p = sub.add_parser("current-devdocs-commit", help="Print the commit upstream-phpbb-documentation/ was last pulled from")

    args = parser.parse_args()
    languages_repo = load_translation_conf()

    if args.action == "validate-lang":
        validate_lang_code(args.lang)
        print(args.lang)

    elif args.action == "write-language-toml":
        path = write_language_toml(languages_repo, args.lang, args.name, args.native_name, args.locale)
        print(f"wrote {path}")

    elif args.action == "po-stats":
        translated, fuzzy, untranslated, obsolete = po_stats(args.po_path)
        print(f"{translated} {fuzzy} {untranslated} {obsolete}")

    elif args.action == "record-source":
        data = read_source_metadata(languages_repo)
        # setdefault() only fires when the key is absent, not when it's
        # present-but-empty (e.g. a source.json written before this
        # default existed, which persisted "upstream": {}) -- check for
        # that explicitly so the default actually lands. migrate_upstream_metadata()
        # (already applied by read_source_metadata() above) has already
        # upgraded a legacy flat upstream object to the per-family shape,
        # so this only needs to fill in whichever family is still missing.
        data.setdefault("upstream", {})
        data["upstream"].setdefault(args.family, dict(UPSTREAM_DEFAULTS[args.family]))
        data.setdefault("languages", {})
        data["languages"].setdefault(args.lang, {})
        data["languages"][args.lang][args.family] = {"commit": args.commit}
        write_source_metadata(languages_repo, data)
        print(f"recorded {args.lang}/{args.family} = {args.commit}")

    elif args.action == "read-source":
        data = read_source_metadata(languages_repo)
        commit = data.get("languages", {}).get(args.lang, {}).get(args.family, {}).get("commit")
        print(commit or "unknown")

    elif args.action == "list-devdocs-docnames":
        for docname in devdocs_discover_docnames(args.source_root):
            print(docname)

    elif args.action == "extract-devdocs-pot":
        import tempfile

        build_dir = Path(args.build_dir)
        build_dir.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="devdocs_extract_") as tmp:
            tmp_path = Path(tmp)
            conf_dir_obj = tmp_path / "conf"
            write_devdocs_conf_py(conf_dir_obj)
            doctrees_dir = tmp_path / "doctrees"
            result = subprocess.run(
                [
                    "sphinx-build", "-b", "gettext", "-q",
                    "-c", str(conf_dir_obj),
                    "-d", str(doctrees_dir),
                    str(args.source_root), str(build_dir),
                ],
                capture_output=True, text=True,
            )
        if result.stderr.strip():
            print(result.stderr, file=sys.stderr)
        if result.returncode != 0:
            sys.exit(f"sphinx-build failed (exit {result.returncode})")
        pot_count = len(list(build_dir.rglob("*.pot")))
        print(f"extracted {pot_count} .pot file(s) into {build_dir}")

    elif args.action == "current-devdocs-commit":
        print(current_devdocs_commit())
