"""Bounded on-device recognition improvement experiment.
Protocol fixed before evaluation: 24 earliest licensed research-grade observations
since 2024 per species; exclude evaluation observations/photos/hashes. Normalized
CLIP embedding class centroids. No hyperparameter tuning on the evaluation corpus.
Only development-time public iNaturalist requests; no runtime API.
"""
import json,time,hashlib,urllib.parse,urllib.request,sys
from pathlib import Path
import numpy as np
from PIL import Image,ImageOps
import coremltools as ct
base=Path(__file__).resolve().parents[1]
work=Path(sys.argv[1]);work.mkdir(parents=True,exist_ok=True)
corpus=base/'Evidence/model-evaluation'
evaluation=json.loads((corpus/'manifest.json').read_text())
exclude_hash={r['sha256'] for r in evaluation};exclude_url={r['observation_url'] for r in evaluation}
species=json.loads((base/'Brackish/Resources/species.json').read_text())
manifest=[];prototypes=[]
model=ct.models.MLModel(str(base/'Brackish/Resources/FishEncoder.mlpackage'),compute_units=ct.ComputeUnit.CPU_ONLY)
def read(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Brackish-Recognition-Evaluation/1.0 (github.com/Ashen-Skool/brackish-nyc)'}),timeout=25).read()
def encode(path):
 im=ImageOps.fit(ImageOps.exif_transpose(Image.open(path)).convert('RGB'),(224,224),method=Image.Resampling.BICUBIC)
 a=np.asarray(im).astype(np.float32)/255
 out=model.predict({'image':np.transpose(a,(2,0,1))[None]})['embedding'].reshape(-1)
 return out/np.linalg.norm(out)
for s in species:
 params=urllib.parse.urlencode(dict(taxon_name=s['scientific'],quality_grade='research',photos='true',photo_license='cc0,cc-by',per_page=24,order_by='id',order='asc',d1='2024-01-01'))
 try:
  observations=json.loads(read('https://api.inaturalist.org/v1/observations?'+params))['results']
 except Exception as error:print('FETCH ERROR',s['name'],error,flush=True);continue
 features=[]
 for r in observations:
  source='https://www.inaturalist.org/observations/'+str(r['id'])
  if source in exclude_url:continue
  photos=[p for p in r['photos'] if p['license_code'] in ['cc0','cc-by']]
  if not photos:continue
  p=photos[0];url=p['url'].replace('/square.','/medium.');file=f"{s['id']}-{r['id']}.jpg"
  try:
   data=read(url);sha=hashlib.sha256(data).hexdigest()
   if sha in exclude_hash:continue
   (work/file).write_bytes(data);f=encode(work/file);features.append(f)
   manifest.append(dict(file=file,species=s['id'],taxon=r['taxon']['name'],observation_url=source,photo_url=url,attribution=p['attribution'],license=p['license_code'],sha256=sha,observed_on=r['observed_on']))
  except Exception as error:print('IMAGE ERROR',file,error,flush=True)
 if features:
  centroid=np.mean(features,axis=0);centroid/=np.linalg.norm(centroid)
  prototypes.append(dict(id=s['id'],count=len(features),vector=centroid.tolist()))
 print(s['name'],len(features),flush=True);time.sleep(1.1)
(work/'prototype-manifest.json').write_text(json.dumps(manifest,indent=2))
(work/'prototypes.json').write_text(json.dumps(prototypes,separators=(',',':')))
results=[]
for r in evaluation:
 f=encode(corpus/r['file']);scores=sorted([(p['id'],float(np.dot(f,p['vector']))) for p in prototypes],key=lambda v:-v[1])
 results.append(dict(file=r['file'],expected=r['expected'],ranking=[id for id,_ in scores],scores=[v for _,v in scores]))
(work/'prototype-evaluation.json').write_text(json.dumps(results,indent=2))
known=[r for r in results if r['expected'] not in ['no-fish','other-fish']]
print('PROTOTYPE UNGATED',len(known),'top1',sum(r['ranking'][0]==r['expected'] for r in known),'top3',sum(r['expected'] in r['ranking'][:3] for r in known),flush=True)
