#!/bin/bash
#
# phpbbdocs_hugo.sh
#
# Builds the Hugo-based documentation site from this project's DocBook
# source. For each language, transforms proteus_doc_<lang>.xml (via
# xsl/proteus_hugo.xsl) into Hugo Markdown content under
# site/content/<lang>/, copies that language's images into
# site/static/<lang>/images/, then runs `hugo` to build
# the static site.
#
# This is the Hugo output path specifically — proteus_doc.sh (PHP/XHTML)
# and proteus_markdown.sh (plain Markdown) are separate scripts for the
# other output formats this same DocBook source can produce.
#
# Requires xsltproc and hugo on PATH.
#
# Usage: ./phpbbdocs_hugo.sh [language|all] [destination_dir]
#   language        A language code with a matching proteus_doc_<lang>.xml
#                    file in this script's own directory. Defaults to
#                    "all", which builds every proteus_doc_*.xml found.
#   destination_dir  Where hugo writes the built site. Defaults to
#                    site/public.
#
# All paths are resolved relative to this script's own location
# ($script_dir below), not the caller's current working directory, so it
# behaves the same wherever it's invoked from.

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
site_dir="$script_dir/site"
requested_lang=${1:-all}
destination_dir=${2:-$site_dir/public}

# Fail fast with a clear message rather than a cryptic error mid-build.
command -v xsltproc >/dev/null 2>&1 || { echo "xsltproc is required" >&2; exit 1; }
command -v hugo >/dev/null 2>&1 || { echo "Hugo is required" >&2; exit 1; }

# Generates Hugo content + static assets for a single language code.
build_language() {
	lang=$1
	source_xml="$script_dir/proteus_doc_$lang.xml"
	image_dir="$script_dir/content/$lang/images"
	content_dir="$site_dir/content/$lang"
	static_dir="$site_dir/static/$lang"

	# $lang ends up directly in filesystem paths below, so reject anything
	# that isn't a plain identifier (no "..", "/", spaces, etc.) before it
	# gets anywhere near mkdir/cp.
	case "$lang" in
		*[!A-Za-z0-9_-]*|'') echo "Invalid language code: $lang" >&2; return 1 ;;
	esac

	[ -f "$source_xml" ] || { echo "No source found for language '$lang'" >&2; return 1; }
	[ -d "$image_dir" ] || { echo "No images found for language '$lang'" >&2; return 1; }

	mkdir -p -- "$content_dir" "$static_dir/images"

	# First pass: run the XSLT transform in "manifest only" mode, which
	# emits just the list of content subdirectories the real transform is
	# about to write files into (one per line), without generating any
	# Markdown yet. xsltproc/the XSLT template don't create intermediate
	# directories on their own, so these need to exist up front or the
	# second pass below would fail trying to write into them.
	manifest=$(xsltproc \
		--xinclude \
		--stringparam manifest.only 1 \
		"$script_dir/xsl/proteus_hugo.xsl" \
		"$source_xml")

	while IFS= read -r directory; do
		[ -n "$directory" ] && mkdir -p -- "$content_dir/$directory"
	done <<EOF
$manifest
EOF

	# Second pass: the real transform, now that every directory it will
	# write into already exists. Emits one _index.md per Hugo section,
	# rooted under $content_dir.
	xsltproc \
		--xinclude \
		--stringparam output.base "$content_dir" \
		--output "$content_dir/_index.md" \
		"$script_dir/xsl/proteus_hugo.xsl" \
		"$source_xml"

	# Images live alongside the DocBook source, not inside the Hugo site
	# tree, so copy this language's images into Hugo's static assets dir.
	cp -a -- "$image_dir/." "$static_dir/images/"
	echo "Generated Hugo content for '$lang'"
}

if [ "$requested_lang" = "all" ]; then
	found=0
	# Discover every language this project has source for by scanning for
	# proteus_doc_<lang>.xml files, rather than hardcoding a language list.
	for source_xml in "$script_dir"/proteus_doc_*.xml; do
		[ -e "$source_xml" ] || continue
		lang=${source_xml##*/proteus_doc_}
		lang=${lang%.xml}
		build_language "$lang"
		found=1
	done
	[ "$found" -eq 1 ] || { echo "No proteus_doc_<language>.xml files found" >&2; exit 1; }
else
	build_language "$requested_lang"
fi

# All languages' Markdown content is now in place under $site_dir/content/
# and $site_dir/static/ — build the actual static site from it.
hugo --source "$site_dir" --destination "$destination_dir"
echo "Built Hugo site in $destination_dir"
