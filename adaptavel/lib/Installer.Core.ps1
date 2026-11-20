param()
Set-StrictMode -Version 2.0
$script:PackageRoot = Split-Path $PSScriptRoot -Parent
function Get-Sha256([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash }
function Get-PatchManifest { Get-Content -LiteralPath (Join-Path $script:PackageRoot 'patches\manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json }
function Resolve-GameData([string]$Folder) {
    if ([string]::IsNullOrWhiteSpace($Folder)) { throw 'Escolha a pasta do Ara Fell: Enhanced Edition.' }
    $full = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($Folder.Trim().Trim('"')))
    if (Test-Path -LiteralPath $full -PathType Leaf) { $full = Split-Path $full -Parent }
    $layouts = @(
        @{Data='Ara Fell_Data'; Exe='Ara Fell.exe'},
        @{Data='RPG_RT_Data'; Exe='RPG_RT.exe'}
    )
    $leaf = Split-Path $full -Leaf
    $direct = @($layouts | Where-Object {$_.Data -eq $leaf})
    $root = if ($direct.Count) { Split-Path $full -Parent } else { $full }
    $matches = @()
    foreach ($layout in $layouts) {
        if ($direct.Count -and $layout.Data -ne $leaf) { continue }
        $data = Join-Path $root $layout.Data
        if ((Test-Path -LiteralPath (Join-Path $root $layout.Exe) -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $data 'data.unity3d') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $data 'Managed\Assembly-CSharp.dll') -PathType Leaf)) {
            $matches += $data
        }
    }
    if ($matches.Count -eq 1) { return $matches[0] }
    if ($matches.Count -gt 1) { throw 'Foram encontradas duas instalacoes. Selecione diretamente Ara Fell_Data ou RPG_RT_Data.' }
    throw 'Nao foi encontrada a Enhanced Edition completa. Selecione a pasta do jogo ou Ara Fell_Data / RPG_RT_Data. A versao classica nao e compativel.'
}

function Find-SteamGames([string[]]$SteamRoots) {
    $libraries = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($root in $SteamRoots) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        [void]$libraries.Add($root)
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            $text = Get-Content -LiteralPath $vdf -Raw
            foreach ($match in [regex]::Matches($text,'"(?:path|\d+)"\s+"((?:[^"\\]|\\.)*)"')) {
                $path = $match.Groups[1].Value.Replace('\\','\')
                if ($path -match '^[A-Za-z]:[\\/]' -or $path -match '^\\\\') { [void]$libraries.Add($path) }
            }
        }
    }
    foreach ($library in $libraries) {
        $manifest = Join-Path $library 'steamapps\appmanifest_440540.acf'
        if (Test-Path -LiteralPath $manifest) {
            $text = Get-Content -LiteralPath $manifest -Raw
            $match = [regex]::Match($text,'"installdir"\s+"([^"]+)"')
            if ($match.Success -and $match.Groups[1].Value -notmatch '[\\/]|\.\.') { Join-Path $library ('steamapps\common\' + $match.Groups[1].Value) }
        }
        foreach ($name in @('Ara Fell','Ara Fell Enhanced Edition','Ara Fell Enhanced')) { Join-Path $library ('steamapps\common\'+$name) }
    }
}
function Find-GameInstallations {
    $roots = New-Object 'System.Collections.Generic.List[string]'
    foreach ($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
        $value = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if ($value) { foreach ($prop in @('SteamPath','InstallPath')) { if ($value.PSObject.Properties[$prop]) { $roots.Add([string]$value.$prop) } } }
    }
    if (${env:ProgramFiles(x86)}) { $roots.Add((Join-Path ${env:ProgramFiles(x86)} 'Steam')) }
    $candidates = New-Object 'System.Collections.Generic.List[string]'
    foreach ($folder in (Find-SteamGames $roots.ToArray())) { $candidates.Add($folder) }
    foreach ($base in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games')) {
        foreach ($key in (Get-ChildItem -LiteralPath $base -ErrorAction SilentlyContinue)) {
            $value = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction SilentlyContinue
            if (-not $value) { continue }
            $title = ''; foreach ($prop in @('DisplayName','gameName')) { if ($value.PSObject.Properties[$prop]) { $title += [string]$value.$prop } }
            if ($title -match 'Ara\s*Fell') { foreach ($prop in @('InstallLocation','path')) { if ($value.PSObject.Properties[$prop] -and $value.$prop) { $candidates.Add([string]$value.$prop) } } }
        }
    }
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem)) { foreach ($rel in @('GOG Games\Ara Fell','GOG Games\Ara Fell Enhanced Edition','Games\Ara Fell')) { $candidates.Add((Join-Path $drive.Root $rel)) } }
    $found = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($candidate in $candidates) { try { $data = Resolve-GameData $candidate; if ($found.Add($data)) { Split-Path $data -Parent } } catch {} }
}
