# Agent notes — Zed fork with single-file diff default

Quick-reference for any AI agent helping with this fork. Read this once and you have full context.

## What this repo is

A personal fork of [zed-industries/zed](https://github.com/zed-industries/zed). The original custom feature (click a file in the git panel → open only that file's diff) is now **upstream**. Official Zed added `git_panel.entry_primary_click_action` (`project_diff` | `file_diff` | `view_file`) and `SoloDiffView`.

This fork carries two small customizations on top of upstream:

1. **Default click action** is `file_diff` instead of upstream's `project_diff`.
2. **Focus fix for the single-file diff**: after a click opens `SoloDiffView`, focus returns to the git panel. Without it, the diff editor takes focus and pressing `delete`/`backspace` deletes text in the file instead of triggering the panel's `git::RestoreFile` (discard changes) binding.

Last synced: upstream `main` at Zed **1.32.0** (merge `ef189ed9f8`, 2026-11-26). The pre-sync 1.20.0 state is on branch `backup-pre-1.32-20261126`.

Remotes:
- `origin` → `https://github.com/brijesh-vadi/zed.git` (the fork, push target)
- `upstream` → `https://github.com/zed-industries/zed.git` (official Zed, pull-only)

## Where the fork default lives

Do **not** re-port the old `single_file_diff_on_click` / `deploy_single_file` / `single_file_filter` patch. That code is obsolete. Upstream's `GitPanelClickBehavior::FileDiff` opens `SoloDiffView`.

Preserve these default changes during merges:

| File | What's in it |
|---|---|
| `assets/settings/default.json` | `"entry_primary_click_action": "file_diff"` under `"git_panel"` |
| `crates/settings_content/src/settings_content.rs` | `#[default]` on `GitPanelClickBehavior::FileDiff` (upstream defaults `ProjectDiff`) |
| `crates/git_ui/src/git_panel.rs` | `open_solo_diff`: collects the `SoloDiffView::open_or_focus` tasks, awaits them with `join_all`, then refocuses `self.focus_handle` (upstream just calls `.detach_and_notify_err` on each task, leaving focus in the diff) |

Secondary/cmd-click still swaps to the project-wide diff. Double-click / explicit view-file actions still open the file.

If a user's `settings.json` still has the old `"single_file_diff_on_click": true`, it is ignored. They can delete it; the fork default already does the same thing.

## Build (Apple Silicon, DMG on Desktop)

```sh
./rebuild-app.sh
```

Produces `/Users/brijesh/Desktop/Zed.app` and `/Users/brijesh/Desktop/Zed.dmg`. Apple Silicon only (`aarch64-apple-darwin`), runs `cargo build --release -j 8`.

### Prerequisites (one-time)

1. `rustup` (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`). The agent's shell may not have it on `PATH`; prefix commands with `export PATH="$HOME/.cargo/bin:$PATH"`. `rust-toolchain.toml` pins the exact version, and rustup installs it on the first `cargo` call.
2. **Full Xcode** (not just CLT — needed for Metal shader compiler). After install: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`, `sudo xcodebuild -license accept`, and `sudo xcodebuild -runFirstLaunch` (otherwise step 3 fails with `Library not loaded: .../CoreSimulator.framework`)
3. **Metal Toolchain** (Xcode 26+ ships without it): `xcodebuild -downloadComponent MetalToolchain`. If you skip this you'll get `cannot execute tool 'metal' due to missing Metal Toolchain` partway into the build.
4. `cmake` (`brew install cmake`) — wasmtime-c-api dep
5. **~40 GB free disk** on the volume holding the repo. `target/` grows to 30-40 GB.

Verify with: `rustc --version && cmake --version && xcrun -find metal`.

### Build flags / version bump

`rebuild-app.sh` writes the Info.plist version inline. When upstream bumps the version, update both lines:

```
CFBundleShortVersionString → match crates/zed/Cargo.toml `version`
CFBundleVersion            → same with dots removed and zero-padded (e.g. 1.4.0 → 1004000)
```

## Sync with upstream (merge workflow)

```sh
git fetch upstream
git merge upstream/main
# resolve conflicts (see below)
git commit
git push origin main
./rebuild-app.sh
```

There's also `sync-with-upstream.sh` for the automated version, but doing it manually is safer when the merge is large.

### Conflict resolution playbook

Conflicts may land in `git_panel.rs`, `project_diff.rs`, `git_panel_settings.rs`, `settings_content.rs`, `default.json`, and `Cargo.toml`. Rules:

1. **Take upstream for `git_panel.rs` / `project_diff.rs`.** Do not re-apply `open_single_file_diff`, `deploy_single_file`, or `single_file_filter`. Official `open_solo_diff` / `SoloDiffView` replaced that.
2. **Re-apply the default and the focus fix.** After the merge, `git_panel.entry_primary_click_action` must be `"file_diff"` in `assets/settings/default.json`, and `GitPanelClickBehavior::FileDiff` must keep `#[default]`. If `git_panel.rs` conflicts in `open_solo_diff`, take upstream and then re-add the refocus (see table above). In `default.json`, upstream keeps adding settings right after `entry_primary_click_action` (e.g. `commit_editor` in 1.32); keep both sides, only changing the value to `"file_diff"`.
3. **Drop leftover `single_file_diff_on_click` fields** if a merge re-introduces them. They will panic on `.unwrap()` if the key is missing from default.json.
4. **For `Cargo.toml` bundle metadata conflicts**: take upstream (`[package.metadata.bundle-dev]`).
5. **Validate before committing the merge**: `cargo check --package git_ui --target aarch64-apple-darwin` is the quickest signal that the resolution compiles. If it passes, the build will too.

### Post-merge verification

After the build finishes, confirm the official single-file view is in the binary:

```sh
nm /Users/brijesh/Desktop/Zed.app/Contents/MacOS/zed | grep -i SoloDiff
```

Should print symbols mentioning `SoloDiffView`. Also confirm defaults:

```sh
grep -n entry_primary_click_action assets/settings/default.json
```

Must be `"file_diff"`.

Smoke test the running app:
- Click a file in git panel → only that file's diff (`SoloDiffView`)
- Then press `delete` → "discard changes" prompt appears; file text is untouched
- Cmd-click / secondary click → project-wide diff
- `entry_primary_click_action` of `project_diff` still available in settings
- Regular "Project Diff" action → all files

## Common gotchas

- **`cargo: command not found`** in the agent shell → `export PATH="$HOME/.cargo/bin:$PATH"`
- **First build on a fresh machine** → `cargo check -p git_ui` took ~5 min (mostly dependency downloads); release build ~9 min on an M-series Mac with a warm cache

- **`metal` not found** → run `xcodebuild -downloadComponent MetalToolchain`
- **`dispatch/dispatch.h` not found** → `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=$(xcrun --show-sdk-path)"`
- **Disk fills up partway through build** → `target/` can hit 30-40 GB; ensure 40 GB+ free before starting
- **Build appears to hang after an error** → cargo waits for in-flight parallel jobs to finish before exiting; let it complete on its own, don't kill

## Related files in this repo

- `FORK-SYNC-GUIDE.md` — **outdated** sync guide from the original `single_file_diff_on_click` patch era. Its "custom changes" section describes code that no longer exists; trust this file instead.
- `sync-with-upstream.sh` — automated sync helper. It looks for a commit named "Add single-file diff feature" and may try to cherry-pick it after a conflict; **don't let it**, that old patch is obsolete. Prefer the manual merge above.
- `rebuild-app.sh` — the build script you'll run
- `docs/src/development/macos.md` — official Zed macOS build docs (has Metal Toolchain note in troubleshooting)
