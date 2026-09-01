#!/bin/bash
#
# pull_upstream_docs.sh
#
# Syncs this project's own English end-user docs source
# (content/en/chapters/, content/en/images/) from the "documentation/"
# subtree of the official phpBB docs repository,
# https://github.com/phpbb/documentation — upstream is authoritative
# for this content, not a local permanent copy that can drift out of
# sync. Files added or changed upstream are copied in; files removed
# upstream are removed locally too (rsync --delete).
#
# This does NOT touch content/da/ or content/fr/ (hand-translated, no
# upstream source to sync from) or proteus_doc_<lang>.xml (this
# project's own multi-language book wrapper, not present upstream in
# this form — see that file's own header comment).
#
# Usage: ./pull_upstream_docs.sh
#
# All paths are resolved relative to this script's own location, not
# the caller's current working directory.

set -Eeuo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
upstream_repo="https://github.com/phpbb/documentation.git"
checkout_dir="$script_dir/upstream-phpbb-documentation"

for tool in git rsync; do
	command -v "$tool" >/dev/null 2>&1 || { echo "$tool is required but not found in PATH." >&2; exit 1; }
done

if [ -d "$checkout_dir/.git" ]; then
	# Already have a checkout here from a previous run — just update it in
	# place. --ff-only refuses to run if history has diverged in a way
	# that isn't a clean fast-forward, rather than silently merging or
	# rewriting anything.
	echo "Existing checkout found at '$checkout_dir' — pulling latest..."
	git -C "$checkout_dir" pull --ff-only
	# A previous run of convert_dev_docs_to_docbook.sh may have this
	# checkout sparse-set to "development" only — make sure
	# "documentation" is included too without dropping that.
	git -C "$checkout_dir" sparse-checkout add documentation
else
	# First run: clone fresh.
	#   --depth 1            only the current commit, not full history —
	#                        this is a sync source, not a repo to work in.
	#   --filter=blob:none   don't download file contents up front, only
	#                        commit/tree metadata (a "blobless" clone) —
	#                        combined with sparse-checkout below, this
	#                        avoids ever fetching the unrelated development/
	#                        (Sphinx dev docs) subtree's file contents.
	#   --sparse             enables sparse-checkout so a subtree can be
	#                        selected next, instead of checking out
	#                        everything.
	echo "Cloning the 'documentation/' subtree from $upstream_repo into '$checkout_dir'..."
	rm -rf "$checkout_dir"
	git clone --depth 1 --filter=blob:none --sparse "$upstream_repo" "$checkout_dir"
	git -C "$checkout_dir" sparse-checkout set documentation
fi

upstream_content_en="$checkout_dir/documentation/content/en"
[ -d "$upstream_content_en" ] || { echo "$upstream_content_en not found — sparse-checkout may have failed." >&2; exit 1; }

echo ""
echo "Syncing content/en/ from upstream (additions, edits, and removals)..."
rsync -a --delete "$upstream_content_en/chapters/" "$script_dir/content/en/chapters/"
rsync -a --delete "$upstream_content_en/images/" "$script_dir/content/en/images/"

echo ""
echo "Done. content/en/ now matches upstream. Review with:"
echo "  git -C '$script_dir' diff --stat content/en"
echo ""
echo "Note: proteus_doc_en.xml's <bookinfo> (title/abstract/authorgroup/"
echo "copyright) is a hand-maintained wrapper, not auto-synced — check it"
echo "against $checkout_dir/documentation/proteus_doc.xml by hand if"
echo "upstream's book metadata has changed."
