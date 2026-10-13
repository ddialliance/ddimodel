#Requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'install-dependencies.ps1')

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Assert-Failure([scriptblock]$Action, [string]$Message) {
    try { & $Action } catch {
        if ($_.Exception.Message.Contains($Message)) { return }
        throw
    }
    throw "Expected failure containing '$Message'."
}
function Test-InstalledDot {
    $global:LASTEXITCODE = $script:probeExit
    "dot - graphviz version $script:installedVersion (build)"
}
function Test-FallbackDot {
    $global:LASTEXITCODE = 0
    "dot - graphviz version $script:fallbackVersion (build)"
}
function Test-Renderer {
    $global:LASTEXITCODE = $script:renderExit
    $script:renderedSvg
}

$script:probeExit = 0
$script:fallbackCalls = 0
$script:fallbackVersion = '16.1.0'
$install = { $script:fallbackCalls++; 'Test-FallbackDot' }
foreach ($version in @('16.1', '16.1.0', '16.2.0', '16.10.0', '17.0.0')) {
    $script:installedVersion = $version
    Assert-True ((Resolve-Graphviz @('Test-InstalledDot') $install) -eq 'Test-InstalledDot') 'A supported installation should be retained.'
}
Assert-True ($script:fallbackCalls -eq 0) 'Supported versions must not trigger a download.'
foreach ($version in @('2.38', '16.0.9', 'unrecognized')) {
    $script:installedVersion = $version
    Assert-True ((Resolve-Graphviz @('Test-InstalledDot') $install) -eq 'Test-FallbackDot') 'Old or unrecognized versions need a replacement.'
}
$script:installedVersion = '17.0.0'
$script:probeExit = 9
Assert-True ((Resolve-Graphviz @('Test-InstalledDot') $install) -eq 'Test-FallbackDot') 'A failed version probe must not be accepted.'
Assert-True ((Resolve-Graphviz @() $install) -eq 'Test-FallbackDot') 'A missing installation needs a download.'
Assert-True ($script:fallbackCalls -eq 5) 'Unexpected number of fallback installations.'
$script:fallbackVersion = '16.0.0'
Assert-Failure { Resolve-Graphviz @() $install } 'expected 16.1.0 or later'
$script:fallbackVersion = 'unknown'
Assert-Failure { Resolve-Graphviz @() $install } 'Cannot determine Graphviz version'
Assert-Failure { Resolve-Graphviz @() { throw 'Download failed.' } } 'Download failed'

$script:renderExit = 0
$script:renderedSvg = '<svg xmlns="http://www.w3.org/2000/svg" />'
Test-GraphvizRendering 'Test-Renderer'
$script:renderExit = 7
Assert-Failure { Test-GraphvizRendering 'Test-Renderer' } 'SVG rendering failed with exit 7'
$script:renderExit = 0
foreach ($invalid in @('', '<html/>', '<svg/>', 'not XML')) {
    $script:renderedSvg = $invalid
    Assert-Failure { Test-GraphvizRendering 'Test-Renderer' } 'did not produce valid SVG'
}

$checksumFile = [IO.Path]::GetTempFileName()
try {
    [IO.File]::WriteAllText($checksumFile, 'checksum test')
    Assert-GraphvizChecksum $checksumFile (Get-FileHash -LiteralPath $checksumFile -Algorithm SHA256).Hash
    Assert-Failure { Assert-GraphvizChecksum $checksumFile ('0' * 64) } 'SHA-256 verification failed'
    Assert-Failure { Assert-GraphvizChecksum $checksumFile 'invalid' } 'SHA-256 verification failed'
} finally {
    Remove-Item -LiteralPath $checksumFile -Force
}
Write-Host 'Graphviz version selection, checksum, and rendering checks passed.'
