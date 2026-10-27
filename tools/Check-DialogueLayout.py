import json,pathlib,re,sys,unicodedata
root=pathlib.Path(__file__).resolve().parents[1]
profile=json.loads((root/'tools/dialogue-font-profile.json').read_text(encoding='utf-8'))
adv=profile['advances'];control=re.compile(r'\{[^}]*\}|\\(?:[A-Za-z]+(?:\[[^]]*\])?|[^\w\s])|<[^>]+>')
catalog={}
for file in sorted((root/'traducao/partes').glob('*.json')):
 data=json.loads(file.read_text(encoding='utf-8'));assert not (catalog.keys() & data.keys());catalog.update(data)
checked=0;failures=[]
for key,value in catalog.items():
 if not re.fullmatch(r'\d+\.\d+\.\d+\.\d+',key):continue
 checked+=1;text=control.sub('',value);unknown={c for c in text if c not in adv}
 if unknown:failures.append((key,'glyphs',sorted(unknown)));continue
 width=sum(adv[c] for c in text)
 if width>profile['portrait_budget']:failures.append((key,width,value))
print(json.dumps({'font':profile['name'],'size':profile['font_size'],'checked_rows':checked,'overflow_or_glyph_issues':failures},ensure_ascii=False,indent=2))
raise SystemExit(bool(failures))
