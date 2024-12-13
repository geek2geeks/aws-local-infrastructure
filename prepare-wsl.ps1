# Run as Administrator
param(
    [switch]$Force
)

Write-Host "Starting WSL environment preparation..." -ForegroundColor Green

# Function to check if running as Administrator
function Test-Administrator {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to check Docker Desktop status
function Test-DockerRunning {
    $dockerCli = "${env:ProgramFiles}\Docker\Docker\resources\bin\docker.exe"
    if (Test-Path $dockerCli) {
        try {
            $null = & $dockerCli ps 2>&1
            return $true
        } catch {
            return $false
        }
    }
    return $false
}

# Function to stop Docker processes with timeout
function Stop-DockerProcesses {
    param([int]$timeoutSeconds = 30)
    
    Write-Host "Stopping Docker processes..." -ForegroundColor Yellow
    $stopTime = [DateTime]::Now.AddSeconds($timeoutSeconds)
    
    # Stop Docker Desktop first
    $dockerDesktop = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
    if ($dockerDesktop) {
        $dockerDesktop | Stop-Process -Force
        Write-Host "Sent stop signal to Docker Desktop" -ForegroundColor Cyan
    }
    
    # Stop all other Docker-related processes
    while ([DateTime]::Now -lt $stopTime) {
        $dockerProcesses = Get-Process | Where-Object {$_.Name -like "*docker*"}
        if (-not $dockerProcesses) {
            Write-Host "All Docker processes stopped successfully" -ForegroundColor Green
            return $true
        }
        
        $dockerProcesses | ForEach-Object {
            try {
                $_ | Stop-Process -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Host "Failed to stop process: $($_.Name)" -ForegroundColor Yellow
            }
        }
        Start-Sleep -Seconds 2
    }
    
    Write-Host "Warning: Timed out waiting for Docker processes to stop" -ForegroundColor Yellow
    return $false
}

# Check for Administrator privileges
if (-not (Test-Administrator)) {
    Write-Host "This script needs to be run as Administrator. Please restart with elevated privileges." -ForegroundColor Red
    exit 1
}

# Check Docker Desktop Installation and Services
Write-Host "Checking Docker installation..." -ForegroundColor Yellow
$dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
if (!(Test-Path $dockerPath)) {
    Write-Host "Docker Desktop not found. Please install Docker Desktop from https://www.docker.com/products/docker-desktop" -ForegroundColor Red
    exit 1
}

# Stop WSL and Docker
Write-Host "Stopping WSL and Docker services..." -ForegroundColor Yellow
wsl --shutdown
Stop-DockerProcesses -timeoutSeconds 30

# Stop Docker services explicitly
$services = @('com.docker.service', 'docker')
foreach ($service in $services) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq 'Running') {
        Write-Host "Stopping service: $service" -ForegroundColor Cyan
        Stop-Service -Name $service -Force
        Start-Sleep -Seconds 2
    }
}

# Create Windows directories if they don't exist
Write-Host "Creating required directories in Windows..." -ForegroundColor Yellow
$directories = @(
    "D:\models",
    "D:\models\config",
    "E:\docker\cloudwatch",
    "E:\docker\bedrock\cache"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        Write-Host "Creating directory: $dir" -ForegroundColor Cyan
        New-Item -Path $dir -ItemType Directory -Force
    } else {
        Write-Host "Directory already exists: $dir" -ForegroundColor Cyan
    }
}

# Set up WSL mount points and permissions with better error handling
Write-Host "Setting up WSL mount points and permissions..." -ForegroundColor Yellow
$wslSetupScript = @'
#!/bin/bash
set -e
echo "Creating WSL directories..."
# Create base mount points if they don't exist
sudo mkdir -p /mnt/d /mnt/e

# Create required directories
sudo mkdir -p /mnt/d/models
sudo mkdir -p /mnt/d/models/config
sudo mkdir -p /mnt/e/docker/cloudwatch
sudo mkdir -p /mnt/e/docker/bedrock/cache

# Set permissions
echo "Setting permissions..."
sudo chown -R $USER:$USER /mnt/d/models
sudo chown -R $USER:$USER /mnt/e/docker
sudo chmod -R 755 /mnt/d/models
sudo chmod -R 755 /mnt/e/docker

# Verify directories exist
if [ -d "/mnt/d/models" ] && [ -d "/mnt/e/docker" ]; then
    echo "Directories created and configured successfully"
else
    echo "Error: Failed to verify directory creation"
    exit 1
fi
'@

# Create temporary script file with Unix line endings
$wslSetupPath = Join-Path $env:TEMP "wsl-setup.sh"
$wslSetupScript | Out-File -FilePath $wslSetupPath -Encoding ASCII -NoNewline
$wslSetupScript = $wslSetupScript.Replace("`r`n", "`n")
[System.IO.File]::WriteAllText($wslSetupPath, $wslSetupScript)

# Convert Windows path to WSL path
$wslPath = "/mnt/" + $wslSetupPath.ToLower().Replace(":", "").Replace("\", "/")

# Execute setup script in WSL
Write-Host "Executing WSL setup script..." -ForegroundColor Yellow
wsl bash -c "chmod +x $wslPath && $wslPath"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error setting up WSL directories and permissions" -ForegroundColor Red
    exit 1
}

# Cleanup
Remove-Item $wslSetupPath -ErrorAction SilentlyContinue

# Configure WSL
Write-Host "Configuring WSL..." -ForegroundColor Yellow
$wslConfigPath = "$env:USERPROFILE\.wslconfig"
$wslConfig = @"
[wsl2]
memory=16GB
processors=12
swap=8GB
localhostForwarding=true
kernelCommandLine=nvidia-drm.modeset=1
nestedVirtualization=true

[experimental]
autoMemoryReclaim=gradual
sparseVHD=true
"@

if (!(Test-Path $wslConfigPath) -or $Force) {
    Set-Content -Path $wslConfigPath -Value $wslConfig -Force
    Write-Host "WSL configuration file created at: $wslConfigPath" -ForegroundColor Green
} else {
    Write-Host "WSL configuration file already exists. Use -Force to overwrite." -ForegroundColor Yellow
}

# Start Docker Desktop
Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
Start-Process "$dockerPath" -WindowStyle Hidden
Start-Sleep -Seconds 30  # Give Docker Desktop time to initialize

# Final status check
Write-Host "`nVerifying setup..." -ForegroundColor Yellow
$checks = @{
    "D:\models exists" = Test-Path "D:\models"
    "E:\docker exists" = Test-Path "E:\docker"
    "WSL D: mount exists" = wsl test -d /mnt/d/models
    "WSL E: mount exists" = wsl test -d /mnt/e/docker
    "Docker Desktop installed" = Test-Path $dockerPath
    "WSL config exists" = Test-Path $wslConfigPath
    "Docker running" = Test-DockerRunning
}

foreach ($check in $checks.GetEnumerator()) {
    if ($check.Value) {
        Write-Host "[OK] $($check.Name)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $($check.Name)" -ForegroundColor Red
    }
}

Write-Host "`nEnvironment preparation completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. If Docker Desktop isn't running, start it manually" -ForegroundColor White
Write-Host "2. Wait for Docker Desktop to fully initialize" -ForegroundColor White
Write-Host "3. Run 'docker-compose up --build' in your project directory" -ForegroundColor White