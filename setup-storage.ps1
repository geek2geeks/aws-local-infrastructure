# setup-storage.ps1

$projectRoot = (Get-Location).Path
Write-Host "Creating storage directories in: $projectRoot" -ForegroundColor Cyan

# Create storage structure
$storageStructure = @(
    "$projectRoot\storage\models\config",
    "$projectRoot\storage\cache",
    "$projectRoot\storage\cloudwatch"
)

foreach ($dir in $storageStructure) {
    if (!(Test-Path $dir)) {
        Write-Host "Creating directory: $dir" -ForegroundColor Yellow
        New-Item -Path $dir -ItemType Directory -Force
    } else {
        Write-Host "Directory exists: $dir" -ForegroundColor Green
    }
}

# Convert Windows path to WSL path format
$wslPath = $projectRoot -replace "\\", "/" -replace ":", ""
$wslPath = "/mnt/" + $wslPath.ToLower()

Write-Host "`nSetting WSL permissions..." -ForegroundColor Cyan
wsl chmod -R 755 "$wslPath/storage"

Write-Host "`nVerifying directory structure:" -ForegroundColor Cyan
Write-Host "Windows view:" -ForegroundColor Yellow
Get-ChildItem .\storage -Recurse | Format-Table FullName

Write-Host "`nWSL view:" -ForegroundColor Yellow
wsl ls -la "$wslPath/storage"

Write-Host "`nSetup complete!" -ForegroundColor Green