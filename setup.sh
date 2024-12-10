#!/bin/bash

# Create service subdirectories
mkdir -p services/apigateway services/cloudwatch services/bedrock services/dynamodb

# Create infrastructure subdirectories
mkdir -p infrastructure/iam infrastructure/vpc infrastructure/ec2

# Create Docker configuration subdirectories
mkdir -p docker/apigateway docker/cloudwatch docker/bedrock docker/dynamodb

# Create shared utilities and configuration subdirectories
mkdir -p shared/utils shared/config

# Create documentation subdirectories
mkdir -p docs/api docs/architecture

# Initialize git repository
git init

# Create initial README.md
echo "# AWS Local Infrastructure

A local implementation of AWS-style services using Docker.

## Services
- API Gateway (request routing and management)
- CloudWatch (monitoring and metrics)
- Bedrock (LLM operations)
- DynamoDB (document storage)

## Requirements
- Windows 11 Pro
- Docker Desktop
- NVIDIA RTX 3090
- Visual Studio Code

## Setup
1. Run \`setup.sh\` to create project structure
2. Run \`docker-compose up\` to start services

## Development
This project follows an Agile methodology with 2-week sprints.

## Architecture
See \`docs/architecture\` for detailed system design." > README.md

# Create initial .gitignore
echo "# Dependencies
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
Thumbs.db" > .gitignore

# Initialize npm for package management
npm init -y

# Create initial docker-compose.yml
echo "version: '3.8'

services:
  apigateway:
    build: ./docker/apigateway
    ports:
      - '8080:8080'
    networks:
      - frontend
      - backend

  cloudwatch:
    build: ./docker/cloudwatch
    volumes:
      - metrics_data:/var/lib/cloudwatch
    networks:
      - backend

networks:
  frontend:
  backend:

volumes:
  metrics_data:" > docker-compose.yml

# Make initial git commit
git add .
git commit -m "feat(project): initial project structure

- Created basic directory structure
- Added README.md and .gitignore
- Set up docker-compose.yml with initial services
- Established documentation framework"