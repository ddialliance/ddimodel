#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$ToolDirectory,
    [string]$DotPathFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:MinimumGraphvizVersion = [version]'16.1.0'

function Get-GraphvizVersion([string]$Executable) {
    $banner = (& $Executable -V 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $banner -notmatch '\bgraphviz\s+version\s+(\d+)\.(\d+)(?:\.(\d+))?(?=\s|\(|$)') {
        throw "Cannot determine Graphviz version from '$Executable': $banner"
    }
    $patch = if ($Matches[3]) { $Matches[3] } else { '0' }
    return [version]"$($Matches[1]).$($Matches[2]).$patch"
}

function Assert-GraphvizChecksum([string]$Path, [string]$Expected) {
    if ($Expected -notmatch '^[0-9a-fA-F]{64}$' -or (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Expected) {
        throw "Graphviz SHA-256 verification failed for '$Path'."
    }
}

function Install-PortableGraphviz([string]$Directory) {
    # Official portable baseline and checksum also used by COGS conformance CI.
    $url = 'https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/16.1.0/windows_10_cmake_Release_Graphviz-16.1.0-win64.zip'
    $sha256 = '733e49626c492242eb8dca30ea627b6ead20710e207998c7933b4909d92d6abc'
    [void][IO.Directory]::CreateDirectory($Directory)
    $archive = Join-Path $Directory 'graphviz-16.1.0-win64.zip'
    Write-Host 'Installing portable Graphviz 16.1.0.'
    Invoke-WebRequest -Uri $url -OutFile $archive
    Assert-GraphvizChecksum $archive $sha256
    $destination = Join-Path $Directory 'portable'
    Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
    $executables = @(Get-ChildItem -LiteralPath $destination -Filter dot.exe -File -Recurse)
    if ($executables.Count -ne 1) { throw 'The Graphviz archive must contain exactly one dot.exe.' }
    return $executables[0].FullName
}

function Resolve-Graphviz([string[]]$Candidates, [scriptblock]$Install) {
    foreach ($candidate in ($Candidates | Select-Object -Unique)) {
        try {
            $version = Get-GraphvizVersion $candidate
        } catch {
            Write-Host "Cannot use Graphviz '$candidate': $($_.Exception.Message)"
            continue
        }
        if ($version -ge $script:MinimumGraphvizVersion) { return $candidate }
        Write-Host "Graphviz $version is below $script:MinimumGraphvizVersion; checking another installation."
    }
    $replacement = & $Install
    $version = Get-GraphvizVersion $replacement
    if ($version -lt $script:MinimumGraphvizVersion) {
        throw "Installed Graphviz $version; expected $script:MinimumGraphvizVersion or later."
    }
    return $replacement
}

function Test-GraphvizRendering([string]$Executable) {
    $svg = ('digraph { node [shape=box]; a [label=<<TABLE><TR><TD>DDI</TD></TR></TABLE>>]; a -> b [label="0..n"]; }' |
        & $Executable -Tsvg | Out-String)
    if ($LASTEXITCODE -ne 0) { throw "Graphviz SVG rendering failed with exit $LASTEXITCODE." }
    try { $document = [xml]$svg } catch { throw 'Graphviz did not produce valid SVG.' }
    if ($null -eq $document.DocumentElement -or $document.DocumentElement.LocalName -ne 'svg' -or
        $document.DocumentElement.NamespaceURI -ne 'http://www.w3.org/2000/svg') {
        throw 'Graphviz did not produce valid SVG.'
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $IsWindows) { throw 'This dependency installer supports Windows builds.' }
    if (-not $ToolDirectory) {
        $temporaryRoot = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [IO.Path]::GetTempPath() }
        $ToolDirectory = Join-Path $temporaryRoot 'ddi-lifecycle-tools/graphviz-16.1.0'
    }
    $ToolDirectory = [IO.Path]::GetFullPath($ToolDirectory)
    $candidates = @()
    if ($env:COGS_DOT) {
        $candidates += (Get-Command $env:COGS_DOT -CommandType Application -ErrorAction Stop).Source
    }
    $onPath = Get-Command dot -CommandType Application -ErrorAction SilentlyContinue
    if ($onPath) { $candidates += $onPath.Source }
    $portable = Join-Path $ToolDirectory 'portable'
    if (Test-Path -LiteralPath $portable -PathType Container) {
        $candidates += @(Get-ChildItem -LiteralPath $portable -Filter dot.exe -File -Recurse | ForEach-Object FullName)
    }
    $dot = Resolve-Graphviz $candidates { Install-PortableGraphviz $ToolDirectory }
    Test-GraphvizRendering $dot
    Write-Host "Selected Graphviz $(Get-GraphvizVersion $dot): $dot"
    $env:COGS_DOT = $dot
    if ($DotPathFile) {
        # Use the console encoding so cmd.exe can read the selected path.
        [IO.File]::WriteAllText($DotPathFile, $dot, [Console]::OutputEncoding)
    }
    $dot
}
