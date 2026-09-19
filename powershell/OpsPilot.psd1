@{
    RootModule        = 'OpsPilot.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '2b9f3c5d-3d71-4bf9-b037-08619f91f8d7'
    Author            = 'Charles Luke Templonuevo'
    CompanyName       = 'Community'
    Copyright         = '(c) 2026 Charles Luke Templonuevo. MIT License.'
    Description       = 'Cross-platform operations automation utilities for PowerShell.'
    PowerShellVersion = '7.2'
    FunctionsToExport = @(
        'Get-OpsSystemReport',
        'Test-OpsEndpoint',
        'Find-OpsLogIssues',
        'New-OpsChecksumManifest',
        'New-OpsBackup'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('DevOps', 'Automation', 'Operations', 'Monitoring', 'Backup')
            ProjectUri = 'https://github.com/Arondith/PowerShell-Bash-DevOps-Project'
            LicenseUri = 'https://opensource.org/license/mit'
        }
    }
}
