param(
    [string] $RuntimeRoot,

    [string] $OriginalGameRoot,

    [string] $PatchRoot,

    [string] $OutputRoot
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
if (-not $RuntimeRoot) {
    $RuntimeRoot = Join-Path $repositoryRoot 'local\game'
}
if (-not $PatchRoot) {
    $PatchRoot = Join-Path $repositoryRoot 'local\package\offline-installer\patch'
}

$runtimePath = [IO.Path]::GetFullPath($RuntimeRoot).TrimEnd('\')
$patchPath = [IO.Path]::GetFullPath($PatchRoot).TrimEnd('\')
$developmentMarker = Join-Path $runtimePath '.unreal-revived-development.json'
if (-not $OriginalGameRoot -and (Test-Path -LiteralPath $developmentMarker -PathType Leaf)) {
    $marker = Get-Content -LiteralPath $developmentMarker -Raw | ConvertFrom-Json
    $OriginalGameRoot = $marker.originalGameRoot
}
if (-not $OriginalGameRoot) {
    throw 'OriginalGameRoot is required when the runtime marker does not record it.'
}
$originalPath = [IO.Path]::GetFullPath($OriginalGameRoot).TrimEnd('\')

foreach ($requiredFile in @(
    (Join-Path $runtimePath 'System64\Unreal.exe'),
    (Join-Path $runtimePath 'System64\Default.ini'),
    (Join-Path $originalPath 'System\Unreal.exe'),
    (Join-Path $patchPath 'System64\Unreal.exe')
)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Content audit input is incomplete: $requiredFile"
    }
}

if (-not $OutputRoot) {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $OutputRoot = Join-Path $repositoryRoot "local\logs\content-audit\$timestamp"
}
$outputPath = [IO.Path]::GetFullPath($OutputRoot).TrimEnd('\')
foreach ($inputPath in @($runtimePath, $originalPath, $patchPath)) {
    if ($outputPath -eq $inputPath -or $outputPath.StartsWith("$inputPath\", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'OutputRoot must not be an audit input or a directory inside one.'
    }
}

function Get-RelativeAuditPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Root,

        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $rootUri = [Uri]::new(([IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'))
    $pathUri = [Uri]::new([IO.Path]::GetFullPath($Path))
    return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('/', '\')
}

function Get-FileMap {
    param([Parameter(Mandatory = $true)][string] $Root)

    $map = @{}
    foreach ($file in Get-ChildItem -LiteralPath $Root -File -Recurse -Force) {
        $relativePath = Get-RelativeAuditPath -Root $Root -Path $file.FullName
        $map[$relativePath.ToLowerInvariant()] = $file
    }
    return $map
}

function Get-ContentClassification {
    param([Parameter(Mandatory = $true)][string] $RelativePath)

    $path = $RelativePath.Replace('/', '\')
    $fileName = Split-Path $path -Leaf
    $extension = [IO.Path]::GetExtension($fileName).ToLowerInvariant()

    if ($path -match '^(Maps|Meshes|Music|Sounds|Textures)\\') {
        return [ordered]@{ category = 'required'; feature = 'game-content'; rationale = 'Referenced by the engine package search paths and required by shipped maps.' }
    }
    if ($path -match '^SystemLocalized\\') {
        return [ordered]@{ category = 'feature-required'; feature = 'localization'; rationale = 'All bundled languages are in the supported product boundary.' }
    }
    if ($path -match '^WebServer\\' -or $fileName -match '^(IpDrv|IpServer|UBrowser|UWebAdmin|USQLite)\.') {
        return [ordered]@{ category = 'feature-required'; feature = 'multiplayer-server'; rationale = 'Multiplayer client, dedicated server, and web administration are supported.' }
    }
    if ($fileName -match '^XOpenGLDrv\.' -or $fileName -ieq 'OpenGLDrv.dll') {
        return [ordered]@{ category = 'feature-required'; feature = 'renderer-recovery'; rationale = 'XOpenGL recovery remains supported when D3D12 cannot start.' }
    }
    if ($fileName -match '^D3D12Drv\.' -or $fileName -ieq 'ModernMenu.u') {
        return [ordered]@{ category = 'required'; feature = 'unreal-revived'; rationale = 'Generated Unreal Revived renderer or menu payload.' }
    }
    if ($path -match '^System64\\' -and $fileName -match '^(Unreal|Core|Engine|Render|WinDrv)\.(exe|dll)$') {
        return [ordered]@{ category = 'required'; feature = 'x64-host'; rationale = 'Pinned and validated OldUnreal x64 host module.' }
    }
    if ($path -match '^System\\' -and $extension -in @('.u', '.int')) {
        return [ordered]@{ category = 'required'; feature = 'engine-packages'; rationale = 'The x64 host loads script and localization packages from System.' }
    }
    if ($path -in @('Help\Logo.bmp', 'Help\SetupLogo.bmp')) {
        return [ordered]@{ category = 'required'; feature = 'x64-host'; rationale = 'The x64 executable loads this startup or first-time configuration bitmap.' }
    }
    if ($path -match '^(Help|Manual|directx9c|Compress)\\') {
        return [ordered]@{ category = 'candidate'; feature = 'distribution-residue'; rationale = 'Documentation or historical installer material; not runtime evidence.' }
    }
    if ($path -match '^System(64)?\\editorres\\' -or $fileName -in @('EdSplash.bmp', 'DefaultUnrealED.ini', 'ConfigLogo.bmp', 'Manifest.ini')) {
        return [ordered]@{ category = 'candidate'; feature = 'editor-or-setup-assets'; rationale = 'Editor or historical setup asset outside the installed-product runtime boundary.' }
    }
    if ($fileName -match '^(UnrealEd|UCC)(\.exe)?$' -or $fileName -match '^(Editor|ScriptedAIEd)\.' -or $path -match '^editorres\\') {
        return [ordered]@{ category = 'candidate'; feature = 'developer-tools'; rationale = 'Editor and compiler tooling are outside the installed-product boundary.' }
    }
    if ($path -match '^System\\' -and $extension -in @('.exe', '.dll')) {
        return [ordered]@{ category = 'candidate'; feature = 'legacy-32-bit-host'; rationale = 'Native 32-bit host binary cannot load into the supported x64 process; validate launch-tool dependencies.' }
    }
    if ($fileName -match '^(D3DDrv|D3D9Drv|SoftDrv|GlideDrv|MeTaLDrv|ICBINDx11Drv)\.' -or $fileName -ieq 'glide2x.dll') {
        return [ordered]@{ category = 'candidate'; feature = 'legacy-renderer'; rationale = 'Renderer is outside the D3D12 plus XOpenGL support boundary.' }
    }
    if ($path -match '^System(64)?\\ICBINDx11Drv\\') {
        return [ordered]@{ category = 'candidate'; feature = 'legacy-renderer'; rationale = 'Companion assets for a renderer outside the D3D12 plus XOpenGL support boundary.' }
    }
    if ($extension -in @('.log', '.tmp') -or $fileName -in @('Unreal.ini', 'User.ini', 'SHALinkerCache.ini', 'installscript.vdf', 'gamespyinstaller220std.exe')) {
        return [ordered]@{ category = 'candidate'; feature = 'copied-state-or-installer'; rationale = 'Copied user state, logs, cache, or historical installer residue.' }
    }

    return [ordered]@{ category = 'unknown'; feature = 'unclassified'; rationale = 'No removal claim is made without stronger package or runtime evidence.' }
}

function Get-ConfiguredSearchPatterns {
    param([Parameter(Mandatory = $true)][string] $DefaultIni)

    $patterns = foreach ($line in Get-Content -LiteralPath $DefaultIni) {
        if ($line -notmatch '^(LangPaths|Paths)=(.+)$') {
            continue
        }

        $setting = $Matches[1]
        $configuredValue = $Matches[2].Trim()
        $configuredPath = $configuredValue.Replace('/', '\').Replace('<lang>', '*')
        if ($configuredPath.StartsWith('..\')) {
            $relativePattern = $configuredPath.Substring(3)
        }
        else {
            $relativePattern = "System64\$configuredPath"
        }
        [pscustomobject]@{
            configured = $configuredValue
            pattern = $relativePattern
            matcher = [WildcardPattern]::new($relativePattern, [Management.Automation.WildcardOptions]::IgnoreCase)
            priority = if ($setting -eq 'Paths') { 0 } else { 1 }
        }
    }
    return @($patterns | Sort-Object priority)
}

Write-Host 'Indexing original game and pinned patch inputs'
$originalFiles = Get-FileMap -Root $originalPath
$patchFiles = Get-FileMap -Root $patchPath
$runtimeFiles = @(Get-ChildItem -LiteralPath $runtimePath -File -Recurse -Force)
$runtimeFileCount = $runtimeFiles.Count
$runtimeByteCount = [long](($runtimeFiles | Measure-Object -Property Length -Sum).Sum)
$configuredSearchPatterns = Get-ConfiguredSearchPatterns -DefaultIni (Join-Path $runtimePath 'System64\Default.ini')

Write-Host "Hashing and classifying $runtimeFileCount effective runtime files"
$records = foreach ($file in $runtimeFiles) {
    $relativePath = Get-RelativeAuditPath -Root $runtimePath -Path $file.FullName
    $key = $relativePath.ToLowerInvariant()
    $originalFile = $originalFiles[$key]
    $patchFile = $patchFiles[$key]
    $origin = if ($patchFile -and $originalFile) { 'patch-replaced-or-confirmed' } elseif ($patchFile) { 'patch-added' } elseif ($originalFile) { 'original-only' } else { 'generated-or-unattributed' }
    $classification = Get-ContentClassification -RelativePath $relativePath
    $matchingSearchPattern = $configuredSearchPatterns | Where-Object { $_.matcher.IsMatch($relativePath) } | Select-Object -First 1

    [pscustomobject][ordered]@{
        path = $relativePath
        size = [long]$file.Length
        sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        origin = $origin
        originalSize = if ($originalFile) { [long]$originalFile.Length } else { $null }
        patchSize = if ($patchFile) { [long]$patchFile.Length } else { $null }
        category = $classification.category
        feature = $classification.feature
        configuredSearchPath = if ($matchingSearchPattern) { $matchingSearchPattern.configured } else { $null }
        rationale = $classification.rationale
    }
}

$recordCount = @($records).Count
$recordBytes = [long](($records | Measure-Object -Property size -Sum).Sum)
if ($recordCount -ne $runtimeFileCount -or $recordBytes -ne $runtimeByteCount) {
    throw "Inventory reconciliation failed: filesystem=$runtimeFileCount/$runtimeByteCount report=$recordCount/$recordBytes"
}

New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
$records | Sort-Object path | Export-Csv -LiteralPath (Join-Path $outputPath 'files.csv') -NoTypeInformation -Encoding UTF8
$summary = @($records | Group-Object category | ForEach-Object {
    [pscustomobject][ordered]@{
        category = $_.Name
        files = $_.Count
        bytes = [long](($_.Group | Measure-Object -Property size -Sum).Sum)
    }
} | Sort-Object category)
$report = [ordered]@{
    schema = 1
    product = 'Unreal Revived'
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    inputs = [ordered]@{ runtimeRoot = $runtimePath; originalGameRoot = $originalPath; patchRoot = $patchPath }
    totals = [ordered]@{ files = $recordCount; bytes = $recordBytes }
    categories = $summary
    files = @($records | Sort-Object path)
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $outputPath 'inventory.json') -Encoding UTF8

$markdown = @(
    '# Unreal Revived content audit'
    ''
    "Generated: $($report.generatedAtUtc)"
    ''
    'This report is an evaluation only. Candidate files are not approved for removal, and unknown files default to retained.'
    ''
    '## Totals'
    ''
    "- Files: $recordCount"
    "- Bytes: $recordBytes"
    ''
    '## Classification summary'
    ''
    '| Category | Files | Bytes |'
    '| --- | ---: | ---: |'
)
foreach ($group in $summary) {
    $markdown += "| $($group.category) | $($group.files) | $($group.bytes) |"
}
$markdown += @(
    ''
    'Review `files.csv` or `inventory.json` for per-file provenance, hashes, classification, and rationale.'
)
$markdown | Set-Content -LiteralPath (Join-Path $outputPath 'report.md') -Encoding UTF8

Write-Host "Content audit complete: $outputPath"
$summary | Format-Table -AutoSize