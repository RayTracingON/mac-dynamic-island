#!/bin/bash

# Fix Xcode Duplicate File References
# This script removes duplicate file references from the Xcode project

set -e

PROJECT_FILE="Mac灵动岛.xcodeproj/project.pbxproj"
BACKUP_FILE="Mac灵动岛.xcodeproj/project.pbxproj.backup"

echo "🔧 Fixing Xcode duplicate file references..."
echo ""

# Backup the project file
echo "📦 Creating backup..."
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"
echo ""

# Close Xcode first
echo "⚠️  IMPORTANT: Close Xcode before running this fix!"
echo "Press Enter to continue, or Ctrl+C to abort..."
read

# Remove duplicate TouchIDManager references (keep only Security/)
echo "🗑️  Removing duplicate TouchIDManager references..."
# Remove the line with 51D0247A (Utils/TouchIDManager.swift)
sed -i '' '/51D0247A2F1610E400B1FF0F.*TouchIDManager.swift/d' "$PROJECT_FILE"

# Remove duplicate FeatureFlags references (keep only Configuration/)
echo "🗑️  Removing duplicate FeatureFlags references..."
# Remove the line with 51579D00 (State/FeatureFlags.swift)
sed -i '' '/51579D002F14E1A300D13091.*FeatureFlags.swift/d' "$PROJECT_FILE"

# Remove duplicate OnboardingView references (keep only Onboarding/)
echo "🗑️  Removing duplicate OnboardingView references..."
# This one might have multiple, we need to check the file references section

# Remove duplicate BoringHeader references (keep only Views/)
echo "🗑️  Removing duplicate BoringHeader references..."
# We need to find the right UUID for the duplicate

echo ""
echo "✅ Done! Duplicate references removed."
echo ""
echo "📝 Next steps:"
echo "1. Open Xcode"
echo "2. Clean build folder (Shift + ⌘ + K)"
echo "3. Build (⌘B)"
echo ""
echo "If something goes wrong, restore from backup:"
echo "cp \"$BACKUP_FILE\" \"$PROJECT_FILE\""
