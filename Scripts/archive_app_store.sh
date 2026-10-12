#!/bin/bash
# Uses Xcode's signed-in account. Exports locally; never uploads or releases the app.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
platform="${1:-all}"
case "$platform" in
  all) platforms=(macOS iPadOS) ;;
  macOS|iPadOS) platforms=("$platform") ;;
  *) echo 'Usage: Scripts/archive_app_store.sh [all|macOS|iPadOS] [new-output-directory]' >&2; exit 2 ;;
esac
output="${2:-BuildArtifacts/AppStore-$(date +%Y%m%d-%H%M%S)}"
if [[ -e "$output" ]]; then
  echo "Output already exists; choose a new directory: $output" >&2
  exit 2
fi
mkdir -p "$output/Logs"
output="$(cd "$output" && pwd)"
trap 'echo "Archive/export failed. See logs: $output/Logs" >&2' ERR
python3 Scripts/generate_project.py
for platform in "${platforms[@]}"; do
  destination='generic/platform=macOS'
  extension=pkg
  if [[ "$platform" == iPadOS ]]; then destination='generic/platform=iOS'; extension=ipa; fi
  archive="$output/$platform/JumpRopePlayer.xcarchive"
  echo "$platform: archiving"
  xcodebuild -project JumpRopePlayer.xcodeproj -scheme JumpRopePlayer \
    -configuration Release -destination "$destination" \
    -archivePath "$archive" -derivedDataPath "DerivedData/AppStore-$platform" \
    -allowProvisioningUpdates archive > "$output/Logs/$platform-archive.log" 2>&1
  echo "$platform: exporting App Store package"
  xcodebuild -exportArchive -archivePath "$archive" \
    -exportOptionsPlist "App/Configuration/ExportOptions-$platform.plist" \
    -exportPath "$output/$platform/Export" -allowProvisioningUpdates \
    > "$output/Logs/$platform-export.log" 2>&1
  python3 Scripts/verify_signed_release.py --platform "$platform" --archive "$archive" \
    --package "$output/$platform/Export/JumpRopePlayer.$extension" \
    | tee "$output/Logs/$platform-verification.json"
done
echo "App Store files: $output"
