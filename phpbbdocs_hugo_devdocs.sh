#!/bin/bash
#
# phpbbdocs_hugo_devdocs.sh
#
# Builds Hugo content for the phpBB developer documentation (coding
# guidelines, extension tutorials, DBAL reference, etc.) and adds it
# into the SAME Hugo site phpbbdocs_hugo.sh builds the end-user docs
# into, as a new "development" section under whichever language is
# requested (content/<lang>/development/), then runs the Hugo build
# itself.
#
# For "en", this script always regenerates dev-docs-docbook/en/ itself
# first by running convert_dev_docs_to_docbook.sh, which pulls the
# developer docs fresh from upstream and converts each .rst file to a
# standalone DocBook <article> (see its own header comment for why the
# conversion needs the fixes it applies) — so an "en" build never
# silently renders a stale prior conversion. For any other language,
# dev-docs-docbook/<lang>/ has to already exist, produced separately —
# there's no automated upstream source for a translation, so this
# script only renders whichever DocBook source is already on disk for
# that language into Hugo pages, it doesn't translate anything itself.
#
# Every page gets a translationKey derived from its chapter and slug
# (development-<chapter>-<slug>, stable across languages since neither
# half changes when the content is translated), so Hugo's language
# switcher can actually link a translated page back to its English
# original — without this, translated pages would exist but the
# language switcher would have no way to find them from the English
# version, matching what the hand-authored end-user docs already do
# with their own translationKey values.
#
# Why this isn't just "run phpbbdocs_hugo.sh on the dev docs too": that
# script's XSLT (proteus_hugo.xsl) only knows how to process a single
# <book> containing <chapter>/<section> elements — the shape of the
# hand-authored end-user docs, which are one XIncluded book. The
# dev-docs conversion instead produced 55 independent, already-separate
# <article> files nested in subdirectories (auth/, cli/, db/,
# development/, extensions/ [19 files alone], files/, language/,
# migrations/ [+ a tools/ subdirectory], request/, testing/). Rather
# than force that into a single synthetic book, this script treats each
# top-level subdirectory as a Hugo chapter and each .rst-derived article
# in it as one page within that chapter — mirroring the source's own
# organization. The actual per-article rendering is done by a separate,
# purpose-built stylesheet, xsl/proteus_hugo_devdocs.xsl (imports the
# same shared element templates proteus_hugo.xsl's chain uses, adding
# table/code-block/line-break support the end-user docs never needed
# but this content does).
#
# Requires xsltproc and hugo on PATH. Building "en" also transitively
# requires whatever convert_dev_docs_to_docbook.sh needs (git, curl,
# tar, xmllint) — see that script's own header.
#
# Usage: ./phpbbdocs_hugo_devdocs.sh [language] [destination_dir]
#   language        Defaults to "en". Reads from dev-docs-docbook/<language>/
#                    (dev-docs-docbook/en/ matches convert_dev_docs_to_docbook.sh's
#                    own default output location).
#   destination_dir  Defaults to site/public (same default
#                    phpbbdocs_hugo.sh uses, since this builds into the
#                    same site).
#
# All paths are resolved relative to this script's own location, not
# the caller's current working directory.

set -Eeuo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
site_dir="$script_dir/site"
lang=${1:-en}

case "$lang" in
	*[!A-Za-z0-9_-]*|'') echo "Invalid language code: $lang" >&2; exit 1 ;;
esac

source_dir="$script_dir/dev-docs-docbook/$lang"
content_root="$site_dir/content/$lang/development"
destination_dir=${2:-$site_dir/public}

command -v xsltproc >/dev/null 2>&1 || { echo "xsltproc is required" >&2; exit 1; }
command -v hugo >/dev/null 2>&1 || { echo "Hugo is required" >&2; exit 1; }

if [ "$lang" = "en" ]; then
	# English has a real upstream source — always regenerate it fresh
	# rather than trusting whatever's already on disk, so this build can
	# never silently render a stale prior conversion.
	"$script_dir/convert_dev_docs_to_docbook.sh" "$source_dir"
else
	[ -d "$source_dir" ] || {
		echo "No $source_dir found — produce a translated $source_dir first (there's no automated upstream source for '$lang')." >&2
		exit 1
	}
fi

# A handful of the top-level directory names are abbreviations that
# look better with a specific human title than a bare capitalized first
# letter would give ("Db" / "Cli") — everything else falls through to
# the generic capitalize-first-letter default below.
pretty_title() {
	case "$1" in
		db) echo "Database Abstraction Layer" ;;
		cli) echo "CLI" ;;
		*) printf '%s' "$1" | sed -e 's/_/ /g' -e 's/\b\(.\)/\u\1/g' ;;
	esac
}

rm -rf "$content_root"
mkdir -p "$content_root"

# Top-level landing page for the whole "development" section, listing
# every chapter (subdirectory) — filled in as the loop below finds them.
chapter_links=""

for chapter_dir in "$source_dir"/*/; do
	[ -d "$chapter_dir" ] || continue
	chapter_name=$(basename -- "$chapter_dir")
	chapter_title=$(pretty_title "$chapter_name")
	chapter_out="$content_root/$chapter_name"
	mkdir -p -- "$chapter_out"

	chapter_links="$chapter_links- [$chapter_title]($chapter_name/)
"

	# Every article (.dbk file) directly under this chapter, plus any in
	# a nested subdirectory (migrations/tools/ is the one case of this
	# in the current source) — find handles both without needing special
	# casing for the one nested exception.
	page_links=""
	weight=1
	while IFS= read -r -d '' dbk_file; do
		# Slug from the path relative to the chapter directory, not just
		# the bare filename — e.g. tutorial_migrations.dbk -> tutorial_migrations,
		# but tools/index.dbk -> tools-index. Bare-filename slugs collide
		# whenever a nested subdirectory (migrations/tools/ is the one
		# case in the current source) has a file with the same name as
		# one directly in the chapter root — migrations/index.dbk and
		# migrations/tools/index.dbk both being named "index" silently
		# overwrote one with the other before this fix (confirmed: only
		# migrations/index.dbk's content ever made it to the site;
		# migrations/tools/index.dbk, "Migration Tools", was silently
		# missing entirely).
		relative_to_chapter=${dbk_file#"$chapter_dir"}
		relative_to_chapter=${relative_to_chapter%.dbk}
		slug=$(printf '%s' "$relative_to_chapter" | tr '/' '-')
		page_out_dir="$chapter_out/$slug"
		mkdir -p -- "$page_out_dir"

		# --nonet: the DocBook 4 DOCTYPE these files carry declares a real
		# external DTD URL (oasis-open.org) — without this, xsltproc tries
		# to fetch it over the network on every single file, which is
		# both slow and noisy (a warning per file) for no benefit, since
		# nothing here actually needs a DTD-defined entity resolved.
		xsltproc \
			--nonet \
			--stringparam page.weight "$weight" \
			--stringparam page.translationKey "development-$chapter_name-$slug" \
			--output "$page_out_dir/index.md" \
			"$script_dir/xsl/proteus_hugo_devdocs.xsl" \
			"$dbk_file"

		# Pull the title back out of the front matter this script just
		# wrote, so the chapter's own contents list uses the same title
		# text the page itself does, rather than re-deriving it from the
		# slug a second time. The XSL emits it YAML-double-quoted (titles
		# can contain a colon, e.g. "Tutorial: Modules", which would
		# otherwise break Hugo's front-matter parser) — strip the quotes
		# and un-escape \" back to " for plain display as markdown link
		# text here, where no quoting is needed.
		page_title=$(sed -n 's/^title: "\(.*\)"$/\1/p' "$page_out_dir/index.md" | sed 's/\\"/"/g' | head -1)
		page_links="$page_links- [$page_title]($slug/)
"
		weight=$((weight + 1))
	done < <(find "$chapter_dir" -name '*.dbk' -print0)

	cat > "$chapter_out/_index.md" <<EOF
---
title: "${chapter_title//\"/\\\"}"
translationKey: development-$chapter_name
---

# $chapter_title

## Contents

$page_links
EOF

	echo "Generated '$chapter_title' ($((weight - 1)) page(s))"
done

cat > "$content_root/_index.md" <<EOF
---
title: Development
translationKey: development-home
---

# Development Documentation

## Contents

$chapter_links
EOF

hugo --source "$site_dir" --destination "$destination_dir"
echo "Built Hugo site (with development docs) in $destination_dir"
