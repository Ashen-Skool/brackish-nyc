# Brackish

**A different kind of city.** A native NYC fishing atlas and private field journal,
with original underwater artwork and Pip, a quiet illustrated companion.

The app runs without API keys, registration, subscriptions, service accounts or a
custom backend. Photo comparison is real, bundled Core ML inference. It is
experimental and must be manually checked; read [the model card](Docs/MODEL_CARD.md)
for measured limitations rather than treating suggestions as confirmed identification.

## Build and run

Prerequisites: a Mac with Xcode 26.6 (verified) and an installed iOS 26.5 simulator
runtime. The deployment target is iOS 17+, but only the documented runtime was
available for execution in this session. There are no Swift package dependencies,
model downloads, Git LFS objects, environment secrets or backend setup steps.

1. Open `Brackish.xcodeproj` in Xcode.
2. Select the **Brackish** scheme and an iPhone simulator.
3. Run. Onboarding leads into the atlas without a permission prompt.

From this directory:

```sh
xcodebuild -project Brackish.xcodeproj -scheme Brackish \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath ../../work/Build build CODE_SIGNING_ALLOWED=NO
```

Choose a concrete available simulator for tests:

```sh
xcrun simctl list devices available
BRACKISH_SIMULATOR_ID='<your simulator UUID>' bash Scripts/verify.sh
```

The test script imports one attributed evaluation photo into the selected simulator.
Use a dedicated, disposable simulator. Tests use a separate `BrackishUITesting`
journal directory and never erase the normal app journal. Photo-picker automation
is verified on iPhone 16 / iOS 26.5; its one coordinate-based selection is documented
because this runtime does not expose the thumbnail cells to XCTest.

Physical-device installation requires ordinary Apple signing: choose your team in
Xcode. No phone was available for installation in this session. No App Store,
TestFlight or production performance claim is implied.

## The connected journeys

- **Identify:** camera or scoped Photos import → on-device comparison → up to three
  field-mark candidates → your confirmation, or unknown → editable journal entry.
- **Atlas:** seven reviewed shore locations across five boroughs → search by place,
  borough or fish → water/area/saved filters → access/source notes → bookmark,
  Apple Maps directions, and trip checklist.
- **Prepare and remember:** persistent custom checklist items, dates and packed
  states; saved spots; twelve species references; purpose-based tackle guidance
  and a truthful map search for tackle shops; a searchable private journal.
- **Privacy:** GPS-stripped photos, broad optional catch area, no photo uploads,
  explicit export to JSON including JPEGs, export redaction by default, per-entry
  deletion, delete-all, and failure recovery that preserves existing files.

## Read before release

- [Validation and release status](Docs/VALIDATION.md)
- [Recognition model card and diagnostic results](Docs/MODEL_CARD.md)
- [Privacy behavior](Docs/PRIVACY.md)
- [Content sources and review](Docs/SOURCES.md)
- [Engineering and observed environment](Docs/ENGINEERING.md)
- [Design and motion specification](Docs/DESIGN.md)
- [Original generation prompts](Design/PROMPTS.md)
- [Release checklist](Docs/RELEASE_CHECKLIST.md)
- [MIT app license](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md)

Actual simulator captures, test reports, model-evaluation provenance and the
walkthrough are in `Evidence/`. The unlocked, foreground simulator motion review
was completed on September 6, 2026; see the validation report. `Design/visual-target-v1.png` is concept art,
**not** an app screenshot. The app ships with an empty journal. Catches shown in
showcase evidence are clearly labelled examples using attributed evaluation photos.

## Editing and reproduction

The `.xcodeproj` is checked in. If adding/removing source/resource files, install
XcodeGen and run `xcodegen generate --spec project.yml`. Optional Python preparation
scripts require Python 3.11; normal app builds do not use Python.

`Scripts/make_catalog.py` rebuilds the reviewed JSON content. `prepare_prompts.py`
rebuilds the fixed text embeddings using the separately downloaded text model;
this is only needed when changing recognition labels. The Core ML encoder is
already bundled. `fetch_evaluation.py` records licensed photo sources and hashes;
`prototype_experiment.py` preserves the protocol for a rejected improvement trial.
Neither API is called by the app.
