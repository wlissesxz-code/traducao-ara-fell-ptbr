function Initialize-Package {
    $manifest = Get-PatchManifest
    $missing = @($manifest.payloads | Where-Object { -not (Test-Path -LiteralPath (Join-Path $script:PackageRoot $_.path) -PathType Leaf) })
    if (-not $missing.Count) { Test-Package; return }
    Write-Host 'Preparando a traducao: baixando os componentes oficiais deste projeto (aprox. 145 MB)...'
    $temporary = Join-Path $script:PackageRoot ('.download-ptbr-'+[guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $temporary)
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $archive = Join-Path $temporary 'release.zip'
        Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/wlissesxz-code/traducao-ara-fell-ptbr/releases/download/v6.1.1/Ara-Fell-PTBR-6.1.1-Windows.zip' -OutFile $archive
        if ((Get-Sha256 $archive) -ne '82DE7F7D0950B217739DB524EEEECF8EA51B9FAD0AF5F96BFF254E01A3B292FB') { throw 'O download nao passou na verificacao. Tente novamente.' }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($archive)
        try {
            # Extract only the three fixed payloads, never scripts or arbitrary ZIP paths.
            foreach ($payload in $manifest.payloads) {
                if ($payload.path -notin @('bin/xdelta3.exe','patches/data.vcdiff','patches/assembly.vcdiff')) { throw 'Componente inesperado no manifesto.' }
                $entry = $zip.GetEntry('Ara-Fell-PTBR/'+$payload.path)
                if (-not $entry) { throw 'Download incompleto.' }
                $staged = Join-Path $temporary ([IO.Path]::GetFileName($payload.path))
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$staged)
                if ((Get-Sha256 $staged) -ne $payload.sha256) { throw 'Componente invalido no download.' }
            }
        } finally { $zip.Dispose() }
        foreach ($payload in $manifest.payloads) {
            $target = Join-Path $script:PackageRoot $payload.path
            [void](New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent))
            Copy-Item -LiteralPath (Join-Path $temporary ([IO.Path]::GetFileName($payload.path))) -Destination $target -Force
        }
        Test-Package
    } finally {
        $resolved = [IO.Path]::GetFullPath($temporary)
        if ((Split-Path $resolved -Parent) -eq [IO.Path]::GetFullPath($script:PackageRoot) -and (Split-Path $resolved -Leaf) -match '^\.download-ptbr-[a-f0-9]{32}$') { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}
