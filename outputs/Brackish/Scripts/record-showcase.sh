#!/bin/bash
# Uses the dedicated simulator already seeded by verify.sh; does not touch a phone.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${BRACKISH_SIMULATOR_ID:?Set to the dedicated iPhone 16 simulator UUID}"
BRACKISH_DERIVED_DATA="${BRACKISH_DERIVED_DATA:-../../work/VerificationBuild}"
BRACKISH_VIDEO="${BRACKISH_VIDEO:-../../work/brackish-recording.mov}"
BRACKISH_RESULT_PATH="${BRACKISH_RESULT_PATH:-../../work/showcase-$(date +%Y%m%d-%H%M%S).xcresult}"
BRACKISH_RECORD_PID=''
finish_recording() {
  if [[ -n "$BRACKISH_RECORD_PID" ]]; then
    kill -INT "$BRACKISH_RECORD_PID" 2>/dev/null || true
    wait "$BRACKISH_RECORD_PID" || true
    BRACKISH_RECORD_PID=''
  fi
}
trap finish_recording EXIT INT TERM
xcrun simctl io "$BRACKISH_SIMULATOR_ID" recordVideo --codec=h264 --force "$BRACKISH_VIDEO" &
BRACKISH_RECORD_PID=$!
xcodebuild test-without-building -project Brackish.xcodeproj -scheme Brackish \
  -destination "platform=iOS Simulator,id=$BRACKISH_SIMULATOR_ID" \
  -derivedDataPath "$BRACKISH_DERIVED_DATA" -resultBundlePath "$BRACKISH_RESULT_PATH" \
  -only-testing:BrackishUITests/ShowcaseTests CODE_SIGNING_ALLOWED=NO
finish_recording
