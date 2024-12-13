# Common PowerShell functions for AWS Local Infrastructure
# This module contains shared functions used across different scripts

function Write-Status {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info" { "Cyan" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    Write-Host "[$timestamp] $Level : $Message" -ForegroundColor $color
}

function Test-Docker {
    Write-Status "Checking Docker status..." "Info"
    try {
        $dockerInfo = docker info 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Status "Docker is not running" "Error"
            return $false
        }
        
        # Check for critical errors but ignore warnings
        $criticalErrors = $dockerInfo | Where-Object { 
            $_ -match "ERROR" -and $_ -notmatch "WARNING" 
        }
        
        if ($criticalErrors) {
            Write-Status "Docker has critical errors: $criticalErrors" "Error"
            return $false
        }
        
        Write-Status "Docker is running properly" "Success"
        return $true
    }
    catch {
        Write-Status "Error checking Docker: $_" "Error"
        return $false
    }
}

function Test-DockerCompose {
    Write-Status "Checking Docker Compose..." "Info"
    try {
        $version = docker-compose version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Docker Compose is available" "Success"
            return $true
        }
        Write-Status "Docker Compose is not available" "Error"
        return $false
    }
    catch {
        Write-Status "Error checking Docker Compose: $_" "Error"
        return $false
    }
}

function Test-WSL {
    Write-Status "Checking WSL status..." "Info"
    try {
        $wslStatus = wsl --status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "WSL is properly configured" "Success"
            return $true
        }
        Write-Status "WSL is not properly configured" "Error"
        return $false
    }
    catch {
        Write-Status "Error checking WSL: $_" "Error"
        return $false
    }
}

function Initialize-ProjectStructure {
    param(
        [string]$ProjectRoot
    )
    
    Write-Status "Initializing project structure..." "Info"
    
    $directories = @(
        "docker/apigateway/src",
        "docker/bedrock/src",
        "docker/cloudwatch/src",
        "docker/dynamodb/src",
        "modules",
        "scripts",
        "storage/models/config",
        "storage/cache",
        "storage/cloudwatch"
    )
    
    foreach ($dir in $directories) {
        $path = Join-Path $ProjectRoot $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Status "Created directory: $dir" "Success"
        } else {
            Write-Status "Verified directory: $dir" "Success"
        }
    }
    
    # Create version file
    $versionFile = Join-Path $ProjectRoot "storage/cache/version.txt"
    if (-not (Test-Path $versionFile)) {
        Set-Content -Path $versionFile -Value "1.0.0" -Force
        Write-Status "Created version file" "Success"
    }
}

Export-ModuleMember -Function Write-Status, Test-Docker, Test-DockerCompose, Test-WSL, Initialize-ProjectStructure