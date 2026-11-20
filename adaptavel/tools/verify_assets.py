import sys,pathlib,json,hashlib,gc
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]/"python-libs"))
import UnityPy
from PIL import Image,ImageDraw
def inventory(path):
 e=UnityPy.load(path);bundle=next(iter(e.files.values())); hashes={};fonts={};texts={}
 for name,af in bundle.files.items():
  if not hasattr(af,"objects"):continue
  for obj in af.objects.values():
   hashes[(name,obj.path_id)]=hashlib.sha256(obj.get_raw_data()).hexdigest()
   if obj.type.name=="TextAsset":
    d=obj.read_typetree()
    if d["m_Name"]=="Ara Fell Localization":texts=d["m_Script"]
   if obj.type.name=="Font":
    d=obj.read_typetree()
    if d["m_Name"] in ("ChevyRay - Softsquare","ChevyRay - Pinch"):
     tid=d["m_Texture"]["m_PathID"]
     td=af.objects[tid].read_typetree()
     fonts[d["m_Name"]]=(d,td)
 return hashes,fonts,texts
a,fa,ta=inventory(sys.argv[1]);gc.collect();b,fb,tb=inventory(sys.argv[2])
assert a.keys()==b.keys()
changes=[k for k in a if a[k]!=b[k]]
ra=[r.split("\t") for r in ta.splitlines() if r];rb=[r.split("\t") for r in tb.splitlines() if r]
assert [r[:3] for r in rb[:-1]]==ra
assert all(len(r)==4 for r in rb)
for name in fa:
 ga,tda=fa[name];gb,tdb=fb[name]
 def glyph(g,td):
  u=g["uv"];w,h=td["m_Width"],td["m_Height"]
  im=Image.frombytes("L",(w,h),bytes(td["image data"]))
  x=round(u["x"]*w);y=round((u["y"]+u["height"])*h)
  im=im.crop((x,y,x+round(u["width"]*w),y+round(-u["height"]*h)))
  if g["flipped"]:im=im.transpose(Image.Transpose.TRANSVERSE)
  return im
 new={g["index"]:g for g in gb["m_CharacterRects"]}
 for g in ga["m_CharacterRects"]:assert glyph(g,tda).tobytes()==glyph(new[g["index"]],tdb).tobytes()
 preview=Image.new("RGB",(480,95),(18,30,64));x=8
 for ch in "Aa Áá Ãã Çç Éé Õõ Úú":
  g=new[ord(ch)];im=glyph(g,tdb)
  preview.paste((240,240,245),(x,35-round(g["vert"]["y"])),im);x+=round(g["advance"])
 if "--no-preview" not in sys.argv:preview.resize((960,190),Image.Resampling.NEAREST).save("font-"+name.split(" - ")[1]+".png")
print(json.dumps({"objects":len(a),"changed":len(changes),"unchanged":len(a)-len(changes),"english_japanese_preserved":True,"ascii_font_pixels_preserved":True}))
