# install-chrome-devtools-mcp.ps1
# Adds chrome-devtools-mcp to Claude Code's settings.json without overwriting existing mcpServers entries.
# Run from PowerShell:
#   ~/.claude/skills/clone-ui/scripts/install-chrome-devtools-mcp.ps1

$ErrorActionPreference = 'Stop'

$settingsPath = Join-Path $env:USERPROFILE '.claude\settings.json'

if (-not (Test-Path $settingsPath)) {
    Write-Host "Creating new settings.json at $settingsPath"
    '{}' | Set-Content -Path $settingsPath -Encoding utf8
}

$json = Get-Content $settingsPath -Raw | ConvertFrom-Json

if (-not $json.PSObject.Properties.Match('mcpServers').Count) {
    $json | Add-Member -MemberType NoteProperty -Name 'mcpServers' -Value (New-Object PSObject)
}

if ($json.mcpServers.PSObject.Properties.Match('chrome-devtools').Count) {
    Write-Host "chrome-devtools MCP server already configured. Skipping."
    exit 0
}

$entry = [PSCustomObject]@{
    command = 'npx'
    args    = @('-y', 'chrome-devtools-mcp@latest')
}

$json.mcpServers | Add-Member -MemberType NoteProperty -Name 'chrome-devtools' -Value $entry

$json | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding utf8

Write-Host "Added chrome-devtools MCP to $settingsPath"
Write-Host "Restart Claude Code to activate."
