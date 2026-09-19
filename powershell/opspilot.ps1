#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [ValidateSet('system-report', 'health', 'log-scan', 'checksum', 'backup')]
    [string]$Command,

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'OpsPilot.psd1') -Force

function Get-OptionValue {
    param(
        [string[]]$Items,
        [string]$Name,
        [switch]$Required
    )

    $index = [Array]::IndexOf($Items, $Name)
    if ($index -ge 0 -and $index + 1 -lt $Items.Count) {
        return $Items[$index + 1]
    }

    if ($Required) {
        throw "Missing required option: $Name"
    }

    return $null
}

switch ($Command) {
    'system-report' {
        $output = Get-OptionValue -Items $Arguments -Name '--output'
        Get-OpsSystemReport -OutputPath $output | ConvertTo-Json
    }
    'health' {
        $uri = Get-OptionValue -Items $Arguments -Name '--url' -Required
        $timeoutValue = Get-OptionValue -Items $Arguments -Name '--timeout'
        $timeout = if ($timeoutValue) { [int]$timeoutValue } else { 10 }
        Test-OpsEndpoint -Uri $uri -TimeoutSeconds $timeout | ConvertTo-Json
    }
    'log-scan' {
        $path = Get-OptionValue -Items $Arguments -Name '--file' -Required
        $output = Get-OptionValue -Items $Arguments -Name '--output'
        $results = @(Find-OpsLogIssues -Path $path -OutputPath $output)
        [pscustomobject]@{
            file     = $path
            findings = $results.Count
            critical = @($results | Where-Object Severity -eq 'critical').Count
            errors   = @($results | Where-Object Severity -eq 'error').Count
            warnings = @($results | Where-Object Severity -eq 'warning').Count
        } | ConvertTo-Json
    }
    'checksum' {
        $path = Get-OptionValue -Items $Arguments -Name '--path' -Required
        $output = Get-OptionValue -Items $Arguments -Name '--output' -Required
        (New-OpsChecksumManifest -Path $path -OutputPath $output).FullName
    }
    'backup' {
        $source = Get-OptionValue -Items $Arguments -Name '--source' -Required
        $destination = Get-OptionValue -Items $Arguments -Name '--destination' -Required
        (New-OpsBackup -Source $source -Destination $destination).FullName
    }
}
