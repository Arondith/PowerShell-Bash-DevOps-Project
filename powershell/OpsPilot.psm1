Set-StrictMode -Version Latest

function Get-OpsSystemReport {
    [CmdletBinding()]
    param([string]$OutputPath)

    $report = [ordered]@{
        generatedAtUtc = [DateTime]::UtcNow.ToString("o")
        hostname       = [Environment]::MachineName
        user           = [Environment]::UserName
        os             = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        architecture   = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
        processors     = [Environment]::ProcessorCount
        powershell     = $PSVersionTable.PSVersion.ToString()
        workingDir     = (Get-Location).Path
    }

    $json = $report | ConvertTo-Json
    if ($OutputPath) {
        $parent = Split-Path -Parent $OutputPath
        if ($parent -and -not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Set-Content -Path $OutputPath -Value $json -Encoding utf8
    }

    return $report
}

function Test-OpsEndpoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^https?://')]
        [string]$Uri,
        [ValidateRange(1, 120)]
        [int]$TimeoutSeconds = 10
    )

    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $response = $client.GetAsync($Uri).GetAwaiter().GetResult()
        $stopwatch.Stop()
        [pscustomobject]@{
            uri          = $Uri
            healthy      = [int]$response.StatusCode -ge 200 -and [int]$response.StatusCode -lt 400
            statusCode   = [int]$response.StatusCode
            latencyMs    = $stopwatch.ElapsedMilliseconds
            checkedAtUtc = [DateTime]::UtcNow.ToString("o")
            error        = $null
        }
    }
    catch {
        $stopwatch.Stop()
        [pscustomobject]@{
            uri          = $Uri
            healthy      = $false
            statusCode   = $null
            latencyMs    = $stopwatch.ElapsedMilliseconds
            checkedAtUtc = [DateTime]::UtcNow.ToString("o")
            error        = $_.Exception.Message
        }
    }
    finally {
        $client.Dispose()
    }
}

function Find-OpsLogIssues {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path,
        [string]$OutputPath
    )

    $pattern = '(?i)\b(error|fatal|failed|failure|exception|critical|warn|warning)\b'
    $findings = [System.Collections.Generic.List[object]]::new()
    $lineNumber = 0

    foreach ($line in Get-Content -Path $Path) {
        $lineNumber++
        if ($line -match $pattern) {
            $token = $Matches[1].ToLowerInvariant()
            $severity = if ($token -in @('fatal', 'critical')) {
                'critical'
            }
            elseif ($token -in @('error', 'failed', 'failure', 'exception')) {
                'error'
            }
            else {
                'warning'
            }

            $findings.Add([pscustomobject]@{
                LineNumber = $lineNumber
                Severity   = $severity
                Message    = $line
            })
        }
    }

    if ($OutputPath) {
        $parent = Split-Path -Parent $OutputPath
        if ($parent -and -not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        $findings | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
    }

    return $findings
}

function New-OpsChecksumManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    $root = (Resolve-Path $Path).Path
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $lines = Get-ChildItem -Path $root -File -Recurse |
        Sort-Object FullName |
        ForEach-Object {
            $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            $relative = [IO.Path]::GetRelativePath($root, $_.FullName).Replace('\', '/')
            "$hash  $relative"
        }

    Set-Content -Path $OutputPath -Value $lines -Encoding utf8
    return Get-Item $OutputPath
}

function New-OpsBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Source,
        [Parameter(Mandatory)]
        [string]$Destination
    )

    $sourcePath = (Resolve-Path $Source).Path
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    $sourceName = Split-Path -Leaf $sourcePath
    if ([string]::IsNullOrWhiteSpace($sourceName)) {
        $sourceName = 'backup'
    }

    $timestamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
    $archivePath = Join-Path $Destination "$sourceName-$timestamp.zip"
    Compress-Archive -Path (Join-Path $sourcePath '*') -DestinationPath $archivePath -Force

    return Get-Item $archivePath
}

Export-ModuleMember -Function @(
    'Get-OpsSystemReport',
    'Test-OpsEndpoint',
    'Find-OpsLogIssues',
    'New-OpsChecksumManifest',
    'New-OpsBackup'
)
