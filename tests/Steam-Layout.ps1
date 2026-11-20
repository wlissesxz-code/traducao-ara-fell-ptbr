$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\lib\Installer.Core.ps1')
$testRoot=Join-Path $PSScriptRoot ('fixtures-'+[guid]::NewGuid().ToString('N'))
foreach ($name in @('GOG','Steam','Classic','Both','Incomplete')) { [void](New-Item -ItemType Directory -Force -Path (Join-Path $testRoot $name)) }
function Assert($value,$message) { if (-not $value) { throw $message } }
function Fixture($name,$exe,$data) {
    $root=Join-Path $testRoot $name
    [void](New-Item -ItemType Directory -Force -Path (Join-Path $root "$data\Managed"))
    foreach ($rel in @($exe,"$data\data.unity3d","$data\Managed\Assembly-CSharp.dll")) { [IO.File]::WriteAllText((Join-Path $root $rel),'fixture') }
}
Fixture GOG 'Ara Fell.exe' 'Ara Fell_Data'
Fixture Steam 'RPG_RT.exe' 'RPG_RT_Data'
Fixture Both 'Ara Fell.exe' 'Ara Fell_Data'
Fixture Both 'RPG_RT.exe' 'RPG_RT_Data'
[IO.File]::WriteAllText((Join-Path $testRoot 'Steam\Legacy.exe'),'legacy')
[IO.File]::WriteAllText((Join-Path $testRoot 'Classic\RPG_RT.exe'),'classic')
Fixture Incomplete 'RPG_RT.exe' 'RPG_RT_Data'
Remove-Item -LiteralPath (Join-Path $testRoot 'Incomplete\RPG_RT_Data\Managed\Assembly-CSharp.dll')
foreach ($case in @(@('GOG','Ara Fell_Data','Ara Fell.exe'),@('Steam','RPG_RT_Data','RPG_RT.exe'))) {
    $root=Join-Path $testRoot $case[0];$expected=Join-Path $root $case[1]
    foreach ($inputPath in @($root,$expected,(Join-Path $root $case[2]),($expected+'\'))) {
        Assert ((Resolve-GameData $inputPath).TrimEnd('\') -eq $expected) "Detection failed: $inputPath"
    }
    $before=Get-Sha256 (Join-Path $expected 'data.unity3d')
    $failed=$false
    try { Get-InstallPlan $root | Out-Null } catch { $failed=$_.Exception.Message -like '*ainda nao*' }
    Assert $failed 'Unknown files should be refused'
    Assert ((Get-Sha256 (Join-Path $expected 'data.unity3d')) -eq $before) 'Unexpected mutation'
    Assert (-not (Test-Path (Join-Path $expected 'data.unity3d.original-antes-ptbr.bak'))) 'Unexpected backup'
}
foreach ($name in @('Classic','Both','Incomplete')) {
    $failed=$false;try { Resolve-GameData (Join-Path $testRoot $name) | Out-Null } catch {$failed=$true}
    Assert $failed "Should reject: $name"
}
Assert ((Resolve-GameData (Join-Path $testRoot 'Both\RPG_RT_Data')) -like '*RPG_RT_Data') 'Direct selection failed'
# Exercise running-game guard before any write, with mocked compatibility only.
function Get-InstallPlan { [pscustomobject]@{Files=@()} }
function Test-Package {}
function Get-Process { param($Name,$ErrorAction); Assert ($Name -contains 'RPG_RT') 'Missing Steam process guard'; [pscustomobject]@{Name='RPG_RT'} }
$failed=$false;try { Invoke-Translation 'unused' } catch {$failed=$_.Exception.Message -like '*Feche o Ara Fell*'}
Assert $failed 'Running Steam game not blocked'
Write-Output 'PASS: GOG/Steam root, exe, data, trailing slash; classic/incomplete/ambiguous refusal; unsupported files untouched; Steam running-game guard.'
