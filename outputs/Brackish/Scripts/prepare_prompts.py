"""Precompute fixed CLIP text comparisons; not a trained fish classifier.
Run with Python 3.11, transformers, coremltools, numpy on macOS.
Pass the downloaded clip-text.mlpackage then the output JSON path.
"""
import json,sys
import numpy as np
import coremltools as ct
from transformers import CLIPTokenizer
from pathlib import Path
model=ct.models.MLModel(sys.argv[1],compute_units=ct.ComputeUnit.CPU_ONLY)
tokenizer=CLIPTokenizer.from_pretrained('openai/clip-vit-base-patch32', revision='3d74acf9a28c67741b2f4f2ea7635f0aaf6f0268')
species=json.loads((Path(__file__).resolve().parents[1]/'Brackish/Resources/species.json').read_text())
rows=[]
for s in species:
 for template in ['a photo of a {} fish.', 'a close-up photo of a {} fish caught by an angler.', 'a photo of a {} fish seen from the side.']:
  rows.append((s['id'],template.format(s['name'].lower())))
rows += [('other-fish','a photo of a fish of another species.'),('other-fish','a photo of a tropical aquarium fish.'),('other-fish','a photo of a shark.'),('other-fish','a photo of a sea robin fish.'),('other-fish','a photo of a striped bass fishing lure.'),('no-fish','a photo of a person without a fish.'),('no-fish','a photo of a dog.'),('no-fish','a photo of food on a plate.'),('no-fish','a photo of a city street.'),('no-fish','a photo of water without any fish.'),('no-fish','a blurry unrecognizable photograph.'),('no-fish','a photo of a plant.'),('no-fish','a photo of a cat.'),('no-fish','a photo of a blank wall.')]
output=[]
for id,text in rows:
 tokens=np.array(tokenizer(text,padding='max_length',max_length=77,truncation=True)['input_ids'],dtype=np.int32)[None,:]
 vector=model.predict({'input_ids':tokens})['embedding'].reshape(-1)
 vector=vector/np.linalg.norm(vector)
 output.append(dict(id=id,text=text,vector=vector.tolist()))
Path(sys.argv[2]).write_text(json.dumps(output,separators=(',',':')))
print('Wrote',len(output),'prompts of 512 dimensions')
