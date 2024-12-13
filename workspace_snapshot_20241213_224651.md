
### Directory: .\.git
*.git directory present but contents excluded*

### Directory: .\node_modules
*node_modules directory present but contents excluded*

### File: .dockerignore
```
**/__pycache__
**/*.pyc
.git
.env
*.log
```

### File: .env
```
# .env
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
```

### File: .gitignore
```
# Dependencies
node_modules/
__pycache__/

# Environment
.env
.env.local

# Build outputs
dist/
build/

# Logs
*.log
logs/

# Docker
docker-compose.override.yml

# IDE
.vscode/
.idea/

# System
.DS_Store
Thumbs.db

```

### File: .wslignore
```
**/node_modules
**/.git
**/dist
**/build
D:/models/*
E:/docker/*
```

### File: docker-compose.yml
```yaml
version: '3.8'

services:
  apigateway:
    build: 
      context: ./docker/apigateway
      dockerfile: Dockerfile
    ports:
      - '8080:8080'
    networks:
      - frontend
      - backend

  bedrock:
    build: 
      context: ./docker/bedrock
      dockerfile: Dockerfile
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - TRANSFORMERS_CACHE=/root/.cache/huggingface
      - CUDA_VISIBLE_DEVICES=0
      - PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
      - MODEL_BASE_PATH=/models
      - MODEL_CONFIG_PATH=/models/config
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    ports:
      - '5000:5000'
    networks:
      - backend
    volumes:
      - type: bind
        source: ./storage/models
        target: /models
      - type: bind
        source: ./storage/cache
        target: /root/.cache/huggingface
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  cloudwatch:
    build:
      context: ./docker/cloudwatch
      dockerfile: Dockerfile
    volumes:
      - type: bind
        source: ./storage/cloudwatch
        target: /var/lib/cloudwatch
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
```

### File: workspace.py
*workspace.py present but contents excluded*

### File: workspace_snapshot_20241213_224651.md
```markdown

```

### File: docker\apigateway\Dockerfile
```
FROM node:18-alpine

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY src/ ./src/

# Expose API Gateway port
EXPOSE 8080

# Start the service
CMD ["node", "src/server.js"]
```

### File: docker\apigateway\package-lock.json
*package-lock.json present but contents excluded*

### File: docker\apigateway\package.json
```json
{
    "name": "aws-local-apigateway",
    "version": "1.0.0",
    "description": "Local implementation of AWS API Gateway",
    "main": "src/server.js",
    "scripts": {
        "start": "node src/server.js",
        "dev": "nodemon src/server.js",
        "test": "jest"
    },
    "dependencies": {
        "cors": "^2.8.5",
        "express": "^4.21.2",
        "morgan": "^1.10.0",
        "uuid": "^9.0.1"
    },
    "devDependencies": {
        "jest": "^29.7.0",
        "nodemon": "^3.0.2"
    },
    "keywords": [],
    "author": "",
    "license": "ISC"
}

```

### File: docker\apigateway\src\server.js
```javascript
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { v4: uuidv4 } = require('uuid');

const app = express();
const port = process.env.PORT || 8080;

// Basic request tracking for CloudWatch metrics
const requestMetrics = {
  totalRequests: 0,
  requestsPerEndpoint: {},
  errors: 0
};

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Add request tracking middleware
app.use((req, res, next) => {
  const requestId = uuidv4();
  req.requestId = requestId;
  
  // Track request metrics
  requestMetrics.totalRequests++;
  requestMetrics.requestsPerEndpoint[req.path] = 
    (requestMetrics.requestsPerEndpoint[req.path] || 0) + 1;
  
  // Add CloudWatch-style headers
  res.setHeader('x-amzn-RequestId', requestId);
  
  // Track response metrics
  res.on('finish', () => {
    if (res.statusCode >= 400) {
      requestMetrics.errors++;
    }
  });
  
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Metrics endpoint for CloudWatch
app.get('/metrics', (req, res) => {
  res.json({
    metrics: requestMetrics,
    timestamp: new Date().toISOString()
  });
});

// API routes will be added here in subsequent sprints
app.get('/v1/services', (req, res) => {
  res.json({
    services: [
      {
        name: 'apigateway',
        status: 'active',
        endpoints: ['/health', '/metrics', '/v1/services']
      }
    ]
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(`Error [${req.requestId}]:`, err);
  requestMetrics.errors++;
  
  res.status(500).json({
    error: 'Internal Server Error',
    requestId: req.requestId,
    message: err.message
  });
});

app.listen(port, () => {
  console.log(`API Gateway listening on port ${port}`);
});
```

### File: docker\bedrock\Dockerfile
```
# docker/bedrock/Dockerfile
FROM pytorch/pytorch:2.1.1-cuda12.1-cudnn8-runtime

WORKDIR /usr/src/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Create model directory
RUN mkdir -p /models

# Copy source code
COPY src/ ./src/

EXPOSE 5000

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    CUDA_VISIBLE_DEVICES=0 \
    TRANSFORMERS_CACHE=/root/.cache/huggingface \
    PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512 \
    MODEL_BASE_PATH=/models \
    MODEL_CONFIG_PATH=/models/config

CMD ["python3", "src/server.py"]
```

### File: docker\bedrock\requirements.txt
```
# docker/bedrock/requirements.txt
flask==3.0.0
torch==2.1.1
transformers==4.35.2
accelerate==0.25.0
bitsandbytes==0.41.1
opencv-python-headless==4.8.1.78
pillow==10.1.0
numpy==1.24.3
sentencepiece==0.1.99
requests==2.31.0
pynvml==11.5.0
psutil==5.9.6
```

### File: docker\bedrock\src\nvml_monitor.py
```python
import torch
from pynvml import *
import psutil

class GPUMonitor:
    def __init__(self):
        self.has_gpu = torch.cuda.is_available()
        if self.has_gpu:
            nvmlInit()
            self.handle = nvmlDeviceGetHandleByIndex(0)

    def get_gpu_info(self):
        if not self.has_gpu:
            return {'gpu_available': False}

        try:
            info = nvmlDeviceGetMemoryInfo(self.handle)
            temp = nvmlDeviceGetTemperature(self.handle, NVML_TEMPERATURE_GPU)
            util = nvmlDeviceGetUtilizationRates(self.handle)

            return {
                'gpu_available': True,
                'device_name': torch.cuda.get_device_name(0),
                'memory': {
                    'total': f"{info.total/1e9:.2f}GB",
                    'used': f"{info.used/1e9:.2f}GB",
                    'free': f"{info.free/1e9:.2f}GB"
                },
                'temperature': f"{temp}°C",
                'utilization': {
                    'gpu': f"{util.gpu}%",
                    'memory': f"{util.memory}%"
                },
                'system': {
                    'cpu_percent': psutil.cpu_percent(),
                    'memory_percent': psutil.virtual_memory().percent
                }
            }
        except Exception as e:
            return {
                'gpu_available': True,
                'error': str(e)
            }

    def __del__(self):
        if self.has_gpu:
            try:
                nvmlShutdown()
            except:
                pass
```

### File: docker\bedrock\src\server.py
```python
from flask import Flask, request, jsonify
import torch
import os
from nvml_monitor import GPUMonitor

app = Flask(__name__)
gpu_monitor = GPUMonitor()

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'resources': gpu_monitor.get_gpu_info(),
        'environment': {
            'MODEL_BASE_PATH': os.getenv('MODEL_BASE_PATH', '/models'),
            'MODEL_CONFIG_PATH': os.getenv('MODEL_CONFIG_PATH', '/models/config')
        }
    })

@app.route('/v1/bedrock/models')
def list_models():
    model_path = os.getenv('MODEL_BASE_PATH', '/models')
    if not os.path.exists(model_path):
        return jsonify({'models': [], 'error': 'Model path not found'})

    try:
        models = [d for d in os.listdir(model_path) 
                 if os.path.isdir(os.path.join(model_path, d))]
        return jsonify({'models': models})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### File: docker\bedrock\src\config\model_config.json
```json
# docker/bedrock/src/config/model_config.json
{
  "local_model": {
    "model_id": "meta-llama/Llama-3.2-11B-Vision-Instruct",
    "model_path": "D:/models/llama-3.2",
    "quantization": "8bit",
    "gpu_layers": "all",
    "vision_enabled": true,
    "context_window": 4096
  }
}
```

### File: docker\cloudwatch\Dockerfile
```
FROM node:18-alpine
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY src/ ./src/

# Expose metrics port
EXPOSE 9090

# Start the service
CMD ["node", "src/server.js"]

```

### File: docker\cloudwatch\package.json
```json
{
    "name": "aws-local-cloudwatch",
    "version": "1.0.0",
    "description": "Local implementation of AWS CloudWatch",
    "main": "src/server.js",
    "scripts": {
        "start": "node src/server.js",
        "dev": "nodemon src/server.js",
        "test": "jest"
    },
    "dependencies": {
        "express": "^4.18.2",
        "morgan": "^1.10.0",
        "uuid": "^9.0.0"
    },
    "devDependencies": {
        "jest": "^29.7.0",
        "nodemon": "^3.0.2"
    }
}

```

### File: docker\cloudwatch\src\server.js
```javascript
const express = require('express');
const app = express();
const port = process.env.PORT || 9090;

// Basic metrics storage
const metrics = {
    data: {},
    timestamp: null
};

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Store metrics endpoint
app.post('/metrics', (req, res) => {
    metrics.data = req.body;
    metrics.timestamp = new Date().toISOString();
    res.json({ status: 'success' });
});

// Get metrics endpoint
app.get('/metrics', (req, res) => {
    res.json(metrics);
});

app.listen(port, () => {
    console.log(`CloudWatch service listening on port ${port}`);
});

```

### File: modules\Common.psm1
```powershell
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
```

### File: storage\cache\version.txt
```
1
```
