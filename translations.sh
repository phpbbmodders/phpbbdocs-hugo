#!/usr/bin/env bash
#
# translations.sh — gettext-based translation workflow for
# dev-docs-docbook/ and content/*/chapters/ translations.
#
# DocBook engine: itstool (see docs/phpbb-gettext-translation-poc-results.md
# for why itstool over po4a/poxml). Currently covers the seven
# hand-authored end-user chapters (content/en/chapters/*.xml ->
# <lang>/documentation/*.po in the sibling phpbbdocs-languages repo).
# Sphinx/RST dev-docs support is not implemented yet (see that same
# report's open items — the Symfony conf.py extensions question isn't
# resolved).
#
# Usage: ./translations.sh <command> [args]
#   extract                      Generate POT templates (maintainer command)
#   init <lang>                  Initialize a new language's catalogs
#   update <lang>                Refresh POT and merge into <lang>'s catalogs
#   status <lang>                Show translation completion for <lang>
#   check <lang>                 Validate <lang>'s PO files and reconstructed XML
#   audit <lang>                 Diff each chapter's reconstruction against
#                                 content/<lang>/chapters/ for real content
#                                 mismatches (see docs/TODO/todo-po-roundtrip-audit.md)
#   build <lang>                 Reconstruct translated DocBook and build Hugo
#
# Canonical PO catalogs live in the sibling phpbbdocs-languages repo,
# resolved via translation.conf (LANGUAGES_REPO env var overrides it).
#
# Before/after touching this pipeline (build output, PO catalogs, a
# manual itstool invocation), see docs/gettext-workflow-checklist.md —
# round-trip verification, authorship-metadata preservation, and
# attribution steps that should happen every time, not just when asked.
set -Eeuo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

python3() { command python3 "$@"; }
lib="$script_dir/translations/lib.py"

# Use our vendored, patched itstool (translations/vendor/itstool-patched)
# instead of the system itstool. It fixes an upstream itstool 2.0.6 merge
# (-m) bug where translated content for certain placeholder-nested
# paragraphs is silently dropped in favor of the original-language text;
# see that file's header and docs/phpbb-gettext-translation-poc-results.md
# for details. Not yet reported upstream.
itstool() { "$script_dir/translations/vendor/itstool-patched" "$@"; }

chapters=(admin_guide user_guide moderator_guide quick_start_guide upgrade_guide server_guide glossary)

languages_repo() {
	if [ -n "${LANGUAGES_REPO:-}" ]; then
		( cd "$LANGUAGES_REPO" && pwd )
		return
	fi
	local conf_value
	conf_value="$(grep -E '^LANGUAGES_REPO=' "$script_dir/translation.conf" | head -1 | cut -d= -f2-)"
	if [ -z "$conf_value" ]; then
		echo "error: LANGUAGES_REPO not set in translation.conf and no override given" >&2
		exit 1
	fi
	( cd "$script_dir/$conf_value" && pwd )
}

require_lang_arg() {
	if [ -z "${1:-}" ]; then
		echo "error: missing <lang> argument" >&2
		exit 1
	fi
}

cmd_extract() {
	local build_dir="$script_dir/build/gettext/documentation"
	mkdir -p "$build_dir"
	echo "Extracting DocBook POT templates to build/gettext/documentation/"
	# cd into the source directory first so itstool's "#:" source
	# references come out as clean relative paths (content/en/chapters/…)
	# rather than this machine's absolute checkout path, which would
	# otherwise leak into every PO file committed to phpbbdocs-languages.
	( cd "$script_dir/content/en/chapters" && for chapter in "${chapters[@]}"; do
		itstool -o "$build_dir/$chapter.pot" "$chapter.xml"
		echo "  $chapter.pot"
	done )
}

cmd_init() {
	local lang="$1"
	python3 "$lib" validate-lang "$lang" >/dev/null

	local repo
	repo="$(languages_repo)"
	local lang_dir="$repo/$lang"

	if [ -d "$lang_dir/documentation" ] && [ -n "$(ls -A "$lang_dir/documentation" 2>/dev/null)" ]; then
		echo "error: $lang_dir/documentation already has catalogs — init does not overwrite existing work" >&2
		echo "       use 'update $lang' to refresh an existing language instead" >&2
		exit 1
	fi

	echo "Initializing '$lang' in $repo"

	if [ ! -f "$lang_dir/language.toml" ]; then
		echo "No language.toml yet for '$lang'."
		read -rp "  English name (e.g. French): " name
		read -rp "  Native name (e.g. Français): " native_name
		read -rp "  Locale (e.g. fr_FR): " locale
		python3 "$lib" write-language-toml "$lang" --name "$name" --native-name "$native_name" --locale "$locale"
	fi

	cmd_extract

	mkdir -p "$lang_dir/documentation"
	local commit
	commit="$(python3 -c "import sys; sys.path.insert(0,'$script_dir/translations'); import lib; print(lib.current_hugo_commit())")"

	for chapter in "${chapters[@]}"; do
		local pot="$script_dir/build/gettext/documentation/$chapter.pot"
		local po="$lang_dir/documentation/$chapter.po"
		msginit --no-translator -i "$pot" -o "$po" -l "${lang}.UTF-8" >/dev/null 2>&1 || \
			msginit --no-translator -i "$pot" -o "$po" -l "en.UTF-8" >/dev/null 2>&1
		# msginit sets Language from the -l locale; overwrite with the
		# bare phpBB code, since msginit's locale guess is not always
		# right for codes like de_x_sie.
		sed -i "s/^\"Language: .*\\\\n\"/\"Language: $lang\\\\n\"/" "$po"
		echo "  documentation/$chapter.po created"
	done

	python3 "$lib" record-source "$lang" documentation "$commit"
	echo "Done. Edit $lang_dir/documentation/*.po, then run 'check $lang' and 'build $lang'."
}

cmd_update() {
	local lang="$1"
	require_lang_arg "$lang"
	local repo
	repo="$(languages_repo)"
	local lang_dir="$repo/$lang"

	if [ ! -d "$lang_dir/documentation" ]; then
		echo "error: '$lang' has not been initialized — run 'init $lang' first" >&2
		exit 1
	fi

	cmd_extract

	local commit
	commit="$(python3 -c "import sys; sys.path.insert(0,'$script_dir/translations'); import lib; print(lib.current_hugo_commit())")"

	echo ""
	echo "Updating '$lang' documentation catalogs in $lang_dir/documentation"
	local before_commit
	before_commit="$(python3 "$lib" read-source "$lang" documentation)"
	echo "Source: $before_commit -> $commit"
	echo ""

	local any_failed=0
	for chapter in "${chapters[@]}"; do
		local pot="$script_dir/build/gettext/documentation/$chapter.pot"
		local po="$lang_dir/documentation/$chapter.po"
		if [ ! -f "$po" ]; then
			echo "  $chapter.po  MISSING (run init first) — skipped"
			any_failed=1
			continue
		fi
		read -r before_t before_f before_u before_o < <(python3 "$lib" po-stats "$po")
		msgmerge --update --backup=off --previous "$po" "$pot" >/dev/null 2>&1
		read -r after_t after_f after_u after_o < <(python3 "$lib" po-stats "$po")
		if [ "$before_t $before_f $before_u $before_o" = "$after_t $after_f $after_u $after_o" ]; then
			echo "  $chapter.po  unchanged"
		else
			echo "  $chapter.po  updated  (translated $before_t->$after_t, fuzzy $before_f->$after_f, untranslated $before_u->$after_u, obsolete $before_o->$after_o)"
		fi
	done

	if [ "$any_failed" -eq 0 ]; then
		python3 "$lib" record-source "$lang" documentation "$commit"
		echo ""
		echo "Source metadata updated: $repo/metadata/source.json"
	else
		echo ""
		echo "One or more catalogs were missing; source revision NOT advanced." >&2
		return 1
	fi
}

cmd_status() {
	local lang="$1"
	require_lang_arg "$lang"
	local repo
	repo="$(languages_repo)"
	local lang_dir="$repo/$lang"

	if [ ! -d "$lang_dir/documentation" ]; then
		echo "error: '$lang' has not been initialized — run 'init $lang' first" >&2
		exit 1
	fi

	local name
	name="$(grep '^name' "$lang_dir/language.toml" 2>/dev/null | cut -d'"' -f2)"
	echo "${name:-$lang} Translation Status"
	echo "=========================="
	echo ""
	echo "User Documentation"
	echo "------------------"

	local total_t=0 total_f=0 total_u=0 total_o=0
	for chapter in "${chapters[@]}"; do
		local po="$lang_dir/documentation/$chapter.po"
		if [ ! -f "$po" ]; then
			printf "  %-20s MISSING\n" "$chapter.po"
			continue
		fi
		read -r t f u o < <(python3 "$lib" po-stats "$po")
		total_t=$((total_t + t)); total_f=$((total_f + f)); total_u=$((total_u + u)); total_o=$((total_o + o))
		printf "  %-20s translated %-4d fuzzy %-4d untranslated %-4d obsolete %-4d\n" "$chapter.po" "$t" "$f" "$u" "$o"
	done

	local total=$((total_t + total_f + total_u))
	local pct="n/a"
	if [ "$total" -gt 0 ]; then
		pct="$(awk -v t="$total_t" -v n="$total" 'BEGIN{printf "%.1f", (t/n)*100}')"
	fi
	echo ""
	echo "Translated:      $total_t"
	echo "Fuzzy:           $total_f  (needs review)"
	echo "Untranslated:    $total_u"
	echo "Obsolete:        $total_o  (excluded from completion)"
	echo "Completion:      ${pct}%"

	local recorded current
	recorded="$(python3 "$lib" read-source "$lang" documentation)"
	current="$(python3 -c "import sys; sys.path.insert(0,'$script_dir/translations'); import lib; print(lib.current_hugo_commit())")"
	echo ""
	if [ "$recorded" = "$current" ]; then
		echo "Source: up to date ($recorded)"
	else
		echo "Source: DRIFTED — recorded $recorded, current $current (run 'update $lang')"
	fi
}

cmd_check() {
	local lang="$1"
	require_lang_arg "$lang"
	local repo
	repo="$(languages_repo)"
	local lang_dir="$repo/$lang"
	local ok=1
	local catalogs_found=0
	local missing_chapters=()

	echo "$lang Translation Validation"
	echo "=============================="
	echo ""

	for chapter in "${chapters[@]}"; do
		local po="$lang_dir/documentation/$chapter.po"
		if [ ! -f "$po" ]; then
			missing_chapters+=("$chapter")
			continue
		fi
		catalogs_found=$((catalogs_found + 1))
		if ! msgfmt --check -o /dev/null "$po" 2>/tmp/translations_check_err; then
			echo "✗ $chapter.po: PO syntax invalid"
			cat /tmp/translations_check_err
			ok=0
		fi
	done
	local complete=1
	if [ "${#missing_chapters[@]}" -gt 0 ]; then
		complete=0
		echo "✗ missing catalog(s): ${missing_chapters[*]}"
	fi
	if [ "$catalogs_found" -eq 0 ]; then
		echo "✗ no PO catalogs found under $lang_dir/documentation/ -- nothing was validated"
	elif [ "$ok" -eq 1 ]; then
		echo "✓ PO syntax valid ($catalogs_found/${#chapters[@]} catalog(s) present)"
	fi

	local recon_dir
	recon_dir="$(mktemp -d)"
	local recon_ok=1
	for chapter in "${chapters[@]}"; do
		local po="$lang_dir/documentation/$chapter.po"
		local src="$script_dir/content/en/chapters/$chapter.xml"
		[ -f "$po" ] || continue
		local mo="$recon_dir/$chapter.mo"
		msgfmt -o "$mo" "$po" 2>/dev/null
		if ! itstool -m "$mo" -l "$lang" -o "$recon_dir/$chapter.xml" "$src" 2>/tmp/translations_check_err; then
			echo "✗ $chapter: DocBook reconstruction failed"
			cat /tmp/translations_check_err
			recon_ok=0
			continue
		fi
		if ! xmllint --noout --nonet "$recon_dir/$chapter.xml" 2>/tmp/translations_check_err; then
			echo "✗ $chapter: reconstructed XML invalid"
			cat /tmp/translations_check_err
			recon_ok=0
		fi
	done
	if [ "$catalogs_found" -gt 0 ] && [ "$recon_ok" -eq 1 ]; then
		echo "✓ DocBook reconstruction successful ($catalogs_found/${#chapters[@]} catalog(s) present)"
		echo "✓ DocBook XML valid"
	fi
	rm -rf "$recon_dir"

	echo ""
	cmd_status "$lang"
	echo ""
	if [ "$complete" -eq 1 ] && [ "$catalogs_found" -gt 0 ] && [ "$ok" -eq 1 ] && [ "$recon_ok" -eq 1 ]; then
		echo "Result: COMPLETE -- all ${#chapters[@]} expected catalogs present and valid."
	else
		echo "Result: INCOMPLETE -- do not treat this as full-language validation."
	fi

	[ "$complete" -eq 1 ] && [ "$catalogs_found" -gt 0 ] && [ "$ok" -eq 1 ] && [ "$recon_ok" -eq 1 ]
}

cmd_audit() {
	local lang="$1"
	require_lang_arg "$lang"
	local repo
	repo="$(languages_repo)"
	local lang_dir="$repo/$lang"
	local target_dir="$script_dir/content/$lang/chapters"

	echo "$lang PO round-trip content audit"
	echo "================================"
	echo "Reconstructs each chapter from its PO catalog and diffs every"
	echo "paragraph against content/$lang/chapters/ -- see"
	echo "docs/TODO/todo-po-roundtrip-audit.md for what this catches and why."
	echo ""

	local audit_dir
	audit_dir="$(mktemp -d)"
	local overall_ok=1
	local checked=0
	for chapter in "${chapters[@]}"; do
		local po="$lang_dir/documentation/$chapter.po"
		local hand="$target_dir/$chapter.xml"
		local src="$script_dir/content/en/chapters/$chapter.xml"
		if [ ! -f "$po" ] || [ ! -f "$hand" ]; then
			echo "○ $chapter: skipped (no PO catalog or no hand file yet)"
			continue
		fi
		checked=$((checked + 1))
		local mo="$audit_dir/$chapter.mo"
		local recon="$audit_dir/$chapter.xml"
		msgfmt -o "$mo" "$po" 2>/dev/null
		if ! itstool -m "$mo" -l "$lang" -o "$recon" "$src" 2>/tmp/translations_audit_err; then
			echo "✗ $chapter: reconstruction failed"
			cat /tmp/translations_audit_err
			overall_ok=0
			continue
		fi
		python3 "$script_dir/translations/preserve_authorship_metadata.py" "$recon" "$hand"
		local audit_output
		if audit_output="$(python3 "$script_dir/translations/audit_roundtrip.py" "$chapter" "$hand" "$recon" 2>&1)"; then
			echo "✓ $audit_output"
		else
			echo "✗ $chapter: real mismatches found"
			echo "$audit_output" | sed 's/^/    /'
			overall_ok=0
		fi
	done
	rm -rf "$audit_dir"

	echo ""
	if [ "$checked" -eq 0 ]; then
		echo "No chapters were actually checked (no PO catalog + hand file pair found for" \
			"any chapter) -- this is not the same as clean, nothing was compared."
		overall_ok=0
	elif [ "$overall_ok" -eq 1 ] && [ "$checked" -eq "${#chapters[@]}" ]; then
		echo "Result: COMPLETE -- all ${#chapters[@]} chapters round-trip clean."
	elif [ "$overall_ok" -eq 1 ]; then
		echo "Result: PARTIAL -- $checked/${#chapters[@]} chapters checked and clean, the rest" \
			"were skipped (no PO catalog or no hand file yet). Do not treat this as a" \
			"complete audit for this language."
	else
		echo "Some chapters have real mismatches -- see docs/gettext-workflow-checklist.md"
		echo "for what to do next (check which side is correct, fix both to agree)."
	fi
	[ "$checked" -eq "${#chapters[@]}" ] && [ "$overall_ok" -eq 1 ]
}

cmd_build() {
	local lang="$1"
	require_lang_arg "$lang"
	local repo
	repo="$(languages_repo)"
	local lang_dir="$repo/$lang"

	local target_dir="$script_dir/content/$lang/chapters"
	mkdir -p "$target_dir"

	echo "Reconstructing DocBook for '$lang' into content/$lang/chapters/"
	for chapter in "${chapters[@]}"; do
		local po="$lang_dir/documentation/$chapter.po"
		local src="$script_dir/content/en/chapters/$chapter.xml"
		[ -f "$po" ] || { echo "  $chapter: no catalog, skipped"; continue; }
		local mo
		mo="$(mktemp --suffix=.mo)"
		msgfmt -o "$mo" "$po"
		local recon
		recon="$(mktemp --suffix=.xml)"
		itstool -m "$mo" -l "$lang" -o "$recon" "$src"
		rm -f "$mo"
		# itstool's PO/gettext pipeline only carries translatable prose:
		# it always reproduces the English source's <chapterinfo>/
		# <abstract> and per-section <sectioninfo> authorship metadata
		# verbatim, which would reintroduce blocks translated chapters
		# deliberately drop and overwrite translator attribution
		# (e.g. <othername>Claude</othername>) with the English
		# original's authors. Fix that up before replacing the target,
		# preserving whatever attribution the current file already has.
		python3 "$script_dir/translations/preserve_authorship_metadata.py" "$recon" "$target_dir/$chapter.xml"
		mv "$recon" "$target_dir/$chapter.xml"
		echo "  $chapter.xml"
	done

	echo ""
	echo "Run ./phpbbdocs_hugo.sh $lang to build the Hugo site (proteus_doc_${lang}.xml"
	echo "bookinfo front matter is not generated by this tool — see README.md step 1)."
}

command="${1:-}"
shift || true

case "$command" in
	extract) cmd_extract "$@" ;;
	init) cmd_init "$@" ;;
	update) cmd_update "$@" ;;
	status) cmd_status "$@" ;;
	check) cmd_check "$@" ;;
	audit) cmd_audit "$@" ;;
	build) cmd_build "$@" ;;
	""|-h|--help)
		sed -n '2,31p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
		;;
	*)
		echo "error: unknown command '$command'" >&2
		echo "Run './translations.sh --help' for usage." >&2
		exit 1
		;;
esac
