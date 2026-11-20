import json,pathlib,zipfile,hashlib
root=pathlib.Path(__file__).resolve().parents[1]
reference={}
for p in sorted((root/"reference-parts").glob("*.json")):
 part=json.loads(p.read_text(encoding="utf-8-sig"))
 assert not (reference.keys() & part.keys())
 reference.update(part)
assert len(reference)==17647
(root/"reference.json").write_text(json.dumps(reference,ensure_ascii=False,separators=(",",":")),encoding="utf-8")
files=[root/p for p in ["Instalar.cmd","Instalar.ps1","LEIA-ME.txt","reference.json"]]
files += [p for d in ["lib","runtime","python-libs","docs"] for p in (root/d).rglob("*") if p.is_file() and "__pycache__" not in p.parts and p.suffix!=".pyc"]
files += [root/"tools"/p for p in ["PatchLanguage.exe","PatchLanguage.cs","Mono.Cecil.dll","unity_stream.py","patch_assets.py","verify_assets.py"]]
assert len(files)>500
out=root/"output";out.mkdir(exist_ok=True)
archive=out/"Ara-Fell-PTBR-6.2-adaptavel-corrigido.zip"
with zipfile.ZipFile(archive,"w",zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for p in files:z.write(p,"Ara-Fell-PTBR-Adaptavel/"+p.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 assert len(z.infolist())==len(files)
 assert b"gameFolderPicker" in z.read("Ara-Fell-PTBR-Adaptavel/Instalar.ps1")
 assert not z.read("Ara-Fell-PTBR-Adaptavel/lib/Adaptive.ps1").decode("utf-8-sig").startswith("param(")
digest=hashlib.sha256(archive.read_bytes()).hexdigest()
(out/"SHA256SUMS.txt").write_text(digest+"  "+archive.name+"\n",encoding="utf-8")
print("PASS",len(files),"files",archive.stat().st_size,"bytes",digest)
