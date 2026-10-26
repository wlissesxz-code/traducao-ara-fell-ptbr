param([Parameter(Mandatory=$true)][string]$OriginalDataFolder,[Parameter(Mandatory=$true)][string]$TranslatedDataFolder,[Parameter(Mandatory=$true)][string]$XdeltaExe)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'lib\Installer.Core.ps1')
$m=Get-PatchManifest
foreach($e in $m.files){
    $a=Join-Path $OriginalDataFolder $e.path;$b=Join-Path $TranslatedDataFolder $e.path
    if((Get-Sha256 $a) -ne $e.original -or (Get-Sha256 $b) -ne $e.updated){throw ('Arquivos de entrada nao correspondem ao manifesto: '+$e.path)}
}
if((Get-Sha256 $XdeltaExe) -ne ($m.payloads | Where-Object path -eq 'bin/xdelta3.exe').sha256){throw 'Use o Xdelta 3.2.2 oficial correspondente ao manifesto.'}
foreach($e in $m.files){
    $out=Join-Path $root $e.patch
    if(Test-Path -LiteralPath $out){throw ('O destino ja existe. Use uma copia limpa do projeto: '+$e.patch)}
    & $XdeltaExe -e -9 -s (Join-Path $OriginalDataFolder $e.path) (Join-Path $TranslatedDataFolder $e.path) $out
    if($LASTEXITCODE -ne 0){throw 'Falha ao criar patch'}
    $payload=$m.payloads | Where-Object path -eq $e.patch; $payload.sha256=Get-Sha256 $out; $payload.size=(Get-Item -LiteralPath $out).Length
}
$m | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $root 'patches\manifest.json') -Encoding UTF8
Write-Host 'Patches recriados; manifesto atualizado. Teste antes de publicar.'
