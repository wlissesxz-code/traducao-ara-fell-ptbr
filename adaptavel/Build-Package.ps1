$ErrorActionPreference='Stop'
$root=$PSScriptRoot
Set-Location $root
function Download-Checked($url,$file,$sha){
 Invoke-WebRequest -Uri $url -OutFile $file
 if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $sha){throw "Download integrity failure: $file"}
}
Download-Checked 'https://www.python.org/ftp/python/3.12.10/python-3.12.10-embed-amd64.zip' 'python-runtime.zip' '4ACBED6DD1C744B0376E3B1CF57CE906F9DC9E95E68824584C8099A63025A3C3'
Expand-Archive python-runtime.zip runtime -Force
[IO.File]::WriteAllText((Join-Path $root 'runtime\python312._pth'),"python312.zip`r`n.`r`n..\python-libs`r`n..\tools`r`n")
python -m pip install --only-binary=:all: --target python-libs -r requirements.txt
if($LASTEXITCODE -ne 0){throw 'Dependency installation failed'}
Download-Checked 'https://api.nuget.org/v3-flatcontainer/mono.cecil/0.11.6/mono.cecil.0.11.6.nupkg' 'cecil.zip' 'D2A23832AAA948BA9A01ACC42B5726E34C5F995958F1B30D45C0E7C70B3A72D5'
Expand-Archive cecil.zip cecil -Force
Copy-Item cecil\lib\net40\Mono.Cecil.dll tools\Mono.Cecil.dll
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /r:tools\Mono.Cecil.dll /out:tools\PatchLanguage.exe tools\PatchLanguage.cs
if($LASTEXITCODE -ne 0){throw 'Compiler failed'}
& .\runtime\python.exe -X utf8 tools\package.py
if($LASTEXITCODE -ne 0){throw 'Package check failed'}
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Test-InstallerWindow.ps1
if($LASTEXITCODE -ne 0){throw 'Installer UI check failed'}
