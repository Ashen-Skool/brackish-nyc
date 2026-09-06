#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${BRACKISH_SIMULATOR_ID:?Set to your dedicated simulator UUID}"
BRACKISH_DERIVED_DATA="${BRACKISH_DERIVED_DATA:-../../work/VerificationBuild}"
run_location_test() {
  xcodebuild -project Brackish.xcodeproj -scheme Brackish \
    -destination "platform=iOS Simulator,id=$BRACKISH_SIMULATOR_ID" \
    -derivedDataPath "$BRACKISH_DERIVED_DATA" \
    -only-testing:"BrackishUITests/LocationTests/$1" test CODE_SIGNING_ALLOWED=NO
}
xcrun simctl privacy "$BRACKISH_SIMULATOR_ID" revoke location com.ohashenone.brackish
run_location_test testDeniedLocationAndManualArea
xcrun simctl privacy "$BRACKISH_SIMULATOR_ID" grant location com.ohashenone.brackish
xcrun simctl location "$BRACKISH_SIMULATOR_ID" set 40.7441,-73.9601
run_location_test testGrantedLocationDistances
xcrun simctl privacy "$BRACKISH_SIMULATOR_ID" reset location com.ohashenone.brackish
xcrun simctl location "$BRACKISH_SIMULATOR_ID" clear
