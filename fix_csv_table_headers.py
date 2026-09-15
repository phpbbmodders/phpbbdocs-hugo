#!/usr/bin/env python3
"""Fix a real content-loss bug in upstream phpBB developer-docs RST
source: a `.. csv-table::` directive that sets a custom `:delim:` (e.g.
`|` or `#`) for its data rows, but whose `:header:` line keeps the
default comma-and-quotes CSV syntax instead of matching that same
delimiter.

docutils' csv-table parser applies `:delim:` to the whole directive,
header line included, so the header fails to parse and the parser
aborts the entire table -- silently dropping all of its content. The
current Pandoc-based dev-docs pipeline tolerates this (renders the table
fine regardless), which is exactly why it went unnoticed; Sphinx's own
csv-table parser does not (see docs/TODO/todo-sphinx-devdocs-spike.md
and docs/phpbb-gettext-translation-poc-results.md, "Tables" and
Follow-up items, for the full writeup and root-cause verification this
script's fix approach is based on).

This is a downstream fix, not something to send upstream: it doesn't
affect the Pandoc-based flow the current maintainers actually use, so
they have no reason to want it. Run this against a local copy of the
`development/` RST tree before feeding it to Sphinx, the same way
convert_dev_docs_to_docbook.sh already owns its own downstream fixups
against Pandoc's output (see that script's header comment for the
precedent).

Idempotent: a header already rewritten to use the custom delimiter no
longer matches the default comma-and-quotes pattern this script looks
for, so running it again is a no-op for files it already fixed.

Usage:
    python3 fix_csv_table_headers.py <path> [--dry-run]

Arguments:
    path        A single .rst file, or a directory to search recursively
                for .rst files.

Options:
    --dry-run   Report what would change without writing any files.
"""
import argparse
import re
import sys
from pathlib import Path

# Matches a `:header: "A", "B"[, "C"...]` line (the default comma
# delimiter, quoted fields) immediately followed by its own `:delim: X`
# line, capturing the header's indentation, its quoted field list, and
# the custom delimiter to apply.
HEADER_DELIM_PATTERN = re.compile(
    r'^([ \t]*):header:[ \t]*((?:"[^"]*"[ \t]*,[ \t]*)+"[^"]*")[ \t]*\r?\n'
    r'[ \t]*:delim:[ \t]*(\S+)[ \t]*$',
    re.MULTILINE,
)


def fix_text(text):
    """Return (fixed_text, fix_count) for one file's contents."""
    fix_count = 0

    def replace(match):
        nonlocal fix_count
        indent, fields_csv, delim = match.groups()
        fields = [f.strip() for f in re.findall(r'"[^"]*"', fields_csv)]
        fix_count += 1
        new_header = f"{indent}:header: {delim.join(fields)}"
        # Keep the :delim: line exactly as it was, just past the header.
        delim_line = match.group(0).splitlines()[1]
        return f"{new_header}\n{indent}{delim_line.strip()}"

    fixed = HEADER_DELIM_PATTERN.sub(replace, text)
    return fixed, fix_count


def main():
    parser = argparse.ArgumentParser(
        description="Fix csv-table :header: lines that don't match their own "
                    ":delim: setting, which silently drops the whole table "
                    "under Sphinx's stricter csv-table parser.",
    )
    parser.add_argument("path", help="A single .rst file, or a directory to search recursively")
    parser.add_argument("--dry-run", action="store_true",
                         help="Report what would change without writing any files")
    args = parser.parse_args()

    target = Path(args.path)
    if target.is_file():
        rst_files = [target]
    elif target.is_dir():
        rst_files = sorted(target.rglob("*.rst"))
    else:
        print(f"error: {target} is not a file or directory", file=sys.stderr)
        return 1

    total_fixes = 0
    files_changed = 0
    for rst_file in rst_files:
        original = rst_file.read_text(encoding="utf-8")
        fixed, fix_count = fix_text(original)
        if fix_count == 0:
            continue
        files_changed += 1
        total_fixes += fix_count
        print(f"{rst_file}: {fix_count} header(s) fixed")
        if not args.dry_run:
            rst_file.write_text(fixed, encoding="utf-8")

    print(f"\n{total_fixes} header(s) fixed across {files_changed} file(s)"
          f"{' (dry-run, nothing written)' if args.dry_run else ''}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
