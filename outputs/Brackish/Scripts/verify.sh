#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${BRACKISH_SIMULATOR_ID:?Set BRACKISH_SIMULATOR_ID to a dedicated iPhone 16 simulator UUID}"
BRACKISH_DERIVED_DATA="${BRACKISH_DERIVED_DATA:-../../work/VerificationBuild}"
BRACKISH_RESULT_PATH="${BRACKISH_RESULT_PATH:-../../work/verification-$(date +%Y%m%d-%H%M%S).xcresult}"
xcrun simctl boot "$BRACKISH_SIMULATOR_ID" 2>/dev/null || true
xcrun simctl bootstatus "$BRACKISH_SIMULATOR_ID" -b
xcrun simctl addmedia "$BRACKISH_SIMULATOR_ID" Evidence/model-evaluation/yellow-perch-150733403.jpg
xcodebuild -project Brackish.xcodeproj -scheme Brackish \
  -destination "platform=iOS Simulator,id=$BRACKISH_SIMULATOR_ID" \
  -derivedDataPath "$BRACKISH_DERIVED_DATA" \
  -resultBundlePath "$BRACKISH_RESULT_PATH" \
  -skip-testing:BrackishUITests/LocationTests -skip-testing:BrackishUITests/ShowcaseTests \
  test CODE_SIGNING_ALLOWED=NO
