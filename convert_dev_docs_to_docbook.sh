#!/bin/bash
#
# convert_dev_docs_to_docbook.sh
#
# Pulls the "development/" subtree (the Sphinx/reStructuredText developer
# docs: coding guidelines, extension tutorials, DBAL reference, etc.)
# from the official phpBB docs repository,
# https://github.com/phpbb/documentation, and converts every .rst file
# in it to DocBook 4 XML, mirroring the source directory structure.
#
# DocBook 4, not DocBook 5: pandoc can target either, but DocBook 5 puts
# every element in the http://docbook.org/ns/docbook XML namespace. The
# XSLT that renders this content into Hugo pages
# (xsl/proteus_hugo_devdocs.xsl) reuses the same unprefixed,
# namespace-unaware element templates the hand-authored end-user docs'
# stylesheets use (xsl/proteus_markdown.xsl) — those docs' own DocBook
# source declares no namespace at all. Namespace-unaware XPath/match
# patterns silently match nothing in a namespaced document (this was
# tried and confirmed: it produces well-formed but completely empty
# output — every page comes out as just its front matter, no body,
# because e.g. "article/info/title" matches zero nodes against a
# namespaced <article>). DocBook 4 has no namespace, so it's a drop-in
# fit for the existing stylesheets with no XSLT rewrite needed — simpler
# than making everything namespace-aware for one content source.
#
# Background: the system pandoc available in this environment (2.9.2.1)
# fails outright on files using Sphinx's ".. csv-table::" directive
# (13 of the source files do) with a hard parse error. pandoc 3.11
# converts those files successfully, but introduces two of its own
# XML-well-formedness bugs, both confirmed by hand before writing this
# script:
#   - Table cells with an embedded line break get an unclosed,
#     HTML-style "<br>" instead of DocBook's required self-closed
#     "<br/>".
#   - A source file containing a raw HTML block (".. raw:: html", used
#     for one ASCII-art-style directory-tree diagram) gets that HTML
#     passed straight through, including the "&nbsp;" HTML entity —
#     which isn't valid in bare XML (only &amp; &lt; &gt; &apos; &quot;
#     are built in) and needs to be the numeric character reference
#     "&#160;" instead.
#
# So this script:
#   1. Downloads a pinned pandoc 3.11 static binary into a local cache
#      directory (once — reused on later runs), rather than relying on
#      whatever pandoc version happens to be on the system PATH.
#   2. Pulls development/ from upstream via a sparse git checkout.
#   3. Converts every .rst file found to DocBook 4, fixing both bugs
#      above in each file's output before writing it.
#   4. Validates every converted file is well-formed XML (xmllint) and
#      reports any that aren't, rather than silently leaving a broken
#      file behind.
#
# Requires: git, curl, tar, xmllint (from libxml2-utils).
#
# Usage: ./convert_dev_docs_to_docbook.sh [output_dir]
#   output_dir defaults to <this script's own directory>/dev-docs-docbook/en
#
# All paths are resolved relative to this script's own location, not
# the caller's current working directory.

set -Eeuo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
upstream_repo="https://github.com/phpbb/documentation.git"
source_checkout_dir="$script_dir/upstream-phpbb-documentation"
pandoc_version="3.11"
pandoc_cache_dir="$script_dir/.pandoc-cache"
pandoc_bin="$pandoc_cache_dir/pandoc-$pandoc_version/bin/pandoc"
output_dir="${1:-$script_dir/dev-docs-docbook/en}"

for tool in git curl tar xmllint; do
	command -v "$tool" >/dev/null 2>&1 || { echo "$tool is required but not found in PATH." >&2; exit 1; }
done

# --- Step 1: get a known-good pandoc, independent of the system version ---

if [ ! -x "$pandoc_bin" ]; then
	echo "Fetching pandoc $pandoc_version (not found in local cache)..."
	mkdir -p "$pandoc_cache_dir/pandoc-$pandoc_version"
	tarball="$pandoc_cache_dir/pandoc-$pandoc_version.tar.gz"
	curl -sL "https://github.com/jgm/pandoc/releases/download/$pandoc_version/pandoc-$pandoc_version-linux-amd64.tar.gz" -o "$tarball"
	tar -xzf "$tarball" -C "$pandoc_cache_dir/pandoc-$pandoc_version" --strip-components=1
	rm -f "$tarball"
fi
echo "Using $("$pandoc_bin" --version | head -1)"

# --- Step 2: pull the development/ subtree from upstream ---
#
# Same blobless-sparse-clone approach as pull_upstream_docs.sh, restricted
# to development/ instead of documentation/ — see that script's comments
# for why each flag is there.

if [ -d "$source_checkout_dir/.git" ]; then
	echo "Existing upstream checkout found — pulling latest..."
	git -C "$source_checkout_dir" pull --ff-only
	# A previous run of pull_upstream_docs.sh may have this checkout
	# sparse-set to "documentation" only — make sure "development" is
	# included too without dropping that.
	git -C "$source_checkout_dir" sparse-checkout add development
else
	echo "Cloning the 'development/' subtree from $upstream_repo..."
	rm -rf "$source_checkout_dir"
	git clone --depth 1 --filter=blob:none --sparse "$upstream_repo" "$source_checkout_dir"
	git -C "$source_checkout_dir" sparse-checkout set development
fi

dev_docs_dir="$source_checkout_dir/development"
[ -d "$dev_docs_dir" ] || { echo "development/ not found in the checkout — sparse-checkout may have failed." >&2; exit 1; }

# --- Step 3: convert every .rst file, mirroring the source layout ---

rm -rf "$output_dir"
mkdir -p "$output_dir"

converted=0
failed=0

# find ... -print0 / read -d '' handles filenames with spaces safely,
# which xargs or a plain for-loop over `find` output would not.
while IFS= read -r -d '' rst_file; do
	# Strip the source root and .rst extension, keep the rest of the path,
	# so e.g. development/extensions/tutorial_basics.rst becomes
	# $output_dir/extensions/tutorial_basics.dbk.
	relative_path=${rst_file#"$dev_docs_dir"/}
	relative_path=${relative_path%.rst}
	out_file="$output_dir/$relative_path.dbk"
	mkdir -p -- "$(dirname -- "$out_file")"

	if "$pandoc_bin" -f rst -t docbook4 --standalone "$rst_file" -o "$out_file" 2>/dev/null; then
		# Fix pandoc 3.11's unclosed <br> tags and raw-HTML &nbsp; entities
		# (see header comment) before validating — in place, since the
		# file was just written fresh.
		sed -i -e 's/<br>/<br\/>/g' -e 's/&nbsp;/\&#160;/g' "$out_file"

		# --noout only checks well-formedness, not validity against the
		# DTD the DocBook 4 DOCTYPE declares (oasis-open.org) — confirmed
		# xmllint doesn't fetch that DTD for a well-formedness-only check
		# (sub-10ms either way), but --nonet is kept anyway so that stays
		# true even if a future xmllint version's default behavior changes.
		if xmllint --noout --nonet "$out_file" 2>/dev/null; then
			converted=$((converted + 1))
		else
			echo "WELL-FORMEDNESS FAILED: $relative_path.rst" >&2
			failed=$((failed + 1))
		fi
	else
		echo "CONVERSION FAILED: $relative_path.rst" >&2
		failed=$((failed + 1))
	fi
done < <(find "$dev_docs_dir" -name '*.rst' -print0)

echo ""
echo "Converted $converted file(s) to DocBook 4 in $output_dir"
if [ "$failed" -gt 0 ]; then
	echo "$failed file(s) failed to convert or didn't come out well-formed — see above." >&2
	exit 1
fi
