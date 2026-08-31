#!/bin/bash
#
# pull_upstream_docs.sh
#
# Fetches the current "documentation/" subtree (the DocBook end-user
# docs: proteus_doc.xml, content/, xsl/) from the official phpBB docs
# repository, https://github.com/phpbb/documentation, into a separate
# local directory for comparison against this project's own content/
# and xsl/ trees.
#
# This does NOT touch this project's own content/, xsl/, or
# proteus_doc_*.xml files. It only creates/updates a pristine reference
# copy of the current upstream source, so the two can be diffed before
# deciding how to reconcile them (see the licensing/attribution
# discussion this script came out of: the official documentation
# content is CC BY-NC-SA 3.0, phpBB Group/phpBB Limited, and this
# project's own copy is missing the <chapterinfo><copyright> metadata
# the upstream source still carries).
#
# Usage: ./pull_upstream_docs.sh [target_dir]
#   target_dir defaults to <this script's own directory>/upstream-phpbb-documentation,
#   regardless of the current working directory it's invoked from.

set -Eeuo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
upstream_repo="https://github.com/phpbb/documentation.git"
target_dir="${1:-$script_dir/upstream-phpbb-documentation}"

# Fail fast with a clear message rather than a cryptic error mid-clone.
if ! command -v git >/dev/null 2>&1; then
	echo "git is required but not found in PATH." >&2
	exit 1
fi

if [ -d "$target_dir/.git" ]; then
	# Already have a checkout here from a previous run — just update it in
	# place. --ff-only refuses to run if history has diverged in a way
	# that isn't a clean fast-forward, rather than silently merging or
	# rewriting anything.
	echo "Existing checkout found at '$target_dir' — pulling latest..."
	git -C "$target_dir" pull --ff-only
else
	# First run: clone fresh.
	#   --depth 1            only the current commit, not full history —
	#                        this is a reference copy, not a repo to work in.
	#   --filter=blob:none   don't download file contents up front, only
	#                        commit/tree metadata (a "blobless" clone) —
	#                        combined with sparse-checkout below, this
	#                        avoids ever fetching the unrelated development/
	#                        (Sphinx dev docs) subtree's file contents.
	#   --sparse             enables sparse-checkout so a subtree can be
	#                        selected next, instead of checking out
	#                        everything.
	echo "Cloning the 'documentation/' subtree from $upstream_repo into '$target_dir'..."
	rm -rf "$target_dir"
	git clone --depth 1 --filter=blob:none --sparse "$upstream_repo" "$target_dir"
	# Restrict the actual working-tree checkout to just documentation/ —
	# the DocBook source (proteus_doc.xml, content/, xsl/) this script
	# cares about.
	git -C "$target_dir" sparse-checkout set documentation
fi

echo ""
echo "Done. Current upstream docs are at:"
echo "  $target_dir/documentation/proteus_doc.xml"
echo "  $target_dir/documentation/content/"
echo "  $target_dir/documentation/xsl/"
echo ""
echo "Compare against this project's own copies with, for example:"
echo "  diff -rq $script_dir/content/en/chapters $target_dir/documentation/content/en/chapters"
