param()
Set-StrictMode -Version 2.0
$script:PackageRoot = Split-Path $PSScriptRoot -Parent
function Get-Sha256([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash }
function Get-PatchManifest { Get-Content -LiteralPath (Join-Path $script:PackageRoot 'patches\manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json }
function Resolve-GameData([string]$Folder) {
    if ([string]::IsNullOrWhiteSpace($Folder)) { throw 'Escolha a pasta do Ara Fell: Enhanced Edition.' }
    $full = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($Folder.Trim().Trim('"')))
    if (Test-Path -LiteralPath $full -PathType Leaf) { $full = Split-Path $full -Parent }
    if ((Split-Path $full -Leaf) -ne 'Ara Fell_Data') { $full = Join-Path $full 'Ara Fell_Data' }
    $root = Split-Path $full -Parent
    foreach ($relative in @('data.unity3d','Managed\Assembly-CSharp.dll')) {
        if (-not (Test-Path -LiteralPath (Join-Path $full $relative) -PathType Leaf)) { throw 'Esta pasta nao contem a Enhanced Edition para Windows. Selecione a pasta onde esta Ara Fell.exe.' }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $root 'Ara Fell.exe') -PathType Leaf)) { throw 'Ara Fell.exe nao foi encontrado junto de Ara Fell_Data.' }
    return $full
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
function Get-InstallPlan([string]$Folder) {
    $data = Resolve-GameData $Folder
    $manifest = Get-PatchManifest
    $plan = @()
    foreach ($entry in $manifest.files) {
        if ($entry.path -match '^[/\\]|\.\.' -or [IO.Path]::IsPathRooted($entry.path)) { throw 'Manifesto invalido.' }
        $target = Join-Path $data $entry.path
        $backup = $target + '.original-antes-ptbr.bak'
        $hash = Get-Sha256 $target
        if ($hash -notin @($entry.original,$entry.updated) + @($entry.previous)) {
            throw ('Versao ainda nao homologada: '+$entry.path+"`r`nSHA-256: "+$hash+"`r`nNenhum arquivo foi alterado. Informe este codigo em uma issue no GitHub; nao force a instalacao.")
        }
        $base = $target
        if (Test-Path -LiteralPath $backup) {
            if ((Get-Sha256 $backup) -ne $entry.original) { throw ('A copia original esta diferente da versao esperada: '+$entry.path) }
            $base = $backup
        } elseif ($hash -ne $entry.original) { throw ('Falta a copia original de '+$entry.path+'. Recupere o original pela sua loja antes de instalar.') }
        $plan += [pscustomobject]@{Entry=$entry;Target=$target;Backup=$backup;Base=$base;Current=$hash}
    }
    [pscustomobject]@{Data=$data;Files=$plan;Manifest=$manifest}
}
function Test-Package {
    $manifest = Get-PatchManifest
    foreach ($item in $manifest.payloads) {
        if ($item.path -match '^[/\\]|\.\.' -or [IO.Path]::IsPathRooted($item.path)) { throw 'Manifesto invalido.' }
        $path = Join-Path $script:PackageRoot $item.path
        if (-not (Test-Path -LiteralPath $path) -or (Get-Sha256 $path) -ne $item.sha256) { throw ('Pacote incompleto ou alterado: '+$item.path+'. Baixe e extraia o ZIP da release novamente.') }
    }
}
function Invoke-Translation([string]$Folder,[ValidateSet('Instalar','Verificar','Restaurar')][string]$Action='Instalar') {
    $plan = Get-InstallPlan $Folder
    Test-Package
    if ($Action -eq 'Verificar') { return ('Instalacao reconhecida. '+$(if (@($plan.Files | Where-Object {$_.Current -ne $_.Entry.updated}).Count -eq 0) {'A traducao completa ja esta aplicada.'} else {'Pronta para receber a traducao.'})) }
    if (Get-Process -Name 'Ara Fell' -ErrorAction SilentlyContinue) { throw 'Feche o Ara Fell antes de continuar.' }
    if ($Action -eq 'Restaurar') { foreach ($item in $plan.Files) { if (-not (Test-Path -LiteralPath $item.Backup)) { throw 'Nao ha copia original para restaurar. Nenhum arquivo foi alterado.' } } }
    if ($Action -eq 'Instalar' -and @($plan.Files | Where-Object {$_.Current -ne $_.Entry.updated}).Count -eq 0) { return 'A traducao completa ja esta aplicada.' }
    $temporary = Join-Path $plan.Data ('.ara-fell-ptbr-'+[guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $temporary)
    $changed = New-Object 'System.Collections.Generic.List[object]'
    try {
        $index = 0
        foreach ($item in $plan.Files) {
            $stage = Join-Path $temporary ('novo-'+$index)
            $rollback = Join-Path $temporary ('anterior-'+$index)
            if ($Action -eq 'Instalar') {
                $patch = Join-Path $script:PackageRoot $item.Entry.patch
                & (Join-Path $script:PackageRoot 'bin\xdelta3.exe') -d -s $item.Base $patch $stage
                if ($LASTEXITCODE -ne 0) { throw ('Nao foi possivel preparar '+$item.Entry.path+'. Nada foi instalado.') }
                $expected = $item.Entry.updated
            } else { Copy-Item -LiteralPath $item.Backup -Destination $stage; $expected = $item.Entry.original }
            if ((Get-Sha256 $stage) -ne $expected) { throw 'A verificacao do arquivo preparado falhou. Nada foi instalado.' }
            $item | Add-Member -NotePropertyName Stage -NotePropertyValue $stage
            $item | Add-Member -NotePropertyName Rollback -NotePropertyValue $rollback
            $index++
        }
        if ($Action -eq 'Instalar') {
            foreach ($item in $plan.Files) {
                if (-not (Test-Path -LiteralPath $item.Backup)) { Copy-Item -LiteralPath $item.Target -Destination $item.Backup }
                if ((Get-Sha256 $item.Backup) -ne $item.Entry.original) { throw 'Falha ao conferir a copia de seguranca original.' }
            }
        }
        foreach ($item in $plan.Files) {
            if ((Get-Sha256 $item.Target) -ne $item.Current) { throw 'O jogo foi alterado durante a instalacao. Tente novamente com o jogo e a loja fechados.' }
            [IO.File]::Replace($item.Stage,$item.Target,$item.Rollback)
            $changed.Add($item)
            $expected = if ($Action -eq 'Instalar') { $item.Entry.updated } else { $item.Entry.original }
            if ((Get-Sha256 $item.Target) -ne $expected) { throw 'Falha ao conferir o arquivo aplicado.' }
        }
    } catch {
        $failure = $_.Exception.Message
        $rollbackFailures = @()
        for ($i=$changed.Count-1;$i -ge 0;$i--) {
            $item = $changed[$i]
            try { [IO.File]::Replace($item.Rollback,$item.Target,$item.Stage) } catch { $rollbackFailures += $item.Target }
        }
        if ($rollbackFailures.Count) { throw ($failure+"`r`nA recuperacao automatica nao terminou. Preserve esta pasta para recuperar os arquivos: "+$temporary) }
        throw ($failure+"`r`nA instalacao anterior foi preservada.")
    } finally {
        # Remove apenas a pasta temporaria criada nesta operacao. Conserva-a se ainda houver recuperacao pendente.
        $pending = $false
        foreach ($item in $changed) { if ((Get-Sha256 $item.Target) -ne $item.Current -and (Test-Path -LiteralPath $item.Rollback)) { $pending = $true } }
        if (-not $pending -or @($changed | Where-Object {(Get-Sha256 $_.Target) -eq $(if ($Action -eq 'Instalar') {$_.Entry.updated} else {$_.Entry.original})}).Count -eq $plan.Files.Count) {
            $resolved = [IO.Path]::GetFullPath($temporary)
            if ((Split-Path $resolved -Parent) -eq $plan.Data -and (Split-Path $resolved -Leaf) -match '^\.ara-fell-ptbr-[a-f0-9]{32}$') { Remove-Item -LiteralPath $resolved -Recurse -Force }
        }
    }
    if ($Action -eq 'Restaurar') { return 'Arquivos originais restaurados. As copias de seguranca foram mantidas.' }
    return 'Traducao instalada! Abra o jogo e selecione Portugues (Brasil) nas opcoes de idioma.'
}

