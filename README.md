# OpsPilot

OpsPilot is a cross-platform DevOps and systems-automation toolkit implemented in both **PowerShell** and **Bash**.

It is designed as a portfolio project that shows practical scripting across Windows and Linux rather than isolated syntax exercises.

## Skills demonstrated

- PowerShell 7 module development
- Bash scripting
- Windows and Linux automation
- CLI design and argument validation
- system inventory
- HTTP health checks and latency measurement
- log triage
- JSON and CSV reporting
- SHA256 integrity manifests
- compressed backups
- defensive error handling
- Pester
- PSScriptAnalyzer
- ShellCheck
- GitHub Actions
- multi-OS continuous integration

## Commands

| Command | Purpose |
| --- | --- |
| system-report | Capture host and runtime information |
| health | Check HTTP status and response latency |
| log-scan | Find warning, error, critical, and exception entries |
| checksum | Create a SHA256 manifest for a directory |
| backup | Create a timestamped compressed backup |

## PowerShell usage

Import the reusable module:

```powershell
Import-Module ./powershell/OpsPilot.psd1
```

Create a system report:

```powershell
pwsh ./powershell/opspilot.ps1 system-report --output ./reports/system.json
```

Check an HTTP endpoint:

```powershell
pwsh ./powershell/opspilot.ps1 health --url https://example.com --timeout 10
```

Scan a log file:

```powershell
pwsh ./powershell/opspilot.ps1 log-scan --file ./examples/sample.log --output ./reports/findings.csv
```

Generate an integrity manifest:

```powershell
pwsh ./powershell/opspilot.ps1 checksum --path ./examples --output ./reports/sha256.txt
```

Create a backup:

```powershell
pwsh ./powershell/opspilot.ps1 backup --source ./examples --destination ./backups
```

PowerShell creates ZIP archives.

## Bash usage

Show help:

```bash
bash ./bash/opspilot.sh --help
```

Create a system report:

```bash
bash ./bash/opspilot.sh system-report --output ./reports/system.json
```

Check an HTTP endpoint:

```bash
bash ./bash/opspilot.sh health --url https://example.com --timeout 10
```

Scan a log file:

```bash
bash ./bash/opspilot.sh log-scan --file ./examples/sample.log --output ./reports/findings.csv
```

Generate an integrity manifest:

```bash
bash ./bash/opspilot.sh checksum --path ./examples --output ./reports/sha256.txt
```

Create a backup:

```bash
bash ./bash/opspilot.sh backup --source ./examples --destination ./backups
```

Bash creates tar.gz archives.

## Log triage

The included examples/sample.log contains informational, warning, error, critical, and exception events. OpsPilot classifies them into warning, error, and critical findings and can export them to CSV.

## Testing

PowerShell:

```powershell
Invoke-Pester -Path ./tests/powershell
Invoke-ScriptAnalyzer -Path ./powershell -Recurse
Test-ModuleManifest ./powershell/OpsPilot.psd1
```

Bash:

```bash
bash -n bash/opspilot.sh
shellcheck bash/opspilot.sh tests/bash/test_opspilot.sh
bash tests/bash/test_opspilot.sh
```

## CI

GitHub Actions validates the project in three environments:

- Bash on Ubuntu
- PowerShell on Ubuntu
- PowerShell on Windows

This verifies syntax, static analysis, module validity, and automated tests on the platforms the scripts target.

## Repository structure

```text
bash/opspilot.sh
powershell/OpsPilot.psd1
powershell/OpsPilot.psm1
powershell/opspilot.ps1
tests/bash/test_opspilot.sh
tests/powershell/OpsPilot.Tests.ps1
examples/sample.log
config/opspilot.env.example
docs/ARCHITECTURE.md
```

## Portfolio value

OpsPilot is relevant to DevOps, system administration, IT support, network operations, cloud support, technical support engineering, and software engineering roles.

See docs/ARCHITECTURE.md for the implementation and testing approach.