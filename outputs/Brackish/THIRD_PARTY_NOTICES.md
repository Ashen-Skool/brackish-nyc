# Third-party notices

## CLIP image model and derived text vectors

Brackish bundles OpenAI CLIP ViT-B/32, MIT license, copyright (c) 2021 OpenAI.
Upstream: https://github.com/openai/CLIP
Weights origin: https://huggingface.co/openai/clip-vit-base-patch32

The bundled image encoder is the 8-bit palettized Core ML conversion from:
https://huggingface.co/veszelovszki/cmdr-clip-vit-b32-coreml
Revision: d75098e638ead36ef9bf1a86ec866aae1f066ea0
Downloaded file: clip-image-p8.mlpackage.zip
Renamed package: FishEncoder.mlpackage (no changes to graph or weights).
The conversion publisher declares MIT for the converted weights. Apple and
OpenAI do not endorse Brackish.

The source text encoder was downloaded from the same revision, used to encode
50 fixed prompts, and is not included in the app. The generated prompt vectors
are bundled in recognition-prompts.json. No training or fine-tuning was performed.
The external image input is planar RGB float32 [0,1], shape [1,3,224,224].
The Core ML graph already contains CLIP mean/std normalization.

MIT License — CLIP:

Copyright (c) 2021 OpenAI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Evaluation photographs (not included in the application)

Evidence/model-evaluation/manifest.json is the authoritative per-file record of
photographer attribution, source observation URL, photo URL, license and SHA-256.
36 photos were retrieved through the documented iNaturalist v1 API, selecting
only CC0, CC BY and CC BY-SA photographs. Attribution is preserved unaltered.
These licenses cover only their respective photos, not the entire Brackish app.
No observation coordinates are included in the manifest.

- CC0 1.0: https://creativecommons.org/publicdomain/zero/1.0/
- CC BY 4.0: https://creativecommons.org/licenses/by/4.0/
- CC BY-SA 4.0: https://creativecommons.org/licenses/by-sa/4.0/

Photos are retained in the supplied medium-size rendition, without retouching.
Research-grade observation labels are not guaranteed ground truth for every
visible subject in a photo. Some show carcasses, bird predation or distant fish;
see the model evaluation notes. The collection is a small diagnostic set, not a
representative accuracy benchmark. It was not used to train the model.

CLIP's original training dataset is not distributed with this project. Its
individual image licenses are not established by the model's MIT license.
Brackish does not claim ownership of, or redistribute, that training corpus.

## Reference text and platform resources

Original concise editorial summaries cite NYSDEC, NOAA Fisheries, NYS Parks,
Hudson River Park, Minnesota DNR and New York Sea Grant. Source links and review
dates are in the app and Docs/SOURCES.md. No third-party fishing illustrations
or government logos are included. MapKit map imagery/attribution and SF Symbols
are supplied by Apple's platform and remain subject to Apple's terms.

The app has no third-party Swift package dependencies. Python tools used only
for preparation are separately licensed upstream (coremltools BSD-3-Clause,
Transformers Apache-2.0, NumPy BSD-3-Clause, Pillow HPND). They are not bundled.
