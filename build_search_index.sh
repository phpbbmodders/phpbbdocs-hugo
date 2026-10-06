#!/usr/bin/bash
#
# build_search_index.sh
#
# Builds the Pagefind full-text search indexes for an already-built Hugo
# site. Called by phpbbdocs_hugo.sh and phpbbdocs_hugo_devdocs.sh after
# `hugo` runs; can also be run on its own against an existing build.
#
# One Pagefind bundle is written per language and top-level section, at
# <site_dir>/<lang>/<section>/pagefind/. Keeping sections in separate
# bundles lets the phpBB Documentation extension serve only the bundles
# for sections a user may read; the standalone site's search page merges
# every section bundle of its language. A language is a directory with
# its own index.html; a section is a directory under it with its own
# index.html (the same rule the extension uses), excluding images/.
#
# Pagefind is pinned to 1.5.2 (pagefind_version below). A `pagefind`
# binary on PATH is used when it reports exactly that version, which is
# much faster; otherwise the script falls back to
# `npx --yes pagefind@<version>` (Node.js required).
#
# Usage: ./build_search_index.sh site_dir
#   site_dir  The built Hugo site (normally site/public).

set -Eeuo pipefail

pagefind_version=1.5.2

usage() {
	sed -n '2,/^$/s/^# \{0,1\}//p' "$0"
}

if [ "$#" -ne 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	usage
	[ "$#" -eq 1 ] && exit 0
	exit 2
fi

site_dir=$1
[ -d "$site_dir" ] || { echo "Site directory not found: $site_dir" >&2; exit 1; }
site_dir=$(CDPATH= cd -- "$site_dir" && pwd)

# Resolve the pinned Pagefind command once, before touching the build.
if command -v pagefind >/dev/null 2>&1 \
	&& [ "$(pagefind --version 2>/dev/null)" = "pagefind $pagefind_version" ]; then
	pagefind_cmd=(pagefind)
elif command -v npx >/dev/null 2>&1; then
	pagefind_cmd=(npx --yes "pagefind@$pagefind_version")
else
	echo "Pagefind $pagefind_version is required (a pagefind binary on PATH, or npx)" >&2
	exit 1
fi

# Bundles from an earlier build may belong to sections or pages that no
# longer exist, so every bundle is rebuilt from scratch. -mindepth and
# -maxdepth restrict this to exactly <lang>/<section>/pagefind, and find
# does not follow symlinks.
find "$site_dir" -mindepth 3 -maxdepth 3 -type d -name pagefind -exec rm -rf -- {} +

found=0
for lang_dir in "$site_dir"/*/; do
	lang_dir=${lang_dir%/}
	lang=${lang_dir##*/}
	[ -f "$lang_dir/index.html" ] && [ ! -L "$lang_dir" ] || continue
	case "$lang" in
		*[!A-Za-z0-9_-]*) echo "Skipping unexpected directory: $lang" >&2; continue ;;
	esac

	# Pagefind picks its stemmer from the language code. Hugo codes such
	# as de_x_sie are not language tags, so index those as their base
	# language (de_x_sie -> de).
	index_lang=${lang%%_*}

	for section_dir in "$lang_dir"/*/; do
		section_dir=${section_dir%/}
		section=${section_dir##*/}
		[ "$section" != images ] && [ -f "$section_dir/index.html" ] && [ ! -L "$section_dir" ] || continue
		case "$section" in
			*[!A-Za-z0-9_-]*) echo "Skipping unexpected directory: $lang/$section" >&2; continue ;;
		esac

		"${pagefind_cmd[@]}" \
			--site "$site_dir" \
			--glob "$lang/$section/**/*.html" \
			--output-subdir "$lang/$section/pagefind" \
			--force-language "$index_lang" \
			--silent
		echo "Indexed $lang/$section"
		found=1
	done
done

[ "$found" -eq 1 ] || { echo "No language sections found in $site_dir" >&2; exit 1; }
