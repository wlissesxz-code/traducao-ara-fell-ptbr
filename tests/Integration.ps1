param([string]$OriginalData,[string]$OriginalAssembly,[string]$PackageRoot,[string]$TestRoot)
$ErrorActionPreference='Stop'
. (Join-Path $PackageRoot 'lib\Installer.Core.ps1')
$root=[IO.Path]::GetFullPath($TestRoot)
New-Item -ItemType Directory -Path (Join-Path $root 'Ara Fell_Data\Managed') -Force | Out-Null
Set-Content -LiteralPath (Join-Path $root 'Ara Fell.exe') -Value 'Test fixture - not an executable' -Encoding ASCII
$data=Join-Path $root 'Ara Fell_Data\data.unity3d'
$dll=Join-Path $root 'Ara Fell_Data\Managed\Assembly-CSharp.dll'
Copy-Item -LiteralPath $OriginalData -Destination $data -Force
Copy-Item -LiteralPath $OriginalAssembly -Destination $dll -Force
$m=Get-PatchManifest
function Assert([bool]$Value,[string]$Message) {if(-not $Value){throw $Message}}
Write-Host '1. Verificacao da instalacao limpa'
Invoke-Translation $root 'Verificar'
Write-Host '2. Instalacao real do patch e verificacao dos dois resultados'
Invoke-Translation $root 'Instalar'
foreach($entry in $m.files){Assert ((Get-Sha256 (Join-Path (Join-Path $root 'Ara Fell_Data') $entry.path)) -eq $entry.updated) 'Hash final incorreto'}
Write-Host '3. Reinstalacao idempotente'
Invoke-Translation $root 'Instalar'
Write-Host '4. Restauracao exata dos originais'
Invoke-Translation $root 'Restaurar'
Assert ((Get-Sha256 $data) -eq $m.files[0].original) 'Restauracao do pacote falhou'
Assert ((Get-Sha256 $dll) -eq $m.files[1].original) 'Restauracao da DLL falhou'
Write-Host '5. Falha durante a segunda substituicao recupera a primeira'
$lock=[IO.File]::Open($dll,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
$failed=$false
try {Invoke-Translation $root 'Instalar'} catch {$failed=$true} finally {$lock.Dispose()}
Assert $failed 'O bloqueio deveria provocar falha'
Assert ((Get-Sha256 $data) -eq $m.files[0].original) 'Rollback do primeiro arquivo falhou'
Assert ((Get-Sha256 $dll) -eq $m.files[1].original) 'O segundo arquivo foi alterado apesar do bloqueio'
Write-Host '6. Versao desconhecida recusada sem alterar o outro arquivo'
$f=[IO.File]::Open($dll,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite);$f.Position=100;$old=$f.ReadByte();$f.Position=100;$f.WriteByte($old -bxor 1);$f.Dispose()
$bad=Get-Sha256 $dll;$failed=$false
try {Invoke-Translation $root 'Instalar'} catch {$failed=$true}
Assert $failed 'Versao desconhecida deveria ser recusada'
Assert ((Get-Sha256 $dll) -eq $bad) 'Arquivo desconhecido foi alterado'
Assert ((Get-Sha256 $data) -eq $m.files[0].original) 'Outro arquivo foi alterado'
Copy-Item -LiteralPath $OriginalAssembly -Destination $dll -Force
Write-Host '7. Descoberta Steam em biblioteca secundaria com espacos'
$steam=Join-Path $root 'fake steam';$library=Join-Path $root 'biblioteca secundaria';$game=Join-Path $library 'steamapps\common\Ara Fell'
New-Item -ItemType Directory -Path (Join-Path $steam 'steamapps'),(Join-Path $library 'steamapps') -Force | Out-Null
$escaped=$library.Replace('\','\\')
Set-Content -LiteralPath (Join-Path $steam 'steamapps\libraryfolders.vdf') -Value ('"libraryfolders" { "1" { "path" "'+$escaped+'" } }')
Set-Content -LiteralPath (Join-Path $library 'steamapps\appmanifest_440540.acf') -Value '"AppState" { "appid" "440540" "installdir" "Ara Fell" }'
Assert ($game -in @(Find-SteamGames @($steam))) 'Biblioteca secundaria Steam nao descoberta'
Write-Host 'PASSOU: instalacao, reinstalacao, restauracao, rollback, recusa e descoberta Steam.'
