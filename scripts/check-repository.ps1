# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repositoryRoot

try {
    $forbiddenPatterns = @(
        '^local/(?!README\.md$)',
        '\.(dll|exe|exp|ilk|lib|obj|pdb|unr|u|uax|umx|usa|utx)$',
        '(^|/)(System|System64|Maps|Music|Sounds|Textures)/'
    )

    $candidateFiles = @(git ls-files --cached --others --exclude-standard)
    foreach ($candidateFile in $candidateFiles) {
        foreach ($pattern in $forbiddenPatterns) {
            if ($candidateFile -match $pattern) {
                throw "Forbidden commit candidate: $candidateFile"
            }
        }
    }

    Write-Host "Repository safety check passed ($($candidateFiles.Count) commit candidates)."
}
finally {
    Pop-Location
}