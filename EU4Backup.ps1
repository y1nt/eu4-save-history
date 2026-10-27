$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
. (Join-Path $PSScriptRoot 'Engine.ps1')
$mutex = New-Object Threading.Mutex($false, 'Local\EU4SaveHistoryTool')
if (-not $mutex.WaitOne(0)) {
    [Windows.Forms.MessageBox]::Show('工具已经在运行，请查看任务栏。', 'EU4 存档备份') | Out-Null
    exit
}
$backupRoot = Join-Path $PSScriptRoot 'Backups'
$configPath = Join-Path $PSScriptRoot 'settings.json'
$defaultSource = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Paradox Interactive\Europa Universalis IV\save games'
if (Test-Path -LiteralPath $configPath) {
    try { $defaultSource = (Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json).Source } catch {}
}
$form = New-Object Windows.Forms.Form
$form.Text = 'EU4 存档时光机 — 保留前两次存档'
$form.ClientSize = New-Object Drawing.Size(760, 450)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10)
function Add-Label($Text, $X, $Y, $W, $H) {
    $control = New-Object Windows.Forms.Label
    $control.Text = $Text; $control.SetBounds($X, $Y, $W, $H)
    $form.Controls.Add($control)
    return $control
}
$null = Add-Label '存档目录（仅监视此目录中的 .eu4 文件）' 20 15 700 25
$pathBox = New-Object Windows.Forms.TextBox
$pathBox.Text = $defaultSource; $pathBox.SetBounds(20, 45, 620, 30)
$form.Controls.Add($pathBox)
function Add-Button($Text, $X, $Y, $W) {
    $button = New-Object Windows.Forms.Button
    $button.Text = $Text; $button.SetBounds($X, $Y, $W, 35)
    $form.Controls.Add($button)
    return $button
}
$browse = Add-Button '选择…' 650 43 90
$toggle = Add-Button '暂停备份' 20 92 130
$open = Add-Button '打开备份文件夹' 165 92 180
$status = Add-Label '' 20 145 720 30
$null = Add-Label "每个存档保留 3 份：最新版本 + 前一次 + 前两次。文件名时间为 UTC。`n首次启动先保存现有版本；之后每次检测到内容变化便轮换备份。" 20 180 720 55
$log = New-Object Windows.Forms.TextBox
$log.Multiline = $true; $log.ReadOnly = $true; $log.ScrollBars = 'Vertical'
$log.SetBounds(20, 245, 720, 150); $form.Controls.Add($log)
$null = Add-Label '玩游戏时保持工具运行；可最小化，关闭窗口将停止备份。' 20 410 720 25
$script:running = $true
$script:lastError = ''
function Add-Log([string]$Text) {
    try { Add-Content -LiteralPath (Join-Path $PSScriptRoot 'activity.log') -Value ((Get-Date -Format 's') + ' ' + $Text) -Encoding UTF8 } catch {}
    if ($log.TextLength -gt 16000) { $log.Text = $log.Text.Substring($log.TextLength - 8000) }
    $log.AppendText(('[' + (Get-Date -Format 'HH:mm:ss') + '] ' + $Text + [Environment]::NewLine))
}
function Set-Running([bool]$Value) {
    $script:running = $Value
    $pathBox.Enabled = -not $Value; $browse.Enabled = -not $Value
    if ($Value) { $toggle.Text = '暂停备份'; $status.Text = '正在监视 · 写入结束并稳定 4 秒后备份' }
    else { $toggle.Text = '开始备份'; $status.Text = '已暂停 · 可以修改存档目录' }
}
$browse.Add_Click({
    $dialog = New-Object Windows.Forms.FolderBrowserDialog
    $dialog.SelectedPath = $pathBox.Text
    if ($dialog.ShowDialog() -eq 'OK') { $pathBox.Text = $dialog.SelectedPath }
    $dialog.Dispose()
})
$toggle.Add_Click({
    if ($script:running) { Set-Running $false; return }
    if (-not [IO.Directory]::Exists($pathBox.Text)) {
        [Windows.Forms.MessageBox]::Show('请选择有效的存档目录。') | Out-Null; return
    }
    try {
        @{ Source = $pathBox.Text } | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8
        $script:observed = @{}; $script:completed = @{}
        Set-Running $true
    } catch { Add-Log $_.Exception.Message }
})
$open.Add_Click({
    try {
        [IO.Directory]::CreateDirectory($backupRoot) | Out-Null
        Start-Process explorer.exe -ArgumentList ('"' + $backupRoot + '"')
    } catch { Add-Log $_.Exception.Message }
})
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    if (-not $script:running) { return }
    try {
        $messages = @(Invoke-BackupScan $pathBox.Text $backupRoot 4 -WarningVariable scanWarnings -WarningAction SilentlyContinue)
        foreach ($message in $messages) { Add-Log $message }
        $warningText = (@($scanWarnings) -join '; ')
        if ($warningText) {
            $status.Text = '部分文件暂未备份 · 正在自动重试'
            if ($warningText -ne $script:lastError) { Add-Log $warningText }
            $script:lastError = $warningText
        } else {
            $script:lastError = ''
            $status.Text = '正在监视 · 写入结束并稳定 4 秒后备份'
        }
    } catch {
        $status.Text = '暂时无法备份 · 将自动重试'
        if ($_.Exception.Message -ne $script:lastError) { Add-Log $_.Exception.Message; $script:lastError = $_.Exception.Message }
    }
})
$form.Add_Shown({ Set-Running $true; Add-Log '监视已启动。现有存档将作为第一个版本保存。'; $timer.Start() })
try { [Windows.Forms.Application]::Run($form) }
finally { $timer.Stop(); $timer.Dispose(); $mutex.ReleaseMutex(); $mutex.Dispose(); $form.Dispose() }
