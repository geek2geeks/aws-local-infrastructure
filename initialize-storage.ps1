# Import common functions
Import-Module (Join-Path $PSScriptRoot "modules\Common.psm1") -Force

# Initialize storage directories with proper permissions
# Run this before starting services

Write-Status "Initializing storage directories..." "Info"

$storageBase = Join-Path $PSScriptRoot "storage"
$directories = @(
    "models",
    "models\config",
    "cache",
    "cloudwatch"
)

# Create base storage directory if it doesn't exist
if (-not (Test-Path $storageBase)) {
    New-Item -ItemType Directory -Path $storageBase -Force | Out-Null
    Write-Status "Created base storage directory" "Success"
}

# Create and verify each required directory
foreach ($dir in $directories) {
    $fullPath = Join-Path $storageBase $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Status "Created directory: $dir" "Success"
    } else {
        Write-Status "Verified directory: $dir" "Success"
    }
}

# Create version marker file
$versionFile = Join-Path $storageBase "cache\version.txt"
if (-not (Test-Path $versionFile)) {
    Set-Content -Path $versionFile -Value "1.0.0" -Force
    Write-Status "Created version file" "Success"
}

Write-Status "Storage initialization complete" "Success"