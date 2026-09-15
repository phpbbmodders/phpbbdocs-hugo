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


def read_source_metadata(languages_repo):
    path = source_json_path(languages_repo)
    if not path.exists():
        return {"upstream": {}, "languages": {}}
    with open(path, encoding="utf-8") as f:
        return json.load(f)


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
        # that explicitly so the default actually lands.
        if not data.get("upstream"):
            data["upstream"] = {"repository": "phpbb/documentation", "branch": "3.3.x"}
        data.setdefault("languages", {})
        data["languages"].setdefault(args.lang, {})
        data["languages"][args.lang][args.family] = {"commit": args.commit}
        write_source_metadata(languages_repo, data)
        print(f"recorded {args.lang}/{args.family} = {args.commit}")

    elif args.action == "read-source":
        data = read_source_metadata(languages_repo)
        commit = data.get("languages", {}).get(args.lang, {}).get(args.family, {}).get("commit")
        print(commit or "unknown")
