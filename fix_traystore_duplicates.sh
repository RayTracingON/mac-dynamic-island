#!/bin/bash

PROJECT_FILE="Mac灵动岛.xcodeproj/project.pbxproj"
BACKUP_FILE="Mac灵动岛.xcodeproj/project.pbxproj.backup_traystore"

echo "Using project file: $PROJECT_FILE"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project file not found!"
    exit 1
fi

echo "Creating backup at $BACKUP_FILE"
cp "$PROJECT_FILE" "$BACKUP_FILE"

echo "Removing duplicate TrayStore references (Models)..."

# Remove the PBXBuildFile reference
# 51E1CA902F23539F009A87D2 /* TrayStore.swift in Sources */
sed -i '' '/51E1CA902F23539F009A87D2/d' "$PROJECT_FILE"

# Remove the PBXFileReference and its entry in the PBXGroup
# 51E1CA8F2F23539F009A87D2 /* TrayStore.swift */
sed -i '' '/51E1CA8F2F23539F009A87D2/d' "$PROJECT_FILE"

echo "Done. Please restart Xcode and Clean Build Folder."
