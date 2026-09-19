BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' '..' 'powershell' 'OpsPilot.psd1'
    Import-Module $modulePath -Force
}

Describe 'OpsPilot PowerShell module' {
    It 'has a valid module manifest' {
        $manifestPath = Join-Path $PSScriptRoot '..' '..' 'powershell' 'OpsPilot.psd1'
        { Test-ModuleManifest -Path $manifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'creates a system report and writes JSON' {
        $output = Join-Path $TestDrive 'system-report.json'
        $report = Get-OpsSystemReport -OutputPath $output

        $report.hostname | Should -Not -BeNullOrEmpty
        Test-Path $output | Should -BeTrue

        $json = Get-Content $output -Raw | ConvertFrom-Json
        $json.architecture | Should -Not -BeNullOrEmpty
        $json.processors | Should -BeGreaterThan 0
    }

    It 'detects warning, error, critical, and exception log entries' {
        $sample = Join-Path $PSScriptRoot '..' '..' 'examples' 'sample.log'
        $csv = Join-Path $TestDrive 'findings.csv'
        $results = @(Find-OpsLogIssues -Path $sample -OutputPath $csv)

        $results.Count | Should -Be 4
        @($results | Where-Object Severity -eq 'warning').Count | Should -Be 1
        @($results | Where-Object Severity -eq 'critical').Count | Should -Be 1
        @($results | Where-Object Severity -eq 'error').Count | Should -Be 2
        Test-Path $csv | Should -BeTrue
    }

    It 'creates a SHA256 manifest for a directory' {
        $source = Join-Path $TestDrive 'manifest-source'
        New-Item -ItemType Directory -Path $source | Out-Null
        Set-Content -Path (Join-Path $source 'alpha.txt') -Value 'alpha'
        Set-Content -Path (Join-Path $source 'beta.txt') -Value 'beta'

        $manifest = Join-Path $TestDrive 'sha256.txt'
        New-OpsChecksumManifest -Path $source -OutputPath $manifest | Out-Null

        $content = Get-Content $manifest -Raw
        $content | Should -Match 'alpha.txt'
        $content | Should -Match 'beta.txt'
        $content | Should -Match '[a-f0-9]{64}'
    }

    It 'creates a compressed backup' {
        $source = Join-Path $TestDrive 'backup-source'
        $destination = Join-Path $TestDrive 'backups'
        New-Item -ItemType Directory -Path $source | Out-Null
        Set-Content -Path (Join-Path $source 'important.txt') -Value 'portfolio-test'

        $archive = New-OpsBackup -Source $source -Destination $destination

        Test-Path $archive.FullName | Should -BeTrue
        $archive.Extension | Should -Be '.zip'
        $archive.Length | Should -BeGreaterThan 0
    }
}
