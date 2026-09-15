"""Append Māori Maps waka-page citations to docs/data/claims.json. Usage: python add_claims.py <waka> <page_url> <file of 'Marae|Hapū (Iwi)' lines>"""
import json, sys, re, pathlib
waka, url, src = sys.argv[1], sys.argv[2], sys.argv[3]
p = pathlib.Path('docs/data/claims.json'); claims = json.loads(p.read_text(encoding='utf-8'))
ids = {c['claim_id'] for c in claims}; n = 1
def nid():
    global n
    while f"C{n:04d}" in ids: n += 1
    ids.add(f"C{n:04d}"); return f"C{n:04d}"
def exists(sub, rel, obj): return any(c['source_id']=='S03' and c['subject_type']=='Marae' and c['subject_ref']==sub and c['relationship']==rel and c['object_ref']==obj for c in claims)
added = 0
for line in open(src, encoding='utf-8'):
    line = line.strip()
    if not line or line.startswith('#'): continue
    name, _, hapu = line.partition('|')
    name = name.strip(); alt = ''
    m = re.match(r'^(.*?)\s*\((.*)\)$', name)
    if m: name, alt = m.group(1).strip(), m.group(2).strip()
    base = dict(source_id='S03', subject_type='Marae', subject_ref=name, subject_detail='', page_url=url, retrieved='2026-09-16', confidence='stated')
    if alt and not exists(name,'alias_of',alt):
        claims.append({**base, 'claim_id': nid(), 'relationship':'alias_of', 'object_ref': alt, 'object_detail':'', 'note':'Name as shown on Māori Maps'}); added+=1
    if not exists(name,'has_waka',waka):
        claims.append({**base, 'claim_id': nid(), 'relationship':'has_waka', 'object_ref': waka, 'object_detail':'', 'note':''}); added+=1
    hapu = hapu.strip()
    if hapu:
        m = re.match(r'^(.*?)\s*\((.*)\)$', hapu); h, iwi = (m.group(1).strip(), m.group(2).strip()) if m else (hapu, '')
        if not exists(name,'has_hapu',h):
            claims.append({**base, 'claim_id': nid(), 'relationship':'has_hapu', 'object_ref': h, 'object_detail': iwi, 'note': f"Māori Maps writes '{hapu}'" if iwi else ''}); added+=1
p.write_text(json.dumps(claims, ensure_ascii=False, indent=1), encoding='utf-8')
print(f"{waka}: +{added} claims, total {len(claims)}")
