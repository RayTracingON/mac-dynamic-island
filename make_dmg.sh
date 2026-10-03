#!/bin/bash

# DMG Packaging Script for Mac灵动岛
# Wraps an exported, Developer ID-signed app in a disk image with an Applications shortcut,
# signs the image, then notarizes and staples it.
#
# Usage: ./make_dmg.sh [--skip-notarize] path/to/Mac灵动岛.app
#
# Notarization uses a notarytool keychain profile (default "mac-dynamic-island", or set
# NOTARY_PROFILE). Create it once with:
#   xcrun notarytool store-credentials mac-dynamic-island --apple-id <Apple ID> --team-id 66233X8P8H

set -euo pipefail

VOLUME_NAME="Mac灵动岛"
DMG_BASENAME="MacDynamicIsland"   # ASCII, so download links and GitHub release assets keep the name
OUTPUT_DIR="$(cd "$(dirname "$0")" && pwd)/dist"
NOTARY_PROFILE="${NOTARY_PROFILE:-mac-dynamic-island}"
NOTARIZE=1

fail() { echo "❌ $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --skip-notarize) NOTARIZE=0; shift ;;
        -h|--help) sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*) fail "Unknown option: $1" ;;
        *) break ;;
    esac
done

[ $# -eq 1 ] || fail "Usage: $0 [--skip-notarize] path/to/Mac灵动岛.app"
APP_PATH="${1%/}"
[ -d "$APP_PATH/Contents" ] || fail "Not an app bundle: $APP_PATH"
APP_NAME="$(basename "$APP_PATH")"

echo "📦 Mac灵动岛 DMG Packaging"
echo "=============================="
echo ""

# The app has to be distribution-ready already: an Apple Development build won't open on other Macs
echo "🔍 Checking the app..."
codesign --verify --deep --strict "$APP_PATH" 2>/dev/null || fail "The app's signature is invalid: codesign --verify --deep --strict \"$APP_PATH\""
IDENTITY="$(codesign -dvv "$APP_PATH" 2>&1 | sed -n 's/^Authority=\(Developer ID Application: .*\)$/\1/p' | head -n 1)"
[ -n "$IDENTITY" ] || fail "The app isn't signed with a Developer ID Application certificate. Export it with Distribute App → Direct Distribution."
if ! xcrun stapler validate "$APP_PATH" > /dev/null 2>&1; then
    echo "⚠️  The app has no stapled notarization ticket. A copy dragged out of the DMG needs a network check on first launch."
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
DMG_PATH="$OUTPUT_DIR/$DMG_BASENAME-$VERSION.dmg"
echo "📋 App: $APP_PATH"
echo "📋 Version: $VERSION"
echo "📋 Signed by: $IDENTITY"
echo ""

# Stage the app next to an Applications shortcut, so the window invites a drag
echo "🗂  Building the disk image..."
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP_PATH" "$STAGING/$APP_NAME"
ln -s /Applications "$STAGING/Applications"

mkdir -p "$OUTPUT_DIR"
rm -f "$DMG_PATH"
# macOS 27 deprecates hdiutil create in favor of diskutil image; older systems only have hdiutil
if diskutil image create from --help > /dev/null 2>&1; then
    CREATE=(diskutil image create from --format ULFO --volumeName "$VOLUME_NAME" "$STAGING" "$DMG_PATH")
else
    CREATE=(hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING" -format ULFO -ov "$DMG_PATH")
fi
# Quiet unless it fails: diskutil writes its progress to stderr
CREATE_LOG="$("${CREATE[@]}" 2>&1)" || { echo "$CREATE_LOG" >&2; fail "Couldn't create the disk image"; }
echo "✅ Created $(basename "$DMG_PATH")"
echo ""

echo "✍️  Signing the disk image..."
codesign --sign "$IDENTITY" --timestamp "$DMG_PATH"
echo "✅ Signed"
echo ""

if [ "$NOTARIZE" -eq 1 ]; then
    if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" > /dev/null 2>&1; then
        echo "❌ No notarytool credentials in the keychain profile \"$NOTARY_PROFILE\". Save them once with:" >&2
        echo "   xcrun notarytool store-credentials $NOTARY_PROFILE --apple-id <Apple ID> --team-id 66233X8P8H" >&2
        echo "   or rerun with --skip-notarize. The signed image is at $DMG_PATH" >&2
        exit 1
    fi

    echo "☁️  Notarizing (this usually takes a few minutes)..."
    RESULT="$(xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait --output-format plist)"
    STATUS="$(plutil -extract status raw -o - - <<< "$RESULT")"
    if [ "$STATUS" != "Accepted" ]; then
        SUBMISSION_ID="$(plutil -extract id raw -o - - <<< "$RESULT" 2>/dev/null || echo "<id>")"
        fail "Notarization finished with status \"$STATUS\". See why: xcrun notarytool log $SUBMISSION_ID --keychain-profile $NOTARY_PROFILE"
    fi
    xcrun stapler staple "$DMG_PATH" > /dev/null
    echo "✅ Notarized and stapled"
    echo ""
else
    echo "⏭  Skipped notarizing the disk image"
    echo ""
fi

echo "🔍 Verifying..."
codesign --verify --strict "$DMG_PATH" || fail "The disk image's signature is invalid"
# Gatekeeper rejects a disk image that isn't notarized itself, even when the app inside is
if ASSESSMENT="$(spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG_PATH" 2>&1)"; then
    GATEKEEPER_OK=1
else
    GATEKEEPER_OK=0
fi
echo "$ASSESSMENT" | sed 's/^/   /'
[ "$NOTARIZE" -eq 0 ] || [ "$GATEKEEPER_OK" -eq 1 ] || fail "Gatekeeper rejects the notarized disk image"
echo ""

echo "=============================="
if [ "$GATEKEEPER_OK" -eq 1 ]; then
    echo "✅ DMG READY TO SHIP"
else
    echo "⚠️  DMG FOR LOCAL TESTING ONLY"
    echo "   Gatekeeper blocks it on other Macs until it's notarized: rerun without --skip-notarize"
fi
echo "=============================="
echo ""
echo "📀 $DMG_PATH"
echo "📏 $(du -h "$DMG_PATH" | cut -f1)"
echo "🔑 SHA-256: $(shasum -a 256 "$DMG_PATH" | cut -d' ' -f1)"
