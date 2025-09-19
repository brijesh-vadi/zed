# Fork Sync Guide: Keeping Your Zed Fork Updated

This guide explains how to keep your forked Zed repository in sync with the official Zed repository while preserving your custom single-file diff feature.

## Repository Setup

Your repository structure:
- **Origin**: `https://github.com/brijesh-vadi/zed.git` (your fork)
- **Upstream**: `https://github.com/zed-industries/zed.git` (official Zed)

## Automated Sync Process

### Quick Sync (Recommended)
Run the automated sync script:
```bash
./sync-with-upstream.sh
```

This script will:
1. ✅ Fetch latest changes from official Zed
2. ✅ Merge them into your main branch
3. ✅ Preserve your single-file diff feature
4. ✅ Create a backup branch
5. ✅ Push updates to your fork

### Rebuild After Sync
After syncing, rebuild your app:
```bash
./rebuild-app.sh
```

This will create a fresh `Zed.app` and `Zed.dmg` with the latest changes.

## Manual Sync Process

If you prefer manual control:

### 1. Fetch Upstream Changes
```bash
git fetch upstream
```

### 2. Create Backup Branch
```bash
git branch backup-$(date +%Y%m%d) main
```

### 3. Merge Upstream Changes
```bash
git checkout main
git merge upstream/main
```

### 4. Resolve Conflicts (if any)
If there are conflicts in your custom files:
- `assets/settings/default.json`
- `crates/git_ui/src/git_panel.rs`
- `crates/git_ui/src/git_panel_settings.rs`
- `crates/git_ui/src/project_diff.rs`
- `crates/settings/src/settings_content.rs`

Resolve them manually, then:
```bash
git add <resolved-files>
git commit
```

### 5. Push to Your Fork
```bash
git push origin main
```

## Your Custom Changes

Your single-file diff feature includes these changes:

### 1. Settings Addition (`assets/settings/default.json`)
```json
"single_file_diff_on_click": true
```

### 2. Settings Structure (`crates/settings/src/settings_content.rs`)
```rust
pub single_file_diff_on_click: Option<bool>,
```

### 3. Git Panel Settings (`crates/git_ui/src/git_panel_settings.rs`)
```rust
pub single_file_diff_on_click: bool,
```

### 4. Click Behavior (`crates/git_ui/src/git_panel.rs`)
- Modified click handler to respect the setting
- Added `display_name()` method as public

### 5. Project Diff (`crates/git_ui/src/project_diff.rs`)
- Added `single_file_filter` field
- Modified `deploy_single_file` method
- Updated tab titles for single-file mode

## Conflict Resolution Tips

### Common Conflicts
1. **Settings files**: Usually easy to resolve - add your setting to the new structure
2. **Git panel code**: May need to adapt to new APIs or structure changes
3. **Dependencies**: New versions might require updates to your code

### Resolution Strategy
1. **Accept upstream changes** for core functionality
2. **Preserve your feature** by re-applying your specific changes
3. **Test thoroughly** after resolving conflicts

## Testing After Sync

### 1. Build Test
```bash
cargo build --release
```

### 2. Feature Test
1. Open a project with Git changes
2. Open Git panel (`Cmd+Shift+G`)
3. Check settings: `"git_panel": {"single_file_diff_on_click": true}`
4. Click on a file → should open single-file diff
5. Tab should show "Diff: filename.txt"

### 3. Full App Test
```bash
./rebuild-app.sh
open /Users/brijesh/Desktop/Zed.app
```

## Sync Schedule Recommendations

### Weekly Sync
```bash
# Every Monday
./sync-with-upstream.sh && ./rebuild-app.sh
```

### Before Important Updates
- Before major Zed releases
- Before presenting your feature
- Before making significant changes

### Emergency Sync
If critical security updates are released:
```bash
./sync-with-upstream.sh
./rebuild-app.sh
# Test immediately
```

## Backup Strategy

### Automatic Backups
The sync script creates automatic backups:
- Format: `backup-YYYYMMDD-HHMMSS`
- Contains your pre-sync state
- Delete after successful testing: `git branch -d backup-<name>`

### Manual Backups
Before major changes:
```bash
git branch feature-backup main
git push origin feature-backup
```

## Troubleshooting

### Sync Script Fails
1. Check git status: `git status`
2. Resolve any uncommitted changes
3. Check network connection
4. Run manual sync process

### Build Fails After Sync
1. Check Rust version: `rustc --version`
2. Update dependencies: `cargo update`
3. Clean build: `cargo clean && cargo build --release`
4. Check for API changes in your custom code

### Feature Broken After Sync
1. Check if your files were modified during merge
2. Compare with backup branch
3. Re-apply your changes manually
4. Test each component individually

## Advanced: Rebasing Strategy

For cleaner history, you can use rebase instead of merge:

```bash
git fetch upstream
git rebase upstream/main
# Resolve conflicts if any
git push --force-with-lease origin main
```

**⚠️ Warning**: Only use `--force-with-lease` if you're the only one working on your fork.

## Getting Help

If you encounter issues:
1. Check the backup branch for your working state
2. Compare changes between versions
3. Test individual components
4. Consider reverting and re-applying changes manually

## Summary

Your workflow should be:
1. **Weekly**: `./sync-with-upstream.sh`
2. **After sync**: `./rebuild-app.sh`
3. **Test**: Verify your feature works
4. **Deploy**: Install new build

This keeps you up-to-date with Zed's latest features while preserving your custom single-file diff functionality!
