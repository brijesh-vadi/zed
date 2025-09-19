#!/usr/bin/env bash

set -euo pipefail

echo "🔄 Syncing fork with official Zed repository..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

# Check if upstream remote exists
if ! git remote | grep -q "^upstream$"; then
    print_warning "Upstream remote not found. Adding official Zed repo as upstream..."
    git remote add upstream https://github.com/zed-industries/zed.git
    print_success "Added upstream remote"
fi

# Stash any uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    print_warning "Uncommitted changes found. Stashing them..."
    git stash push -m "Auto-stash before sync $(date)"
    STASHED=true
else
    STASHED=false
fi

# Create a backup branch of current state
BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
print_status "Creating backup branch: $BACKUP_BRANCH"
git branch "$BACKUP_BRANCH"

# Fetch latest changes from upstream
print_status "Fetching latest changes from upstream..."
git fetch upstream

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_status "Switching to main branch..."
    git checkout main
fi

# Get the commit hash of our custom feature
FEATURE_COMMIT=$(git log --oneline --grep="Add single-file diff feature" | head -n1 | cut -d' ' -f1)

if [ -z "$FEATURE_COMMIT" ]; then
    print_error "Could not find your single-file diff feature commit!"
    print_error "Please ensure your feature is committed with the message 'Add single-file diff feature'"
    exit 1
fi

print_status "Found your feature commit: $FEATURE_COMMIT"

# Merge upstream changes
print_status "Merging upstream changes..."
if git merge upstream/main --no-edit; then
    print_success "Successfully merged upstream changes"
else
    print_error "Merge conflicts detected!"
    print_warning "You'll need to resolve conflicts manually."
    print_warning "After resolving conflicts:"
    print_warning "  1. Run: git add <resolved-files>"
    print_warning "  2. Run: git commit"
    print_warning "  3. Run: git cherry-pick $FEATURE_COMMIT"
    exit 1
fi

# Check if our feature commit is still in the history
if git log --oneline | grep -q "$FEATURE_COMMIT"; then
    print_success "Your single-file diff feature is still intact!"
else
    print_warning "Your feature may have been affected by the merge."
    print_status "Re-applying your single-file diff feature..."

    # Try to cherry-pick our feature
    if git cherry-pick "$FEATURE_COMMIT"; then
        print_success "Successfully re-applied your single-file diff feature"
    else
        print_error "Failed to re-apply feature automatically"
        print_warning "You may need to manually re-apply your changes"
        print_warning "Your backup is available in branch: $BACKUP_BRANCH"
        exit 1
    fi
fi

# Restore stashed changes if any
if [ "$STASHED" = true ]; then
    print_status "Restoring stashed changes..."
    if git stash pop; then
        print_success "Restored stashed changes"
    else
        print_warning "Could not restore stashed changes automatically"
        print_warning "Check 'git stash list' to recover them manually"
    fi
fi

# Push changes to your fork
print_status "Pushing updated changes to your fork..."
git push origin main

print_success "🎉 Sync completed successfully!"
print_status "Summary:"
echo "  ✅ Merged latest changes from official Zed"
echo "  ✅ Preserved your single-file diff feature"
echo "  ✅ Created backup branch: $BACKUP_BRANCH"
echo "  ✅ Pushed changes to your fork"

echo ""
print_status "Next steps:"
echo "  1. Test your custom build: cargo build --release"
echo "  2. Create new app bundle: ./rebuild-app.sh"
echo "  3. If everything works, delete backup branch: git branch -d $BACKUP_BRANCH"
