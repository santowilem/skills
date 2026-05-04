# save-tool-result.ps1 — clone-ui Phase 2 helper
#
# Slices a JSON object out of a Claude tool-result file and writes it to a
# clone workspace location.
#
# Usage:
#   pwsh ./scripts/save-tool-result.ps1 -src <tool-result-path> -out <workspace-json-path> [-marker '```json']
#
# Scope (kept narrow on purpose):
#   - Reads ONLY the file path passed via -src.
#   - Writes ONLY the file path passed via -out.
#   - Does NOT mutate any user, agent, or IDE configuration.
#   - Does NOT make any network calls.
#
# Why this exists: chrome-devtools-mcp evaluate_script results often overflow
# the LLM context window, so they're persisted as tool-result files on disk.
# Phase 2 needs to slice the JSON payload from those files into typed
# capture artifacts (section-styles.json, nav-states.json, etc). Doing this
# inline with PowerShell subexpressions triggers a permission prompt for
# every save; routing through this single script means one allow-rule
# covers every Phase 2 capture.

param(
    [Parameter(Mandatory=$true)][string]$src,
    [Parameter(Mandatory=$true)][string]$out,
    [string]$marker = '```json'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $src)) {
    Write-Error "Source file not found: $src"
    exit 1
}

$raw = [System.IO.File]::ReadAllText($src)

$markerIdx = $raw.IndexOf($marker)
$start = if ($markerIdx -ge 0) { $raw.IndexOf('{', $markerIdx) } else { $raw.IndexOf('{') }
$end = $raw.LastIndexOf('}')

if ($start -lt 0 -or $end -lt $start) {
    Write-Error "No JSON object found in $src (marker='$marker')"
    exit 1
}

$json = $raw.Substring($start, $end - $start + 1)

$outDir = Split-Path -Parent $out
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

[System.IO.File]::WriteAllText($out, $json)

$size = (Get-Item -LiteralPath $out).Length
$name = [System.IO.Path]::GetFileName($out)
Write-Output "${name}: ${size} bytes"
