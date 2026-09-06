# Recognition model card

## Intended role

A private, offline visual comparison to help an angler choose which field marks to inspect.
Every candidate must be confirmed manually. Unknown is available. This is not a legal,
edibility, protected-species, measurement, or fishing-conditions classifier.

## Model and input contract

- OpenAI CLIP ViT-B/32, MIT; 8-bit palettized Core ML image tower.
- Upstream conversion pinned to d75098e638ead36ef9bf1a86ec866aae1f066ea0.
- 224×224 center crop, orientation corrected; planar RGB float32 in [0,1].
- CLIP normalization is inside the graph. Fifty fixed text vectors are bundled.
- Twelve reference species, three prompts each; remaining prompts cover rejection examples.
- Mean cosine similarity ranks each species; no confidence percentages are displayed.
- Gates: best species cosine ≥0.20, > maximum non-fish score +0.015, and
  > maximum other-fish score −0.005. These are heuristics, not calibrated probabilities.
- An inter-species gap below 0.025 gets more explicit ambiguity copy.

## Diagnostic evaluation

The frozen 36-image set contains two earliest eligible research-grade iNaturalist
observations since 2023 per named taxon, fetched under CC0/CC BY/CC BY-SA.
No selection based on model success was performed. The per-file manifest and results
are preserved. Evaluation images were not used to train the delivered model.

The labels describe observations, not necessarily a well-framed visible fish.
Manual contact-sheet review found carcasses, a bird carrying a fish, distant fish,
multiple fish, juveniles, aquarium containers, dog tracks and background-dominated
images. This deliberately difficult sample is too small and unrepresentative to
estimate accuracy for NYC anglers. Duplicate photographers may also correlate examples.

| Diagnostic | Count |
|---|---:|
| Fish-observation images | 24 |
| Correct first candidate, counting rejection as a miss | 10/24 |
| Correct species among three candidates | 15/24 |
| Fish-observation images rejected | 4 |
| Unsupported/non-fish images rejected | 8/12 |

| Species | First / 2 | Top three / 2 | Rejected / 2 |
|---|---:|---:|---:|
| Striped bass | 0 | 0 | 2 |
| Bluefish | 0 | 1 | 0 |
| Summer flounder | 1 | 2 | 0 |
| Scup | 0 | 1 | 0 |
| Black sea bass | 0 | 2 | 0 |
| Largemouth bass | 0 | 0 | 1 |
| Bluegill | 1 | 1 | 0 |
| Pumpkinseed | 2 | 2 | 0 |
| Black crappie | 2 | 2 | 0 |
| Yellow perch | 2 | 2 | 0 |
| Common carp | 1 | 1 | 0 |
| Brown bullhead | 1 | 1 | 1 |

## Limitations and iteration

The first integration double-normalized pixels and performed poorly. That failure
is retained in recognition-evaluation-v1.json. Inspection of the Core ML graph
revealed its internal normalization. The correction was tested against the same
unchanged corpus, without changing rejection thresholds (v2).

A bounded prototype experiment used separate licensed observations since 2024 to
form class centroids from the image embeddings. With the same rejection gate it
returned 9 correct first candidates and 15 top-three matches among the same 24 fish
observations, compared with 10 and 15 for the shipped approach. It was rejected.
The protocol, attribution manifest, prototypes and results are retained separately;
these centroids are not bundled or used in the application. No tuning on this
small diagnostic set is presented as a validated accuracy improvement.

Four unsupported/non-fish images were incorrectly accepted by the heuristic gate.
This is a material limitation. The UI never automatically saves a species and
never equates a leading candidate with a verified identification. The species set
does not cover all NYC fish, including several lookalikes; results can be wrong
even with a good photograph. Center cropping can omit the head or tail.

## Performance boundary

Model evaluation was executed through the actual Swift/Core ML pipeline in the
iPhone 16 simulator on an M3 Ultra Studio. Simulator inference timing is not iPhone
latency. The final validation report records runtime configuration and measured
timings; real-device thermal, energy, memory-pressure and sustained performance
remain unverified. No physical-device 60 fps claim is made.

## License and provenance

See THIRD_PARTY_NOTICES.md for the complete MIT model notice and the per-photo
licenses. The original CLIP training corpus is not distributed here, and this
project does not assert licenses for its individual source images.
