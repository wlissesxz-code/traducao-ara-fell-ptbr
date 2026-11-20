function Invoke-Adaptive([string]$Folder,[string]$Action) {
 $ErrorActionPreference='Stop'
 $data=Resolve-GameData $Folder
 if(Get-Process -Name 'Ara Fell','RPG_RT','Legacy' -ErrorAction SilentlyContinue){throw 'Feche o jogo antes de continuar.'}
 $statePath=Join-Path $data '.ptbr-adaptavel.json'
 $paths=@('data.unity3d','Managed\Assembly-CSharp.dll')
 $state=$null
 if(Test-Path -LiteralPath $statePath){$state=Get-Content -LiteralPath $statePath -Raw -Encoding UTF8|ConvertFrom-Json}
 $plan=@()
 for($i=0;$i -lt 2;$i++){
  $target=Join-Path $data $paths[$i];$backup=$target+'.antes-ptbr-adaptavel.bak';$current=Get-Sha256 $target
  if($state){
   if($state.Files.Count -ne 2 -or $state.Files[$i].Path -ne $paths[$i]){throw 'Registro de instalacao invalido.'}
   $entry=$state.Files[$i]
   if($current -notin @($entry.Original,$entry.Updated)){throw 'O jogo foi modificado depois da traducao. A instalacao atual foi preservada.'}
   if(-not(Test-Path -LiteralPath $backup) -or (Get-Sha256 $backup) -ne $entry.Original){throw 'A copia original esta ausente ou alterada.'}
   $base=$backup;$original=$entry.Original
  }else{
   $base=$target;$original=$current
   if(Test-Path -LiteralPath $backup){
    if((Get-Sha256 $backup) -ne $current){throw 'Ja existe uma copia de seguranca diferente. Ela foi preservada.'}
    $base=$backup
   }
  }
  $plan += [pscustomobject]@{Path=$paths[$i];Target=$target;Backup=$backup;Base=$base;Original=$original;Current=$current;Stage='';Rollback='';Updated=''}
 }
 if($Action -eq 'Restaurar' -and -not $state){throw 'Nao ha instalacao adaptavel registrada nesta pasta.'}
 if($Action -eq 'Instalar' -and $state -and $plan[0].Current -eq $state.Files[0].Updated -and $plan[1].Current -eq $state.Files[1].Updated){return 'A traducao adaptavel ja esta instalada.'}
 $stageRoot=Join-Path $data ('.ptbr-preparo-'+[guid]::NewGuid().ToString('N'))
 [void](New-Item -ItemType Directory -Path $stageRoot)
 $changed=New-Object 'System.Collections.Generic.List[object]'
 $preserve=$false;$stateWritten=$false;$oldState=if($state){[IO.File]::ReadAllBytes($statePath)}else{$null}
 try{
  foreach($p in $plan){$p.Stage=Join-Path $stageRoot ([IO.Path]::GetFileName($p.Path));$p.Rollback=$p.Stage+'.rollback'}
  if($Action -ne 'Restaurar'){
   $output=& (Join-Path $script:PackageRoot 'tools\PatchLanguage.exe') $plan[1].Base $plan[1].Stage 2>&1
   if($LASTEXITCODE -ne 0){throw ('Esta estrutura de idioma nao pode ser adaptada. Nada foi instalado. '+($output|Out-String))}
   $output=& (Join-Path $script:PackageRoot 'runtime\python.exe') -X utf8 (Join-Path $script:PackageRoot 'tools\patch_assets.py') $plan[0].Base $plan[0].Stage (Join-Path $stageRoot 'build') 2>&1
   if($LASTEXITCODE -ne 0){throw ('Nao foi possivel adaptar os textos/fontes. Nada foi instalado. '+($output|Out-String))}
   $report=Get-Content -LiteralPath (Join-Path $stageRoot 'build\report.json') -Raw -Encoding UTF8|ConvertFrom-Json
   if($report.wide.Count){throw 'A verificacao do tamanho dos dialogos falhou. Nada foi instalado.'}
   $output=& (Join-Path $script:PackageRoot 'runtime\python.exe') -X utf8 (Join-Path $script:PackageRoot 'tools\verify_assets.py') $plan[0].Base $plan[0].Stage '--no-preview' 2>&1
   if($LASTEXITCODE -ne 0){throw ('A verificacao dos arquivos adaptados falhou. Nada foi instalado. '+($output|Out-String))}
   if($Action -eq 'Verificar'){return ('Verificacao concluida: estrutura compativel. Linhas reconhecidas: '+$report.translated_matches+'/'+$report.rows+'. Nenhum arquivo do jogo foi substituido.')}
   foreach($p in $plan){$p.Updated=Get-Sha256 $p.Stage}
  }else{
   foreach($p in $plan){Copy-Item -LiteralPath $p.Backup -Destination $p.Stage;$p.Updated=$p.Original}
  }
  if(Get-Process -Name 'Ara Fell','RPG_RT','Legacy' -ErrorAction SilentlyContinue){throw 'O jogo foi aberto durante o preparo. Feche-o e tente novamente.'}
  foreach($p in $plan){
   if((Get-Sha256 $p.Target) -ne $p.Current){throw 'Os arquivos mudaram durante o preparo. Nada foi instalado.'}
   if(-not(Test-Path -LiteralPath $p.Backup)){Copy-Item -LiteralPath $p.Base -Destination $p.Backup}
   if((Get-Sha256 $p.Backup) -ne $p.Original){throw 'A copia de seguranca nao passou na verificacao.'}
  }
  foreach($p in $plan){
   [IO.File]::Replace($p.Stage,$p.Target,$p.Rollback);$changed.Add($p)
   if((Get-Sha256 $p.Target) -ne $p.Updated){throw 'Falha ao conferir o arquivo aplicado.'}
  }
  if($Action -eq 'Instalar'){
   $newState=@{Version='6.2.0-preview';Files=@($plan|Select-Object Path,Original,Updated);Unmatched=@($report.unmatched)}
   $stateTemp=Join-Path $stageRoot 'state.json'
   [IO.File]::WriteAllText($stateTemp,($newState|ConvertTo-Json -Depth 6),(New-Object Text.UTF8Encoding($true)))
   if(Test-Path -LiteralPath $statePath){[IO.File]::Replace($stateTemp,$statePath,$null)}else{[IO.File]::Move($stateTemp,$statePath)}
   $stateWritten=$true
   $message='Traducao instalada! Selecione Portugues (Brasil) nas opcoes do jogo.'
   if($report.unmatched.Count){$message+=' Algumas linhas novas foram mantidas em ingles: '+$report.unmatched.Count+'.'}
   return $message
  }
  return 'Arquivos originais restaurados. Os backups foram preservados.'
 }catch{
  $failure=$_.Exception.Message
  for($i=$changed.Count-1;$i -ge 0;$i--){
   try{[IO.File]::Replace($changed[$i].Rollback,$changed[$i].Target,$changed[$i].Stage)}catch{$preserve=$true}
  }
  if($stateWritten){
   try{if($oldState){[IO.File]::WriteAllBytes($statePath,$oldState)}else{Remove-Item -LiteralPath $statePath}}catch{$preserve=$true}
  }
  if($preserve){throw ($failure+' Preserve a pasta de recuperacao: '+$stageRoot)}
  throw ($failure+' A instalacao anterior foi preservada.')
 }finally{
  $resolved=[IO.Path]::GetFullPath($stageRoot)
  if(-not $preserve -and (Split-Path $resolved -Parent) -eq $data -and (Split-Path $resolved -Leaf) -match '^\.ptbr-preparo-[a-f0-9]{32}$'){Remove-Item -LiteralPath $resolved -Recurse -Force}
 }
}
