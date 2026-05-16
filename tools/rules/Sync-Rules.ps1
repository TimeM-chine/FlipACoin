param(
    [ValidateSet("Sync", "Check", "InitCentral")]
    [string]$Mode = "Check",

    [string]$ProjectRoot = "",
    [string]$ConfigPath = "",
    [string]$CentralRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-FullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Read-TextFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.File]::ReadAllText($Path)
}

function Copy-ManagedFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "Missing source file: $SourcePath"
    }

    $targetDirectory = Split-Path -Parent $TargetPath
    if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    }

    Copy-Item -LiteralPath $SourcePath -Destination $TargetPath -Force
}

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Resolve-FullPath $PSScriptRoot "../.."
} else {
    $ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
}

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $ProjectRoot ".rules-sync.json"
} else {
    $ConfigPath = Resolve-FullPath $ProjectRoot $ConfigPath
}

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "Missing rules sync config: $ConfigPath"
}

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($CentralRoot)) {
    $CentralRoot = Resolve-FullPath $ProjectRoot $config.centralRoot
} else {
    $CentralRoot = Resolve-FullPath $ProjectRoot $CentralRoot
}

$differences = New-Object System.Collections.Generic.List[string]

foreach ($file in $config.files) {
    $centralPath = Resolve-FullPath $CentralRoot $file.source
    $projectPath = Resolve-FullPath $ProjectRoot $file.target

    if ($Mode -eq "InitCentral") {
        Copy-ManagedFile -SourcePath $projectPath -TargetPath $centralPath
        Write-Host "Initialized $($file.source)"
        continue
    }

    if ($Mode -eq "Sync") {
        Copy-ManagedFile -SourcePath $centralPath -TargetPath $projectPath
        Write-Host "Synced $($file.target)"
        continue
    }

    if (-not (Test-Path -LiteralPath $centralPath -PathType Leaf)) {
        $differences.Add("Missing central file: $($file.source)")
        continue
    }

    if (-not (Test-Path -LiteralPath $projectPath -PathType Leaf)) {
        $differences.Add("Missing project file: $($file.target)")
        continue
    }

    if ((Read-TextFile $centralPath) -ne (Read-TextFile $projectPath)) {
        $differences.Add("Out of sync: $($file.target)")
    }
}

if ($Mode -eq "Check") {
    if ($differences.Count -gt 0) {
        $differences | ForEach-Object { Write-Host $_ }
        exit 1
    }

    Write-Host "Rules are in sync with $CentralRoot"
}
