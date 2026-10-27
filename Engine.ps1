$script:observed = @{}
$script:completed = @{}

function Get-ContentHash([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)) }
    finally { $sha.Dispose(); $stream.Dispose() }
}

function Get-SaveSignature($File) {
    return ('{0}:{1}' -f $File.Length, $File.LastWriteTimeUtc.Ticks)
}

function Save-Version([string]$Source, [string]$BackupRoot) {
    $inputStream = $null
    $outputStream = $null
    $temp = $null
    try {
        # Deny writes/deletion during the copy; retry next tick if EU4 is writing.
        $inputStream = [IO.File]::Open($Source, 'Open', 'Read', 'Read')
        if ($inputStream.Length -eq 0) { throw 'Save file is empty; waiting.' }
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $key = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Source.ToLowerInvariant())))).Replace('-', '').Substring(0, 16)
        } finally { $sha.Dispose() }
        $folder = Join-Path $BackupRoot (([IO.Path]::GetFileNameWithoutExtension($Source)) + '_' + $key)
        [IO.Directory]::CreateDirectory($folder) | Out-Null
        $temp = Join-Path $folder ([Guid]::NewGuid().ToString() + '.tmp')
        $outputStream = [IO.File]::Create($temp)
        $inputStream.CopyTo($outputStream)
        $outputStream.Flush($true)
        $outputStream.Dispose(); $outputStream = $null
        $inputStream.Dispose(); $inputStream = $null
        $hash = Get-ContentHash $temp
        $versions = @(Get-ChildItem -LiteralPath $folder -Filter '*.eu4' -File | Sort-Object Name -Descending)
        if ($versions.Count -gt 0 -and (Get-ContentHash $versions[0].FullName) -eq $hash) {
            return $null
        }
        $name = (Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss_fffffff') + '.eu4'
        [IO.File]::Move($temp, (Join-Path $folder $name)); $temp = $null
        # Publish the new copy before removing old copies. Keep latest + two previous.
        $versions = @(Get-ChildItem -LiteralPath $folder -Filter '*.eu4' -File | Sort-Object Name -Descending)
        $versions | Select-Object -Skip 3 | ForEach-Object { Remove-Item -LiteralPath $_.FullName -ErrorAction Stop }
        return ([IO.Path]::GetFileName($Source) + ' -> ' + $name)
    } finally {
        if ($null -ne $outputStream) { $outputStream.Dispose() }
        if ($null -ne $inputStream) { $inputStream.Dispose() }
        if ($temp -and [IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
    }
}

function Invoke-BackupScan {
    [CmdletBinding()]
    param([string]$SourceRoot, [string]$BackupRoot, [int]$StableSeconds = 4)
    if (-not [IO.Directory]::Exists($SourceRoot)) { throw "Save folder unavailable: $SourceRoot" }
    foreach ($file in @(Get-ChildItem -LiteralPath $SourceRoot -Filter '*.eu4' -File -ErrorAction Stop)) {
        $path = $file.FullName
        $signature = Get-SaveSignature $file
        if ($script:completed[$path] -eq $signature) { continue }
        if (-not $script:observed.ContainsKey($path) -or $script:observed[$path].Signature -ne $signature) {
            $script:observed[$path] = @{ Signature = $signature; Since = [DateTime]::UtcNow }
            continue
        }
        if (([DateTime]::UtcNow - $script:observed[$path].Since).TotalSeconds -lt $StableSeconds) { continue }
        try {
            $result = Save-Version $path $BackupRoot
            # A subsequent write must be seen on the next scan.
            $script:completed[$path] = $signature
            if ($result) { $result }
        } catch {
            Write-Warning ($file.Name + ': ' + $_.Exception.Message)
        }
    }
}
