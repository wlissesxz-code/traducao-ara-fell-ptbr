param([string]$PastaJogo,[ValidateSet('Instalar','Verificar','Restaurar')][string]$Acao='Instalar',[switch]$SemInterface)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'lib\Installer.Core.ps1')
if ($SemInterface) {
    try { Write-Output (Invoke-Translation $PastaJogo $Acao); exit 0 } catch { Write-Error $_.Exception.Message; exit 1 }
}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object Windows.Forms.Form
$form.Text = 'Ara Fell - Tradução PT-BR'
$form.Size = New-Object Drawing.Size(740,430)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object Drawing.Font('Segoe UI',10)
$title = New-Object Windows.Forms.Label
$title.Text = 'Ara Fell: Enhanced Edition em português do Brasil'
$title.Font = New-Object Drawing.Font('Segoe UI',14,[Drawing.FontStyle]::Bold)
$title.SetBounds(22,20,690,35)
$form.Controls.Add($title)
$help = New-Object Windows.Forms.Label
$help.Text = "Escolha a pasta onde está Ara Fell.exe (Steam ou GOG).`r`nFeche o jogo antes de instalar. Seus jogos salvos não serão alterados."
$help.SetBounds(22,65,680,50)
$form.Controls.Add($help)
$folder = New-Object Windows.Forms.ComboBox
$folder.SetBounds(22,127,560,30)
$folder.DropDownStyle = 'DropDown'
foreach ($path in @(Find-GameInstallations)) { [void]$folder.Items.Add($path) }
if ($PastaJogo) {$folder.Text=$PastaJogo} elseif ($folder.Items.Count) {$folder.SelectedIndex=0}
$form.Controls.Add($folder)
$browse = New-Object Windows.Forms.Button
$browse.Text='Procurar...'
$browse.SetBounds(594,125,108,32)
$browse.Add_Click({
    $dialog=New-Object Windows.Forms.FolderBrowserDialog
    $dialog.Description='Escolha a pasta do Ara Fell: Enhanced Edition'
    $dialog.ShowNewFolderButton=$false
    if ($folder.Text -and (Test-Path -LiteralPath $folder.Text)) {$dialog.SelectedPath=$folder.Text}
    if ($dialog.ShowDialog($form) -eq 'OK') {$folder.Text=$dialog.SelectedPath}
    $dialog.Dispose()
})
$form.Controls.Add($browse)
$status=New-Object Windows.Forms.TextBox
$status.Multiline=$true
$status.ReadOnly=$true
$status.ScrollBars='Vertical'
$status.BackColor=[Drawing.Color]::White
$status.SetBounds(22,175,680,110)
$status.Text="Versão 6.1.0 - tradução completa.`r`nGOG: testada. Steam: detecção disponível; aplicação condicionada à verificação dos arquivos.`r`nO patch recusa versões diferentes, sem alterar a instalação."
$form.Controls.Add($status)
$buttons=@()
foreach ($item in @(@('Instalar tradução','Instalar',22,210),@('Verificar','Verificar',244,130),@('Restaurar original','Restaurar',386,170))) {
    $button=New-Object Windows.Forms.Button
    $button.Text=$item[0]
    $button.Tag=$item[1]
    $button.SetBounds([int]$item[2],305,[int]$item[3],38)
    $button.Add_Click({
        param($sender,$eventArgs)
        if ($sender.Tag -eq 'Restaurar') {
            $answer=[Windows.Forms.MessageBox]::Show($form,'Antes de restaurar, selecione English nas opções do jogo e feche o jogo. Já fez isso?','Restaurar original','YesNo','Question')
            if ($answer -ne 'Yes') {return}
        }
        foreach ($control in $buttons) {$control.Enabled=$false};$browse.Enabled=$false;$folder.Enabled=$false
        $form.UseWaitCursor=$true
        $status.Text='Conferindo arquivos e preparando a operação. Aguarde...'
        [Windows.Forms.Application]::DoEvents()
        try {$status.Text=Invoke-Translation $folder.Text ([string]$sender.Tag)} catch {$status.Text=$_.Exception.Message}
        finally {foreach ($control in $buttons) {$control.Enabled=$true};$browse.Enabled=$true;$folder.Enabled=$true;$form.UseWaitCursor=$false}
    })
    $buttons+= $button
    $form.Controls.Add($button)
}
$note=New-Object Windows.Forms.Label
$note.Text='Após instalar: Opções > idioma > Português (Brasil). A cópia original fica preservada.'
$note.SetBounds(22,359,680,30)
$form.Controls.Add($note)
[void]$form.ShowDialog()
$form.Dispose()
