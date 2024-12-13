# Import common functions
Import-Module (Join-Path $PSScriptRoot "modules\Common.psm1") -Force

function Start-DockerServices {
    Write-Status "Starting Docker services..." "Info"
    
    # Set required environment variables
    $env:COMPOSE_CONVERT_WINDOWS_PATHS = 1
    
    # Ensure we're in the correct directory
    Push-Location $PSScriptRoot
    
    try {
        # Stop any existing containers
        Write-Status "Stopping existing containers..." "Info"
        $downProcess = Start-Process -FilePath "docker-compose" -ArgumentList "down" -NoNewWindow -Wait -PassThru
        if ($downProcess.ExitCode -ne 0) {
            Write-Status "Warning: Issues stopping existing containers" "Warning"
        }

        # Start services
        Write-Status "Starting new containers..." "Info"
        $upProcess = Start-Process -FilePath "docker-compose" -ArgumentList "up", "-d" -NoNewWindow -Wait -PassThru
        
        if ($upProcess.ExitCode -eq 0) {
            Write-Status "Services started successfully" "Success"
            return $true
        } else {
            Write-Status "Failed to start services" "Error"
            return $false
        }
    }
    catch {
        Write-Status "Error managing Docker services: $_" "Error"
        return $false
    }
    finally {
        Pop-Location
    }
}

# Main execution
if (-not (Test-Docker)) {
    Write-Status "Docker checks failed" "Error"
    exit 1
}

if (-not (Test-DockerCompose)) {
    Write-Status "Docker Compose checks failed" "Error"
    exit 1
}

if (-not (Test-WSL)) {
    Write-Status "WSL checks failed" "Error"
    exit 1
}

Initialize-ProjectStructure -ProjectRoot $PSScriptRoot

if (Start-DockerServices) {
    Write-Status "Infrastructure started successfully" "Success"
    Write-Status "You can check service health at:" "Info"
    Write-Status "  API Gateway: http://localhost:8080/health" "Info"
    Write-Status "  Bedrock: http://localhost:5000/health" "Info"
    Write-Status "  CloudWatch: http://localhost:9090/metrics" "Info"
} else {
    Write-Status "Failed to start infrastructure" "Error"
    exit 1
}