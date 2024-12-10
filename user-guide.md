# Local AWS Infrastructure: User Guide

## Introduction

This guide explains how to interact with our local AWS-style infrastructure. Our system provides AWS-compatible APIs for various services, allowing you to develop applications using familiar AWS patterns while running everything locally.

## Getting Started

### Base URL Structure
All services are accessible through our API Gateway at:
```
http://localhost:8080/v1/{service}/{endpoint}
```

### Authentication
Include your API key in all requests:
```
Headers:
  X-Api-Key: your-api-key
```

## Core Services

### 1. Bedrock Service (LLM Operations)

#### Text Generation
```http
POST /v1/bedrock/generate
Content-Type: application/json

{
    "prompt": "Your text prompt here",
    "parameters": {
        "max_length": 100,
        "temperature": 0.7
    }
}
```

#### Model Information
```http
GET /v1/bedrock/models
```

### 2. DynamoDB Service

#### Create Item
```http
POST /v1/dynamodb/items
Content-Type: application/json

{
    "TableName": "YourTable",
    "Item": {
        "id": "unique-id",
        "data": "your-data"
    }
}
```

#### Query Items
```http
POST /v1/dynamodb/query
Content-Type: application/json

{
    "TableName": "YourTable",
    "KeyConditionExpression": "id = :id",
    "ExpressionAttributeValues": {
        ":id": "unique-id"
    }
}
```

### 3. CloudWatch Metrics

#### View Service Metrics
```http
GET /v1/cloudwatch/metrics?service=bedrock
```

#### Set Alarms
```http
POST /v1/cloudwatch/alarms
Content-Type: application/json

{
    "AlarmName": "HighGPUUsage",
    "MetricName": "GPUUtilization",
    "Threshold": 90,
    "Period": 300
}
```

## Common Patterns

### 1. LLM with Storage Example

This pattern shows how to generate text and store the results:

```python
# Example Python code
import requests

# Step 1: Generate text
response = requests.post(
    "http://localhost:8080/v1/bedrock/generate",
    headers={"X-Api-Key": "your-api-key"},
    json={
        "prompt": "Your prompt here",
        "parameters": {"max_length": 100}
    }
)
generated_text = response.json()

# Step 2: Store result
store_response = requests.post(
    "http://localhost:8080/v1/dynamodb/items",
    headers={"X-Api-Key": "your-api-key"},
    json={
        "TableName": "Generations",
        "Item": {
            "id": "unique-id",
            "text": generated_text["response"]
        }
    }
)
```

### 2. Monitoring Resource Usage

Monitor your application's resource consumption:

```python
import requests

# Get current metrics
metrics = requests.get(
    "http://localhost:8080/v1/cloudwatch/metrics",
    headers={"X-Api-Key": "your-api-key"},
    params={
        "service": "bedrock",
        "period": "5m"
    }
)

# Check GPU utilization
gpu_usage = metrics.json()["metrics"]["GPUUtilization"]
```

## Resource Management

### Understanding Limits

Your local infrastructure runs on specific hardware:
- GPU: RTX 3090 (24GB VRAM)
- RAM: 64GB
- CPU: AMD 5950x

Monitor these resources through CloudWatch metrics to ensure optimal performance.

### Best Practices

1. Request Batching
   - Batch similar requests together
   - Use bulk operations for DynamoDB when possible

2. Resource Monitoring
   - Monitor GPU utilization
   - Watch memory usage
   - Track response times

3. Error Handling
   - Implement exponential backoff
   - Handle rate limiting gracefully
   - Check resource availability

## Troubleshooting

### Common Issues and Solutions

1. Service Unavailable
   ```
   Check: http://localhost:8080/v1/health
   ```

2. High Latency
   - Monitor CloudWatch metrics
   - Check resource utilization
   - Consider request batching

3. Rate Limiting
   - Implement request throttling
   - Use exponential backoff
   - Monitor usage patterns

## Development Tools

### Dashboard Access
Access the monitoring dashboard:
```
http://localhost:3000
```

### API Documentation
View OpenAPI documentation:
```
http://localhost:8080/docs
```

## Security Considerations

1. API Key Management
   - Rotate keys regularly
   - Don't share keys between applications
   - Monitor key usage

2. Network Security
   - Use HTTPS for production
   - Implement rate limiting
   - Monitor access patterns

## Migration Considerations

When moving to cloud deployment:
1. Update base URLs
2. Verify resource limits
3. Adjust monitoring thresholds
4. Update security configurations

Remember: The APIs remain consistent between local and cloud deployments, making migration smoother.