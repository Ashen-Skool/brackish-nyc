# Validation and delivery status

Brackish is an implemented native app candidate with reproducible builds and
verified simulator journeys. It is **not represented as App Store submitted,
production-ready, a reliable species authority, or verified at 60 fps on a phone**.

## Verified environment and source

Mac Studio M3 Ultra, 256 GB RAM; Xcode 26.6 (17F113); iPhone 16 simulator running
iOS 26.5. The project targets iOS 17+. Both paired physical phones were unavailable
when checked, so camera hardware, spoken VoiceOver, felt haptics, device thermals
and real-device rendering performance are not passed.

A fresh GitHub clone at production-source commit
`327e4bfaa` (see the full SHA in Evidence/clean-checkout-build.json) built in Release
configuration for a generic iOS Simulator with no service keys or model download.
The generated project is committed. Subsequent delivery commits contain evidence,
documentation and scripts; production source changes require revalidation.

## Automated checks

The final general suite reports **22 passed, 0 failed**:

- 12 core tests: atomic journal round trips, edit persistence, corruption preservation,
  schema rejection, failed-write state retention, complete deletion, path safety,
  export redaction, measurement validation, catalog/search integrity, rejection
  logic, image input normalization and essential color contrast. Some methods
  cover more than one invariant; the machine-readable result is authoritative.
- 2 recognition/metadata tests: inference over the frozen 36-image corpus and
  orientation-preserving GPS removal.
- 8 UI tests: map search/bookmark/checklist/relaunch, unavailable camera and empty
  search, accessibility audit, journal edit/validation/delete, save/relaunch,
  native Photos → comparison → confirmation → photo journal, Files export/delete-all,
  and largest Dynamic Type navigation/editor access.

Two additional, separately configured tests pass: denied location with manual
borough selection, and granted location with simulated NYC coordinates and
straight-line distance ordering. These are not extra copies of the core tests.
A separate walkthrough case drives real controls and records app motion.

Evidence/tests-final-summary.json, tests-core-and-denied-location.json and
tests-granted-location.json contain XCTest's exported results. The extended photo
journey also exports its saved JPEG; tests-photo-export-summary.json and
photo-export-verification.json preserve that passing check. The core/location
bundle overlaps the final suite: do not add their totals as if all were unique.

The native contrast audit has one specifically reviewed false-positive exception
for the custom primary label, measured from its saved issue crop at **13.20:1**.
Clipped offscreen text is checked at another scroll position. This is not an
unqualified claim that the raw automatic contrast audit found nothing.
See Evidence/accessibility-review.md and the independent theme-color test.

## Feature/control audit

| Area | Evidence and boundary |
|---|---|
| Onboarding, Next/Back, final entry | Actual simulator walkthrough and settled screenshots; no permissions required to enter. |
| Photo library import | Native scoped picker, actual attributed JPEG, real Core ML candidates and saved journal photo. |
| Camera | Unavailable-camera recovery verified in simulator. Actual capture and permission denial on hardware remain pending. |
| Identification | Real inference and uncertainty/rejection paths; no random or hard-coded species result. Model shortcomings are material and documented. |
| Journal create/edit/delete | UI validation/edit/delete and relaunch tests; optional measurements and broad-area picker backed by stored fields. |
| Persistence failures | Atomic write, corruption, unsupported schema and failed-save state retention covered in core tests. |
| Unfinished photo | Sanitized draft retained across navigation/relaunch; comparison cancellation preserves it. Unsaved editor text is not advertised as an autosaved draft. |
| Map/search | Native MapKit, seven real reference spots, text/water/borough/saved filtering. No fabricated map, catch score or live conditions. |
| Location | Denied and granted tests pass; non-NYC location copy and timeouts wired in source. Catch records have no coordinates. |
| Saved spots/checklists | Save and packed state survive relaunch; custom item added; date, uncheck-all and deletion have concrete persistence actions. |
| Species/reference/tackle | All twelve species have field marks, purpose-based tackle notes and sources. Shop action is a real Apple Maps search, not inventory. |
| Export | Native Files save completed with a real saved photograph; JSON and JPEG payload located/decoded. Notes/area redaction verified. Copies exported outside the app are not erased by delete-all. |
| Delete-all | UI confirmation, empty state after relaunch, and photo/draft removal in core tests. |
| External resources | 20 of 21 audited URLs return HTTP 200. NY Health blocks automated requests with 403; it is a referenced official endpoint, not a fabricated replacement. |
| Offline | Persistence, reference/search and inference are local by construction and exercised without app service calls. An airplane-mode integration run was not performed by changing the shared host network. Map tiles/directions/websites may need internet. |
| Accessibility | Dynamic Type, labels/traits, contrast review and non-color state indicators. Physical spoken VoiceOver and touch ergonomics remain release checks. |
| Motion | Real recorded transitions and scrolling inspected; simulator callback intervals recorded. Native sheets handle interactive presentation; edited-entry dismissal is explicitly guarded. |

## Recognition boundary

On the small unfiltered diagnostic set, the correct species was first for 10/24
fish-observation images and present in the three candidates for 15/24. Four fish
observations were rejected. All 6 non-fish examples were rejected; only 2/6 unsupported
fish were rejected. Thus four unsupported fish received incorrect in-set suggestions.

The corpus includes poor framing, carcasses, distant subjects, multiple fish and
bird predation. These counts are not population accuracy. The model is useful as
an experimental visual lead and does not replace field-mark confirmation. It must
never authorize consumption or possession. See Docs/MODEL_CARD.md and per-image results.

## Performance boundary

The available callback captures have a 16.67 ms median but longer tails. They do
not demonstrate consistent 60 fps. Instruments' Animation Hitches template explicitly
reports that it is unsupported on this simulator platform. Photo decoding was moved
off the main actor and long content made lazy, but no unsupported speedup or phone
performance is claimed. Full data and tool limitations are in Evidence/PERFORMANCE.md.

## Visual evidence

Design/visual-target-v1.png is an AI-generated design reference. Evidence/screenshots/
contains actual simulator output. The walkthrough uses actual app controls; its
catch is marked as a showcase example with an attributed iNaturalist photograph,
not a personal catch. Original artwork, generation prompts, flattened editable PNGs,
editable Swift layouts/motion, source/content provenance and licenses are delivered.

## Foreground motion review completed — September 6, 2026

After the owner unlocked the Mac Studio, the Simulator window was raised and the
app was reviewed live in the foreground. Forward and reverse onboarding changes
settled normally; the old/new text did not remain overlaid. A short downward drag
on the Gantry Plaza detail sheet left the sheet open and settled. A fresh full
walkthrough test passed, covering onboarding, map-to-detail presentation, photo
import, candidate selection, journal save, tab changes and scrolling.

The new recording was checked using continuous time-normalized frame sequences,
including chapter changes, sheet presentation, photo scrolling and save dismissal.
The previous persistent-looking transition artifacts were not reproduced in this
foreground review. The earlier capture's cause is not asserted. The simulator
stream is variable-frame-rate; frame sampling must normalize timing before
selecting windows, otherwise selection gaps can misleadingly repeat a frame.

`Evidence/Brackish-walkthrough.mp4` replaces the provisional recording. It contains
actual simulator output, with only the test-launch lead-in trimmed and a delivery
resize. `tests-unlocked-walkthrough-summary.json` records the passing run;
`unlocked-live-transition.png`, `unlocked-motion-frame-review.jpg` and
`sheet-short-drag-unlocked.png` preserve review evidence. The locked-desktop blocker
is resolved. This is simulator visual acceptance, not physical-device or 60 fps
certification; the other release boundaries above remain in force.
