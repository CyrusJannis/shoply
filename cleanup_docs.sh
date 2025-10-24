#!/bin/bash

# Documentation Cleanup Script
# This script organizes documentation files and removes duplicates

echo "🧹 Starting documentation cleanup..."

# Create archive directory
mkdir -p docs/archive

# Files to archive (move to docs/archive/)
echo "📦 Archiving old implementation documents..."
mv SMART_HOME_IMPLEMENTATION_PLAN.md docs/archive/ 2>/dev/null
mv SMART_HOME_IMPLEMENTATION_SUMMARY.md docs/archive/ 2>/dev/null
mv SMART_HOME_QUICKSTART.md docs/archive/ 2>/dev/null
mv RECIPE_FILTERS_IMPLEMENTATION.md docs/archive/ 2>/dev/null
mv RECIPE_FILTERS_QUICKSTART.md docs/archive/ 2>/dev/null
mv ONBOARDING_IMPLEMENTATION_SUMMARY.md docs/archive/ 2>/dev/null
mv ONBOARDING_QUICKSTART.md docs/archive/ 2>/dev/null
mv IMPLEMENTATION_SUMMARY.md docs/archive/ 2>/dev/null
mv NAVIGATION_REDESIGN_SUMMARY.md docs/archive/ 2>/dev/null
mv NAVIGATION_QUICK_REFERENCE.md docs/archive/ 2>/dev/null
mv DESIGN_CHANGES.md docs/archive/ 2>/dev/null
mv DESIGN_UPDATE.md docs/archive/ 2>/dev/null
mv MIGRATION_NOTES.md docs/archive/ 2>/dev/null
mv NEXT_STEPS.md docs/archive/ 2>/dev/null
mv PROJECT_COMPLETE.md docs/archive/ 2>/dev/null

# Create setup guides directory
mkdir -p docs/setup

# Move setup guides
echo "📚 Organizing setup guides..."
mv APPLE_SIGNIN_QUICKSTART.md docs/setup/ 2>/dev/null
mv APPLE_SIGNIN_SETUP.md docs/setup/ 2>/dev/null
mv APPLE_SIGNIN_XCODE_SETUP.md docs/setup/ 2>/dev/null
mv GOOGLE_NATIVE_SIGNIN_SETUP.md docs/setup/ 2>/dev/null
mv GOOGLE_SIGNIN_SETUP.md docs/setup/ 2>/dev/null
mv OAUTH_SETUP.md docs/setup/ 2>/dev/null
mv SHARE_LINK_SETUP.md docs/setup/ 2>/dev/null
mv IOS_WIDGET_SETUP.md docs/setup/ 2>/dev/null
mv GITHUB_ACTIONS_SETUP.md docs/setup/ 2>/dev/null
mv WICHTIG_ENV_SETUP.md docs/setup/ 2>/dev/null

# Create deployment directory
mkdir -p docs/deployment

# Move deployment guides
echo "🚀 Organizing deployment guides..."
mv TESTFLIGHT_INTEGRATION.md docs/deployment/ 2>/dev/null
mv TESTFLIGHT_INTERNAL_UPDATE.md docs/deployment/ 2>/dev/null
mv TESTFLIGHT_SETUP.md docs/deployment/ 2>/dev/null
mv TESTFLIGHT_UPLOAD_ANLEITUNG.md docs/deployment/ 2>/dev/null
mv RELEASE_NOTES_v1.1.0.md docs/deployment/ 2>/dev/null

# Create reference directory
mkdir -p docs/reference

# Move reference docs
echo "📖 Organizing reference documentation..."
mv PRODUCT_CLASSIFICATION.md docs/reference/ 2>/dev/null

# Keep in root (core documentation)
echo "✅ Keeping core documentation in root:"
echo "   - README.md"
echo "   - SETUP_GUIDE.md"
echo "   - DEVELOPER_GUIDE.md"
echo "   - PROJECT_STATUS.md"
echo "   - GETTING_STARTED.md"
echo "   - START_HERE.md"
echo "   - QUICKSTART.md"
echo "   - COMPREHENSIVE_IMPLEMENTATION_PLAN.md"
echo "   - LICENSE"

# Create index file
echo "📝 Creating documentation index..."
cat > docs/INDEX.md << 'EOF'
# Documentation Index

## Core Documentation (Root Directory)
- `README.md` - Project overview and main documentation
- `SETUP_GUIDE.md` - Development environment setup
- `DEVELOPER_GUIDE.md` - Development guidelines and best practices
- `PROJECT_STATUS.md` - Current project status and progress
- `GETTING_STARTED.md` - Quick start guide for new developers
- `START_HERE.md` - Entry point for contributors
- `QUICKSTART.md` - Quick reference guide
- `COMPREHENSIVE_IMPLEMENTATION_PLAN.md` - Complete implementation roadmap
- `LICENSE` - Project license

## Setup Guides (`docs/setup/`)
- Apple Sign-In setup guides
- Google Sign-In setup guides
- OAuth configuration
- Share link setup
- iOS widget setup
- GitHub Actions setup
- Environment setup

## Deployment (`docs/deployment/`)
- TestFlight integration guides
- Release notes
- Upload instructions

## Reference (`docs/reference/`)
- Product classification
- Technical specifications

## Archive (`docs/archive/`)
- Old implementation documents
- Deprecated guides
- Historical documentation

## Navigation
- [Back to Root](../)
- [Setup Guides](setup/)
- [Deployment Guides](deployment/)
- [Reference Docs](reference/)
- [Archive](archive/)
EOF

echo ""
echo "✨ Documentation cleanup complete!"
echo ""
echo "📊 Summary:"
echo "   - Core docs: 9 files (kept in root)"
echo "   - Setup guides: Moved to docs/setup/"
echo "   - Deployment guides: Moved to docs/deployment/"
echo "   - Reference docs: Moved to docs/reference/"
echo "   - Archived: Moved to docs/archive/"
echo ""
echo "📖 See docs/INDEX.md for complete documentation index"
