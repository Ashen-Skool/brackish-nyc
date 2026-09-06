"""Small reproducible evaluation-only corpus, not training data or app content.
Two earliest eligible research-grade observations since 2023 per named taxon.
Retain the first licensed photo. No filtering by recognition outcome.
One API request/second per iNaturalist's published guidance.
"""
import json,urllib.request,urllib.parse,time,hashlib
from pathlib import Path
base=Path(__file__).resolve().parents[1]
out=base/'Evidence/model-evaluation';out.mkdir(parents=True,exist_ok=True)
species=json.loads((base/'Brackish/Resources/species.json').read_text())
queries=[(s['id'],s['scientific']) for s in species]
queries += [('other-fish','Oncorhynchus mykiss'),('other-fish','Carassius auratus'),('other-fish','Prionotus carolinus'),('no-fish','Canis lupus familiaris'),('no-fish','Felis catus'),('no-fish','Helianthus annuus')]
manifest=[]
def get(url):
 return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Brackish-Showcase-Evaluation/1.0 (github.com/oh-ashen-one/brackish-nyc)'}),timeout=40).read()
for label,taxon in queries:
 params=urllib.parse.urlencode(dict(taxon_name=taxon,quality_grade='research',photos='true',photo_license='cc0,cc-by,cc-by-sa',per_page=2,order_by='id',order='asc',d1='2023-01-01'))
 try:
  response=json.loads(get('https://api.inaturalist.org/v1/observations?'+params))
  for row in response['results']:
   photos=[p for p in row['photos'] if p['license_code'] in ['cc0','cc-by','cc-by-sa']]
   if not photos: continue
   photo=photos[0];url=photo['url'].replace('/square.','/medium.')
   filename=f"{label}-{row['id']}.jpg"
   data=get(url);(out/filename).write_bytes(data)
   manifest.append(dict(file=filename,expected=label,taxon=row['taxon']['name'],observation_url=f"https://www.inaturalist.org/observations/{row['id']}",photo_url=url,attribution=photo['attribution'],license=photo['license_code'],sha256=hashlib.sha256(data).hexdigest(),observed_on=row['observed_on']))
   print(filename,photo['license_code'],flush=True)
 except Exception as e: print('FAILED',taxon,str(e),flush=True)
 time.sleep(1.1)
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('TOTAL',len(manifest))
