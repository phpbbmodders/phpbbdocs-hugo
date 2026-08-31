#!/bin/bash
#
# fill_translation_fallbacks.sh
#
# For every page that exists under one language's content tree but has
# no counterpart at the same relative path in another language, copies
# the source page into that language's tree verbatim, flagged with
# `fallback: true` / `fallbackFrom: <source_lang>` front matter — so the
# site can show a "this page hasn't been translated yet" notice and
# link to it from the language switcher, instead of either 404ing on a
# direct link or (the current behavior with no fallback at all) simply
# never showing a switcher link to it in the first place.
#
# Matching by relative path, not by parsing each page's own
# translationKey field, works here specifically because this project's
# own convention (see this project's own README.md, "Adding another
# language" section) already requires a translated page to keep the
# exact same filename/subdirectory layout as its source-language
# original for the language switcher to work at all — so identical path
# implies identical translationKey in every page this project produces.
#
# Usage: ./fill_translation_fallbacks.sh <source_lang> [target_lang ...]
#   source_lang   The language whose content is authoritative/complete
#                 (e.g. "en"). Required.
#   target_lang   One or more languages to fill gaps for. Defaults to
#                 every other content/<lang>/ directory found if none
#                 are given.
#
# Only ever ADDS or REFRESHES fallback copies — a real, already-translated
# page (anything without `fallback: true` in its front matter) is never
# touched. Safe to re-run any time: a gap that's since been given a real
# translation is left alone (the real file is there, so the "already
# exists and isn't a fallback" check skips it); a gap that's still a gap
# gets its fallback copy refreshed with whatever the source content
# currently says, so a fallback page can't go stale after a source
# update the way a one-time copy would.
#
# All paths are resolved relative to this script's own location, not
# the caller's current working directory.

set -Eeuo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
content_dir="$script_dir/site/content"
source_lang=${1:?"Usage: $0 <source_lang> [target_lang ...]"}
shift || true

[ -d "$content_dir/$source_lang" ] || { echo "No $content_dir/$source_lang found." >&2; exit 1; }

if [ "$#" -gt 0 ]; then
	target_langs=("$@")
else
	target_langs=()
	for dir in "$content_dir"/*/; do
		lang=$(basename -- "$dir")
		[ "$lang" = "$source_lang" ] && continue
		target_langs+=("$lang")
	done
fi

filled=0
for target_lang in "${target_langs[@]}"; do
	target_dir="$content_dir/$target_lang"
	mkdir -p -- "$target_dir"

	while IFS= read -r -d '' source_file; do
		relative_path=${source_file#"$content_dir/$source_lang/"}
		target_file="$target_dir/$relative_path"

		# A real translated page, or one this script already filled on a
		# previous run, are the only two states a target file can be in.
		# Only the second is safe to overwrite.
		if [ -f "$target_file" ] && ! grep -q "^fallback: true$" "$target_file" 2>/dev/null; then
			continue
		fi

		mkdir -p -- "$(dirname -- "$target_file")"
		# Insert the fallback marker right after the opening front-matter
		# fence rather than re-parsing/rebuilding the whole YAML block —
		# works regardless of whatever other fields a given page's front
		# matter already has (weight, other custom params, etc.).
		awk -v src="$source_lang" '
			NR==1 && $0=="---" { print; print "fallback: true"; print "fallbackFrom: " src; next }
			{ print }
		' "$source_file" > "$target_file"

		filled=$((filled + 1))
	done < <(find "$content_dir/$source_lang" \( -name "index.md" -o -name "_index.md" \) -print0)
done

echo "Filled/refreshed $filled fallback page(s) across: ${target_langs[*]}"
