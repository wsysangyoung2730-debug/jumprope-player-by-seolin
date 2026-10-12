#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
/usr/bin/python3 Scripts/generate_project.py
swift test
xcodebuild -project JumpRopePlayer.xcodeproj -scheme JumpRopePlayer -destination 'platform=macOS' -derivedDataPath DerivedData/Mac CODE_SIGNING_ALLOWED=NO build
xcodebuild -project JumpRopePlayer.xcodeproj -scheme JumpRopePlayer -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData/iPad CODE_SIGNING_ALLOWED=NO build
