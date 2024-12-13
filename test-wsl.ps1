# test-wsl.ps1

$dirs = @(
    "D:\models",
    "D:\models\config",
    "E:\docker\cloudwatch",
    "E:\docker\bedrock\cache"
)

Write-Host "Testing Windows directory creation..." -ForegroundColor Cyan

foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        Write-Host "Creating: $dir" -ForegroundColor Yellow
        New-Item -Path $dir -ItemType Directory -Force
    } else {
        Write-Host "Exists: $dir" -ForegroundColor Green
    }
}

Write-Host "`nTesting WSL access..." -ForegroundColor Cyan

# Simple WSL test command
$wslCommand = 'echo "Testing D drive..." && ls -l /mnt/d/models && echo "Testing E drive..." && ls -l /mnt/e/docker'
Write-Host "Executing WSL command..." -ForegroundColor Yellow
wsl bash -c $wslCommand

Write-Host "`nSetup verification complete" -ForegroundColor Green