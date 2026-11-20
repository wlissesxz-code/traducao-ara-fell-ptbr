"""Streaming UnityFS reader/writer: never loads the complete bundle into RAM."""
import struct, pathlib, io, shutil
import lz4.block
def zread(f):
 b=bytearray()
 while True:
  c=f.read(1)
  if not c: raise ValueError("Truncated UnityFS string")
  if c==b"\0": return b.decode()
  b.extend(c)
def unpack(f,fmt): return struct.unpack(">"+fmt,f.read(struct.calcsize(">"+fmt)))
def decode(data,size,flags):
 kind=flags&63
 if kind==0: result=data
 elif kind in (2,3): result=lz4.block.decompress(data,uncompressed_size=size)
 else: raise ValueError("Unsupported UnityFS compression "+str(kind))
 if len(result)!=size: raise ValueError("Invalid block size")
 return result
def extract(src,dest):
 dest=pathlib.Path(dest);dest.mkdir(parents=True,exist_ok=True)
 with open(src,"rb") as f:
  if zread(f)!="UnityFS": raise ValueError("Not a UnityFS bundle")
  version,=unpack(f,"I");engine=zread(f);revision=zread(f)
  total,cs,us,flags=unpack(f,"QIII")
  if version>=7:f.seek((-f.tell())%16,1)
  headerend=f.tell()
  if flags&128:f.seek(total-cs)
  info=io.BytesIO(decode(f.read(cs),us,flags))
  start=headerend if flags&128 else f.tell()
  if flags&512:start+=( -start)%16
  info.read(16);count,=unpack(info,"I")
  blocks=[unpack(info,"IIH") for _ in range(count)]
  count,=unpack(info,"I")
  nodes=[]
  for n in range(count):
   offset,size,nflags=unpack(info,"QQI");name=zread(info)
   nodes.append(dict(offset=offset,size=size,flags=nflags,name=name,path=str(dest/("node"+str(n)))))
  handles=[open(n["path"],"wb") for n in nodes]
  try:
   f.seek(start);pos=0
   for us,cs,bflags in blocks:
    data=decode(f.read(cs),us,bflags)
    for node,out in zip(nodes,handles):
     a=max(pos,node["offset"]);b=min(pos+us,node["offset"]+node["size"])
     if b>a:out.write(data[a-pos:b-pos])
    pos+=us
  finally:
   for h in handles:h.close()
  for n in nodes:
   if pathlib.Path(n["path"]).stat().st_size!=n["size"]:raise ValueError("Truncated node")
  return dict(version=version,engine=engine,revision=revision,nodes=nodes)
def pack(meta,dest):
 temp=str(dest)+".blocks";blocks=[];nodes=[];offset=0
 with open(temp,"wb") as data:
  for n in meta["nodes"]:
   size=pathlib.Path(n["path"]).stat().st_size
   nodes.append(dict(n,offset=offset,size=size));offset+=size
   with open(n["path"],"rb") as src:
    while True:
     raw=src.read(131072)
     if not raw:break
     comp=lz4.block.compress(raw,store_size=False)
     data.write(comp);blocks.append((len(raw),len(comp),2))
 info=io.BytesIO();info.write(bytes(16));info.write(struct.pack(">I",len(blocks)))
 for b in blocks:info.write(struct.pack(">IIH",*b))
 info.write(struct.pack(">I",len(nodes)))
 for n in nodes:info.write(struct.pack(">QQI",n["offset"],n["size"],n["flags"])+n["name"].encode()+b"\0")
 raw=info.getvalue();comp=lz4.block.compress(raw,store_size=False)
 header=b"UnityFS\0"+struct.pack(">I",6)+meta["engine"].encode()+b"\0"+meta["revision"].encode()+b"\0"
 total=len(header)+20+len(comp)+pathlib.Path(temp).stat().st_size
 with open(dest,"wb") as out,open(temp,"rb") as src:
  out.write(header+struct.pack(">QIII",total,len(comp),len(raw),66));out.write(comp);shutil.copyfileobj(src,out,1024*1024)
 pathlib.Path(temp).unlink()
