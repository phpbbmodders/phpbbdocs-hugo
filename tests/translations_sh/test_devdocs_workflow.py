#!/usr/bin/env python3
"""Real, assert-based test suite for translations.sh's devdocs-* commands
and their translations/lib.py support functions.

No mocking, no pytest dependency -- matches tests/sphinx_devdocs/test_sphinx_to_hugo.py's
established convention (this repo has no other test infrastructure).
Scope is the *orchestration* layer these commands add (path formulas,
discovery, dispatch, msginit/msgmerge wiring, source.json schema/migration)
-- not conversion correctness, which is already covered by
tests/sphinx_devdocs/test_sphinx_to_hugo.py's 53 checks.

Uses a small, real local git repo (not the full 55-file real upstream
checkout) as the "development" tree, pointed at via the DEVDOCS_UPSTREAM_CHECKOUT
env var translations.sh/lib.py both already support -- and a scratch
LANGUAGES_REPO via the existing LANGUAGES_REPO env var -- so every command
here still runs for real (real git, real msginit/msgmerge, real
sphinx-build via sphinx_to_hugo.py), just against fast, disposable
fixture content instead of the real corpus. The real corpus is covered
separately (see docs/TODO/todo-sphinx-devdocs-spike.md's full-sweep
verification, run manually, not CI-gated).

Run directly: python3 tests/translations_sh/test_devdocs_workflow.py
"""

import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
TRANSLATIONS_SH = REPO_ROOT / "translations.sh"

FAILURES = []


def check(condition: bool, message: str) -> None:
    if condition:
        print("ok:", message)
    else:
        print("FAIL:", message)
        FAILURES.append(message)


def run(cmd, **kwargs):
    return subprocess.run(cmd, capture_output=True, text=True, **kwargs)


def run_ok(cmd, **kwargs):
    result = run(cmd, **kwargs)
    if result.returncode != 0:
        raise RuntimeError(
            "command failed ({}): {}\n--- stdout ---\n{}\n--- stderr ---\n{}".format(
                result.returncode, " ".join(str(c) for c in cmd), result.stdout, result.stderr
            )
        )
    return result


FIXTURE_FILES = {
    "index.rst": "Fixture Dev Docs\n================\n\nRoot index page.\n",
    "auth/authentication.rst": "Authentication\n==============\n\nHow authentication works.\n",
    "migrations/tools/config.rst": "Config Tool\n===========\n\nA nested migrations tool page.\n",
}


def make_fake_upstream(base: pathlib.Path) -> pathlib.Path:
    """Builds a real, tiny local git repo with a development/ subtree
    (3 fixture files, including one nested two levels deep to exercise
    PO-path mirroring and devdocs-build's chapter/slug derivation), and
    a real clone of it -- so ensure_devdocs_checkout's `git pull --ff-only`
    against an actual remote succeeds for real, not mocked. Returns the
    clone's path (what DEVDOCS_UPSTREAM_CHECKOUT should point at).
    """
    bare = base / "fake-upstream.git"
    run_ok(["git", "init", "--bare", "-q", str(bare)])

    seed = base / "seed"
    seed.mkdir()
    run_ok(["git", "init", "-q", str(seed)])
    run_ok(["git", "-C", str(seed), "config", "user.email", "test@example.com"])
    run_ok(["git", "-C", str(seed), "config", "user.name", "Test"])
    dev_dir = seed / "development"
    for rel, content in FIXTURE_FILES.items():
        path = dev_dir / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    run_ok(["git", "-C", str(seed), "add", "."])
    run_ok(["git", "-C", str(seed), "commit", "-q", "-m", "seed"])
    run_ok(["git", "-C", str(seed), "branch", "-M", "3.3.x"])
    run_ok(["git", "-C", str(seed), "remote", "add", "origin", str(bare)])
    run_ok(["git", "-C", str(seed), "push", "-q", "origin", "3.3.x"])

    # Sparse clone, matching exactly what ensure_devdocs_checkout's own
    # first-run branch produces (plain "git clone" would leave
    # sparse-checkout uninitialized, and "sparse-checkout add" -- what
    # the existing-checkout branch runs -- requires it to already be
    # initialized; confirmed by a first version of this fixture using a
    # plain clone, which made "git sparse-checkout add development" fail
    # with "unable to load existing sparse-checkout patterns").
    clone = base / "checkout"
    run_ok(["git", "clone", "-q", "--branch", "3.3.x", "--filter=blob:none", "--sparse", str(bare), str(clone)])
    run_ok(["git", "-C", str(clone), "sparse-checkout", "set", "development"])
    return clone


def translations_sh(args, env_extra, **kwargs):
    import os

    env = dict(os.environ)
    env.update(env_extra)
    return run([str(TRANSLATIONS_SH)] + args, env=env, **kwargs)


def test_full_workflow():
    # build/gettext/development/ is a real, shared, repo-level directory
    # (not scoped to this test's own tempdir) -- devdocs-extract doesn't
    # clean stale .pot files from a prior run before writing new ones
    # (matching the documentation family's own cmd_extract, which has
    # the same non-cleaning behavior), so this test must ensure it starts
    # from empty itself, or leftover .pot files from an unrelated prior
    # run (manual testing, another test run) would make devdocs-init/
    # devdocs-build below process far more than this test's 3 fixture
    # files.
    pot_dir = REPO_ROOT / "build" / "gettext" / "development"
    shutil.rmtree(pot_dir, ignore_errors=True)

    with tempfile.TemporaryDirectory(prefix="devdocs_workflow_test_") as tmp:
        base = pathlib.Path(tmp)
        checkout = make_fake_upstream(base)
        languages_repo = base / "languages-repo"
        (languages_repo / "xx").mkdir(parents=True)
        (languages_repo / "xx" / "language.toml").write_text(
            'code = "xx"\nname = "Test"\nnative_name = "Test"\nlocale = "xx_XX"\nstatus = "active"\n',
            encoding="utf-8",
        )
        (languages_repo / "metadata").mkdir()
        (languages_repo / "metadata" / "source.json").write_text(
            json.dumps({"languages": {}, "upstream": {"repository": "phpbb/documentation", "branch": "3.3.x"}}),
            encoding="utf-8",
        )

        env = {"DEVDOCS_UPSTREAM_CHECKOUT": str(checkout), "LANGUAGES_REPO": str(languages_repo)}

        # --- devdocs-extract ---
        r = translations_sh(["devdocs-extract"], env)
        check(r.returncode == 0, "devdocs-extract exits successfully against the fixture checkout")
        pot_dir = REPO_ROOT / "build" / "gettext" / "development"
        pots = sorted(p.relative_to(pot_dir).with_suffix("") for p in pot_dir.rglob("*.pot"))
        check(
            [str(p) for p in pots] == ["auth/authentication", "index", "migrations/tools/config"],
            "devdocs-extract produces exactly the 3 fixture .pot files at mirrored paths",
        )

        # --- devdocs-init ---
        r = translations_sh(["devdocs-init", "xx"], env)
        check(r.returncode == 0, "devdocs-init exits successfully (real output: {!r})".format(r.stderr[-300:] if r.returncode else ""))
        po_dir = languages_repo / "xx" / "development"
        expected_pos = {"index.po", "auth/authentication.po", "migrations/tools/config.po"}
        actual_pos = {str(p.relative_to(po_dir)) for p in po_dir.rglob("*.po")}
        check(actual_pos == expected_pos, "devdocs-init creates PO catalogs at paths that mirror the RST tree exactly, including the nested case")

        po_text = (po_dir / "auth" / "authentication.po").read_text(encoding="utf-8")
        check('"Language: xx\\n"' in po_text, "devdocs-init patches the PO Language: header to the bare phpBB code")

        source_json = json.loads((languages_repo / "metadata" / "source.json").read_text())
        check("development" in source_json["languages"]["xx"], "devdocs-init records a development-family source commit")
        check(
            source_json["upstream"].get("development", {}).get("path") == "development"
            and source_json["upstream"].get("documentation", {}).get("repository") == "phpbb/documentation",
            "source.json's upstream object is per-family after devdocs-init, with the legacy documentation entry preserved",
        )

        # --- devdocs-status ---
        r = translations_sh(["devdocs-status", "xx"], env)
        check(r.returncode == 0, "devdocs-status exits successfully")
        check("Catalogs present: 3/3 files" in r.stdout, "devdocs-status reports full 3/3 coverage for the fixture corpus")
        check("up to date" in r.stdout, "devdocs-status reports the source as up to date right after devdocs-init")

        # --- devdocs-check: clean (untranslated but syntactically valid) ---
        r = translations_sh(["devdocs-check", "xx"], env)
        check(r.returncode == 0, "devdocs-check succeeds (exit 0) with all catalogs present, valid and reconstructable")
        check("Result: COMPLETE" in r.stdout, "devdocs-check reports COMPLETE for full, valid, untranslated coverage")

        # --- devdocs-check: a missing catalog is reported, not silently skipped ---
        moved = po_dir / "index.po"
        moved_aside = base / "index.po.bak"
        shutil.move(str(moved), str(moved_aside))
        r = translations_sh(["devdocs-check", "xx"], env)
        check(r.returncode != 0, "devdocs-check fails (nonzero exit) when a catalog is missing")
        check("missing catalog" in r.stdout, "devdocs-check's output names the missing-catalog case, not a silent skip")
        shutil.move(str(moved_aside), str(moved))

        # --- devdocs-check: a corrupted PO is reported ---
        corrupted = po_dir / "auth" / "authentication.po"
        original_text = corrupted.read_text(encoding="utf-8")
        corrupted.write_text(original_text + '\nmsgid "broken\n', encoding="utf-8")
        r = translations_sh(["devdocs-check", "xx"], env)
        check(r.returncode != 0, "devdocs-check fails (nonzero exit) when a PO is syntactically corrupted")
        check("PO syntax invalid" in r.stdout, "devdocs-check's output names the corrupted PO, not a silent skip")
        corrupted.write_text(original_text, encoding="utf-8")

        # --- devdocs-build ---
        before_site_content = set((REPO_ROOT / "site" / "content").rglob("*")) if (REPO_ROOT / "site" / "content").exists() else set()
        before_content = set((REPO_ROOT / "content").rglob("*"))
        r = translations_sh(["devdocs-build", "xx"], env)
        check(r.returncode == 0, "devdocs-build exits successfully")
        preview_dir = REPO_ROOT / "build" / "devdocs-preview" / "xx" / "development"
        check(
            (preview_dir / "auth" / "authentication" / "index.md").is_file(),
            "devdocs-build writes a real page for the single-nesting-level fixture file",
        )
        check(
            (preview_dir / "migrations" / "tools-config" / "index.md").is_file(),
            "devdocs-build flattens a two-level-nested docname's slug via hyphen, matching phpbbdocs_hugo_devdocs.sh's convention",
        )
        check(
            not (preview_dir / "index").exists() and not list(preview_dir.glob("index*")),
            "devdocs-build skips the single-segment root 'index' docname (no chapter to publish it under)",
        )
        front_matter = (preview_dir / "auth" / "authentication" / "index.md").read_text(encoding="utf-8")
        check("translationKey: development-auth-authentication" in front_matter, "devdocs-build sets the expected translationKey")

        after_site_content = set((REPO_ROOT / "site" / "content").rglob("*")) if (REPO_ROOT / "site" / "content").exists() else set()
        after_content = set((REPO_ROOT / "content").rglob("*"))
        check(before_site_content == after_site_content, "devdocs-build never touches site/content/ (the live dev-docs pipeline's own output)")
        check(before_content == after_content, "devdocs-build never touches content/ (the documentation family's own tracked source)")

        shutil.rmtree(REPO_ROOT / "build" / "devdocs-preview", ignore_errors=True)
        shutil.rmtree(pot_dir, ignore_errors=True)


def test_upstream_metadata_migration():
    sys.path.insert(0, str(REPO_ROOT / "translations"))
    import lib

    legacy = {"upstream": {"repository": "phpbb/documentation", "branch": "3.3.x"}, "languages": {}}
    migrated = lib.migrate_upstream_metadata(dict(legacy))
    check(
        migrated["upstream"] == {"documentation": {"repository": "phpbb/documentation", "branch": "3.3.x"}},
        "a legacy flat upstream object migrates to the per-family shape, preserving its fields under 'documentation'",
    )

    already_migrated = {"upstream": {"documentation": {"repository": "x", "branch": "y"}}, "languages": {}}
    result = lib.migrate_upstream_metadata(dict(already_migrated))
    check(result == already_migrated, "migration is idempotent on an already-per-family-shaped upstream object")

    empty = {"upstream": {}, "languages": {}}
    result = lib.migrate_upstream_metadata(dict(empty))
    check(result == empty, "migration is a no-op on an empty upstream object")


def test_devdocs_po_path_mirrors_nesting():
    sys.path.insert(0, str(REPO_ROOT / "translations"))
    import lib

    path = lib.devdocs_po_path(pathlib.Path("/repo"), "fr", "migrations/tools/config")
    check(
        str(path) == "/repo/fr/development/migrations/tools/config.po",
        "devdocs_po_path mirrors a multi-segment docname's directory structure exactly, not a flattened slug",
    )


def main() -> int:
    test_upstream_metadata_migration()
    test_devdocs_po_path_mirrors_nesting()
    test_full_workflow()

    print()
    if FAILURES:
        print("{} check(s) FAILED:".format(len(FAILURES)))
        for message in FAILURES:
            print(" -", message)
        return 1
    print("All checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
