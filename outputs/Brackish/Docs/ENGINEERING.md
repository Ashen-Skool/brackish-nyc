# Engineering notebook

## Environment actually observed

- Host: Mac Studio, M3 Ultra, 32 CPU cores, 256 GB memory.
- Xcode 26.6 (17F113), iOS 26.5 simulator runtime.
- Dedicated simulator: Brackish RC iPhone 16, BDA086AC-BB6D-4159-A1A4-7DFC9672BC91.
- Target: iOS 17 and later; native iPhone layout with adaptive iPad support.
- Configured model read at session start: gpt-6-astra, high reasoning. No setting was changed.
- Paired iPhone 13 and iPhone 17 Pro Max were listed as unavailable. Physical-device
  validation and any device FPS claim remain outside the evidence obtained.
- All compilation, inference, preparation and recording ran on this Studio in
  session-owned paths. No other Studio workload was stopped or reconfigured.

## Architecture

SwiftUI NavigationStack and native sheets surround four deliberately small areas:
Atlas, Identify, Journal and Pack. MapKit supplies the map and external directions;
CoreLocation requests coarse accuracy only after Near me; PhotosPicker scopes
access to a selected photo; UIKit supplies camera capture. There is no backend,
service API, embedded credential, analytics SDK, advertising SDK or Swift package.

JournalVault stores a versioned Codable journal with atomic replacement. State
changes are published only after persistence succeeds. Photo files use random
names, have GPS/EXIF removed, and are written before the journal references them.
A failed save removes the newly written photo and retains the previous state.
Deleting an entry removes its associated image after the state is committed.
Deleting everything commits an empty journal before removing images and drafts.
Malformed or newer-schema files are preserved and editing is blocked; Settings
can export the raw recovery file. Files use complete iOS data protection and the
private directory is excluded from cloud backup. Export is explicit.

Recognition runs through an actor and accepts cancellation before/after inference.
The input image is orientation-corrected, center-cropped, resampled to 224 square,
and passed as planar RGB [0,1]. The graph performs normalization internally.
Fifty fixed, normalized text vectors cover 12 species and rejection examples.
Mean cosine similarity over each species' three prompts ranks the candidates.
No softmax score is displayed as a confidence probability. This is zero-shot
comparison, not a fish-specific classifier and not a model trained on this app's
reference text. See MODEL_CARD.md for measured limitations.

## Behavior under failure

Photo import errors leave the previous photo intact and provide a retry message;
canceled comparison retains the photo. A sanitized unfinished photo is persisted
as a draft and restored after returning to Identify or relaunching. Camera denial
and camera unavailability lead to Photos/manual entry. Unavailable location can
be replaced by a borough. Search operates on bundled places and species offline.
The map never substitutes fictional tiles or conditions when networking fails.
Source links and directions are explicitly external and need connectivity.

The JSON export includes structured records and base64 JPEGs. Area and written
notes are removed by default, with an explicit opt-in for a fuller private backup.
Visible details inside images can still disclose places. Exact coordinates are
never stored in catch entries. Copies exported to Files are beyond app deletion.

## Reproducibility

The generated .xcodeproj is committed. XcodeGen is optional unless changing the
project structure. Model weights and prompts are ordinary tracked files so a
checkout can build without a model download, Git LFS, Hugging Face login or token.
The 84 MB weight file exceeds GitHub's recommendation but is below its per-file
limit. The app never fetches models at runtime.

Builds used automatic signing disabled for simulator. Device installation needs
normal Apple developer signing; no App Store or TestFlight action was performed.
