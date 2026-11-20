import sys,pathlib,json,struct,copy,unicodedata,gc,re
ROOT=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"python-libs"))
import UnityPy
from PIL import Image,ImageDraw
from unity_stream import extract,pack

def require(b,msg):
 if not b:raise ValueError(msg)
def patch_font(obj,assets,chars):
 d=obj.read_typetree()
 if not d["m_CharacterRects"] or not d["m_Name"].startswith("ChevyRay - "):return []
 texptr=d["m_Texture"];
 if texptr["m_PathID"]==0:return []
 require(texptr["m_FileID"]==0,"External font texture")
 tex=assets.objects[texptr["m_PathID"]];td=tex.read_typetree()
 require(td["m_TextureFormat"] in (1,4) and td["m_MipCount"]==1,"Unknown bitmap font format "+d["m_Name"]+str((td["m_TextureFormat"],td["m_MipCount"])))
 w,h=td["m_Width"],td["m_Height"]
 raw=bytes(td["image data"])
 if td["m_TextureFormat"]==4:
  require(len(raw)==w*h*4,"External RGBA font bitmap")
  require(all(raw[i:i+3]==bytes([255,255,255]) for i in range(0,len(raw),4) if raw[i+3]),"Colored bitmap font")
  raw=raw[3::4];td["m_TextureFormat"]=1
 require(len(raw)==w*h,"External font bitmap")
 original=Image.frombytes("L",(w,h),raw)
 glyphs={chr(g["index"]):g for g in d["m_CharacterRects"]}
 missing=sorted(set(chars)-glyphs.keys())
 if not missing:return []
 generated=[]
 for ch in missing:
  nd=unicodedata.normalize("NFD",ch)
  require(len(nd)==2 and nd[0] in glyphs,"Missing base glyph "+ch)
  base,mark=nd;g=copy.deepcopy(glyphs[base])
  uv=g["uv"];x=round(uv["x"]*w);y=round((uv["y"]+uv["height"])*h)
  gw=round(uv["width"]*w);gh=round(-uv["height"]*h)
  require(gw>0 and gh>0,"Unexpected UV orientation")
  glyph=original.crop((x,y,x+gw,y+gh))
  if g["flipped"]:glyph=glyph.transpose(Image.Transpose.TRANSVERSE);gw,gh=glyph.size;g["flipped"]=False
  bbox=glyph.getbbox();require(bbox is not None,"Empty glyph")
  if base=="i" and mark!="\u0327":
   # Remove the original dot before adding the accent.
   ImageDraw.Draw(glyph).rectangle((bbox[0],bbox[1],bbox[2]-1,bbox[1]),fill=0)
  below=mark=="\u0327";extra=2 if below else 3
  canvas=Image.new("L",(gw,gh+extra));canvas.paste(glyph,(0,0 if below else extra))
  dr=ImageDraw.Draw(canvas);cx=max(1,min(gw-3,(bbox[0]+bbox[2]-1)//2))
  if below:
   yy=bbox[3];dr.point((cx+1,yy),fill=255);dr.point((cx,yy+1),fill=255)
  else:
   # Align the accent to the top of the ink, leaving a one-pixel gap.
   yy=bbox[1]
   points={"\u0301":[(1,0),(0,1)],"\u0300":[(-1,0),(0,1)],
           "\u0302":[(0,0),(-1,1),(1,1)],"\u0303":[(-1,0),(0,0),(0,1),(1,1)]}
   require(mark in points,"Unsupported accent")
   for dx,dy in points[mark]:dr.point((cx+dx,yy+dy),fill=255)
  g["index"]=ord(ch);g["vert"]["height"]-=extra
  if not below:g["vert"]["y"]+=extra
  generated.append((g,canvas))
 nw=max(w,256);nh=h+sum(im.height+2 for _,im in generated)
 nh=1<<(nh-1).bit_length()
 atlas=Image.new("L",(nw,nh));atlas.paste(original,(0,0))
 for g in d["m_CharacterRects"]:
  g["uv"]["x"]*=w/nw;g["uv"]["width"]*=w/nw
  g["uv"]["y"]*=h/nh;g["uv"]["height"]*=h/nh
 x=1;y=h+1;rowh=0
 for g,im in generated:
  if x+im.width+1>nw:x=1;y+=rowh+2;rowh=0
  atlas.paste(im,(x,y))
  g["uv"]={"x":x/nw,"y":(y+im.height)/nh,"width":im.width/nw,"height":-im.height/nh}
  d["m_CharacterRects"].append(g);x+=im.width+2;rowh=max(rowh,im.height)
 td["m_Width"]=nw;td["m_Height"]=nh;td["m_CompleteImageSize"]=nw*nh;td["image data"]=atlas.tobytes()
 obj.save_typetree(d);tex.save_typetree(td)
 return [obj,tex]

def patch(src,dest,work):
 reference=json.loads((ROOT/"reference.json").read_text(encoding="utf-8"))
 by_en={}
 for r in reference.values():by_en.setdefault(r["en"],set()).add(r["pt"])
 env=UnityPy.load(str(src));bundle=next(iter(env.files.values()))
 candidates=[]
 for name,assets in bundle.files.items():
  if not hasattr(assets,"objects"):continue
  for obj in assets.objects.values():
   if obj.type.name=="TextAsset":
    data=obj.read_typetree()
    if data["m_Name"]=="Ara Fell Localization":candidates.append((name,assets,obj,data))
 require(len(candidates)==1,"Localization table not uniquely identified")
 name,assets,textobj,data=candidates[0]
 rows=[r.split("\t") for r in data["m_Script"].splitlines() if r]
 require(all(len(r)==3 for r in rows),"Expected original English/Japanese table; restore before reapplying")
 result=[];unknown=[];mapped=0
 for row in rows:
  key,en,jp=row;r=reference.get(key)
  if r and r["en"]==en:pt=r["pt"];mapped+=1
  elif en in by_en and len(by_en[en])==1:pt=next(iter(by_en[en]));mapped+=1
  else:pt=en;unknown.append(key)
  result.append(row+[pt])
 require(mapped/len(rows)>=0.98,"Too many unknown texts; unsupported content")
 result.append(["Portuguese","Portuguese","Portuguese","Português (Brasil)"])
 data["m_Script"]="\r\n".join("\t".join(r) for r in result)+"\r\n"
 textobj.save_typetree(data);changes={name:{textobj.path_id:textobj}}
 chars={c for row in result for c in row[3] if ord(c)>127}
 chars |= {c.upper() for c in chars} | {c.lower() for c in chars}
 fonts=0
 for aname,af in bundle.files.items():
  if not hasattr(af,"objects"):continue
  for obj in af.objects.values():
   if obj.type.name=="Font":
    modifications=patch_font(obj,af,chars)
    if modifications:fonts+=1
    for o in modifications:changes.setdefault(aname,{})[o.path_id]=o
 require(fonts>0,"No bitmap fonts patched")
 font=next(o.read_typetree() for o in assets.objects.values() if o.type.name=="Font" and o.read_typetree()["m_Name"]=="ChevyRay - Softsquare")
 advances={chr(g["index"]):g["advance"] for g in font["m_CharacterRects"]}
 wide=[]
 for row in result:
  if re.fullmatch(r"\d+(?:\.\d+){3}",row[0]):
   plain=re.sub(r"\\[A-Za-z]+\[[^\]]*\]|\\[.!|^><$]","",row[3])
   width=sum(advances.get(c,6) for c in plain)+1
   if width>232:wide.append([row[0],width])
 # Keep output for review; layout failures must be resolved before distributing this build.
 report={"rows":len(rows),"translated_matches":mapped,"unmatched":unknown,"fonts":fonts,"wide":wide}
 work=pathlib.Path(work);work.mkdir(parents=True,exist_ok=True)
 replacements={}
 for aname,changed in changes.items():
  af=bundle.files[aname]
  require(af.header.version==20,"Unsupported serialized asset header")
  for obj in changed.values():
   payload=obj.data
   f=work/("object-"+str(len(replacements))+"-"+str(obj.path_id));f.write_bytes(payload)
   replacements.setdefault(aname,[]).append((obj.byte_start_offset[0]-obj.reader.BaseOffset,obj.byte_start_offset[1],obj.byte_size_offset[0]-obj.reader.BaseOffset,str(f),af.header.data_offset))
 meta=extract(src,work/"nodes")
 for aname,items in replacements.items():
  node=next(n for n in meta["nodes"] if n["name"]==aname)
  with open(node["path"],"r+b") as f:
   for startpos,startsize,sizepos,payloadpath,offset in items:
    payload=pathlib.Path(payloadpath).read_bytes()
    f.seek(0,2);f.write(bytes((-f.tell())%8));start=f.tell()
    f.write(payload);f.seek(startpos);f.write(struct.pack("<I" if startsize==4 else "<Q",start-offset))
    f.seek(sizepos);f.write(struct.pack("<I",len(payload)))
   f.seek(0,2);size=f.tell();require(size<2**32,"Asset exceeds format size limit")
   f.seek(4);f.write(struct.pack(">I",size))
 pack(meta,dest)
 (work/"report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
 print(json.dumps(report,ensure_ascii=False),flush=True)
 return report
if __name__=="__main__":patch(sys.argv[1],sys.argv[2],sys.argv[3])
