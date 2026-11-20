param([string]$PastaJogo,[ValidateSet('Instalar','Verificar','Restaurar')][string]$Acao='Instalar',[switch]$SemInterface)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'lib\Installer.Core.ps1')
. (Join-Path $PSScriptRoot 'lib\Adaptive.ps1')

if ($SemInterface) {
    try { Write-Output (Invoke-Adaptive $PastaJogo $Acao); exit 0 } catch { Write-Error $_.Exception.Message; exit 1 }
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
$help.Text = "Escolha a pasta do Ara Fell (Steam ou GOG).`r`nFeche o jogo antes de instalar. Seus jogos salvos não serão alterados."
$help.SetBounds(22,65,680,50)
$form.Controls.Add($help)
$gameFolderPicker = New-Object Windows.Forms.ComboBox
$gameFolderPicker.SetBounds(22,127,560,30)
$gameFolderPicker.DropDownStyle = 'DropDown'
foreach ($path in @(Find-GameInstallations)) { [void]$gameFolderPicker.Items.Add($path) }
if ($PastaJogo) {$gameFolderPicker.Text=$PastaJogo} elseif ($gameFolderPicker.Items.Count) {$gameFolderPicker.SelectedIndex=0}
$form.Controls.Add($gameFolderPicker)
$browse = New-Object Windows.Forms.Button
$browse.Text='Procurar...'
$browse.SetBounds(594,125,108,32)
$browse.Add_Click({
    $dialog=New-Object Windows.Forms.FolderBrowserDialog
    $dialog.Description='Escolha a pasta do Ara Fell: Enhanced Edition'
    $dialog.ShowNewFolderButton=$false
    if ($gameFolderPicker.Text -and (Test-Path -LiteralPath $gameFolderPicker.Text)) {$dialog.SelectedPath=$gameFolderPicker.Text}
    if ($dialog.ShowDialog($form) -eq 'OK') {$gameFolderPicker.Text=$dialog.SelectedPath}
    $dialog.Dispose()
})
$form.Controls.Add($browse)
$status=New-Object Windows.Forms.TextBox
$status.Multiline=$true
$status.ReadOnly=$true
$status.ScrollBars='Vertical'
$status.BackColor=[Drawing.Color]::White
$status.SetBounds(22,175,680,110)
$status.Text="Versão 6.2 de teste - instalador adaptável.`r`nAdapta textos e fontes locais. Preparo pode levar alguns minutos.`r`nExige cerca de 5 GB livres para o preparo e os backups."
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
        foreach ($control in $buttons) {$control.Enabled=$false};$browse.Enabled=$false;$gameFolderPicker.Enabled=$false
        $form.UseWaitCursor=$true
        $status.Text='Adaptando e conferindo os arquivos. Aguarde alguns minutos; esta janela pode ficar sem responder.'
        [Windows.Forms.Application]::DoEvents()
        try {$status.Text=Invoke-Adaptive $gameFolderPicker.Text ([string]$sender.Tag)} catch {$status.Text=$_.Exception.Message}
        finally {foreach ($control in $buttons) {$control.Enabled=$true};$browse.Enabled=$true;$gameFolderPicker.Enabled=$true;$form.UseWaitCursor=$false}
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
