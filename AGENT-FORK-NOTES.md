# Agent notes — Zed fork with single-file diff feature

Quick-reference for any AI agent helping with this fork. Read this once and you have full context.

## What this repo is

A personal fork of [zed-industries/zed](https://github.com/zed-industries/zed) with **one custom feature**: clicking a file in the git panel opens a diff filtered to just that file (instead of the multi-file scrollable diff). Setting name: `single_file_diff_on_click`, defaults to `true`.

Remotes:
- `origin` → `https://github.com/brijesh-vadi/zed.git` (the fork, push target)
- `upstream` → `https://github.com/zed-industries/zed.git` (official Zed, pull-only)

## Where the custom feature lives

Touch these files carefully during merges — preserve all four.

| File | What's in it |
|---|---|
| `crates/settings_content/src/settings_content.rs` | `pub single_file_diff_on_click: Option<bool>` field on `GitPanelSettingsContent` |
| `crates/git_ui/src/git_panel_settings.rs` | `pub single_file_diff_on_click: bool` field + merge logic |
| `crates/git_ui/src/git_panel.rs` | `fn open_single_file_diff(...)` + click handler that branches on the setting |
| `crates/git_ui/src/project_diff.rs` | `single_file_filter: Option<GitStatusEntry>` field, `pub fn deploy_single_file(...)`, and the `retain` filter inside `refresh()` |
| `assets/settings/default.json` | `"single_file_diff_on_click": true` under `"git_panel"` |

Note: `crates/settings/src/settings_content.rs` (path in the older `FORK-SYNC-GUIDE.md`) is **wrong** — upstream renamed the crate to `settings_content`. Use the path above.

## Build (Apple Silicon, DMG on Desktop)

```sh
./rebuild-app.sh
```

Produces `/Users/brijesh/Desktop/Zed.app` and `/Users/brijesh/Desktop/Zed.dmg`. Apple Silicon only (`aarch64-apple-darwin`), runs `cargo build --release -j 8`.

### Prerequisites (one-time)

1. `rustup` (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
2. **Full Xcode** (not just CLT — needed for Metal shader compiler). After install: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
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

Conflicts almost always land in `git_panel.rs`, `project_diff.rs`, `git_panel_settings.rs`, and sometimes `Cargo.toml`. Rules:

1. **Always preserve the four feature files' custom code.** If upstream renamed a symbol/variable/function around our code, adapt — don't drop our logic.
2. **Drop stale custom helpers that upstream has obsoleted.** Example: an earlier merge had a `file_history()` function referencing `FileHistoryView::open`. Upstream PR #50288 replaced `FileHistoryView` with a git graph view — keeping `file_history()` would fail to compile. Remove it during the merge.
3. **For the click handler in `git_panel.rs`**: upstream added `event.click_count() > 1` for double-click-to-open-file (PR #47989). The merged condition should combine both behaviors:
   ```rust
   if event.click_count() > 1 || event.modifiers().secondary() {
       this.open_file(...)
   } else if event.modifiers().platform || event.modifiers().control {
       this.open_file(...)
   } else {
       let settings = GitPanelSettings::get_global(cx);
       if settings.single_file_diff_on_click {
           this.open_single_file_diff(...)
       } else {
           this.open_diff(...)
       }
   }
   ```
4. **For `Cargo.toml` bundle metadata conflicts**: upstream renamed `[package.metadata.bundle]` → `[package.metadata.bundle-dev]` for consistency. Take upstream's name.
5. **Validate before committing the merge**: `cargo check --package git_ui --target aarch64-apple-darwin` is the quickest signal that the resolution compiles. If it passes, the build will too. ~7 min cold, much faster warm.

### Post-merge verification

After the build finishes, confirm the feature is in the binary:

```sh
nm /Users/brijesh/Desktop/Zed.app/Contents/MacOS/zed | grep deploy_single_file
```

Should print at least one symbol mentioning `ProjectDiff::deploy_single_file`. If empty, the merge dropped your code.

Smoke test the running app:
- Click a file in git panel → only that file's diff shown, tab reads `Diff: <filename>`
- Double-click → opens the actual file
- Cmd-click → opens the actual file
- `ProjectDiff::deploy_at` (regular "Project Diff" action) → all files

## Common gotchas

- **`metal` not found** → run `xcodebuild -downloadComponent MetalToolchain`
- **`dispatch/dispatch.h` not found** → `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=$(xcrun --show-sdk-path)"`
- **Disk fills up partway through build** → `target/` can hit 30-40 GB; ensure 40 GB+ free before starting
- **Build appears to hang after an error** → cargo waits for in-flight parallel jobs to finish before exiting; let it complete on its own, don't kill

## Related files in this repo

- `FORK-SYNC-GUIDE.md` — older, more prose-heavy sync guide. Has one wrong path (`crates/settings/...` vs `crates/settings_content/...`); otherwise still useful for context.
- `sync-with-upstream.sh` — automated sync helper
- `rebuild-app.sh` — the build script you'll run
- `docs/src/development/macos.md` — official Zed macOS build docs (has Metal Toolchain note in troubleshooting)
