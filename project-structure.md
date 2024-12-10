# Project Structure: Local AWS-Style Infrastructure

```
/local-aws-infrastructure
│
├── /services                  # Service implementations
│   ├── /bedrock              # LLM service (similar to AWS Bedrock)
│   │   ├── /models          # Model configurations
│   │   └── /inference       # Inference endpoints
│   │
│   ├── /dynamodb            # Document database service
│   │   ├── /tables         # Table definitions
│   │   └── /indexes        # Index configurations
│   │
│   ├── /apigateway          # API routing and management
│   │   ├── /routes         # API route definitions
│   │   └── /authorizers    # Authentication handlers
│   │
│   └── /cloudwatch          # Monitoring and logging
│       ├── /metrics        # Metric collectors
│       └── /alarms         # Alert configurations
│
├── /infrastructure          # Infrastructure configuration
│   ├── /iam                # Identity and access management
│   │   ├── /roles         # Service role definitions
│   │   └── /policies      # Access policy configurations
│   │
│   ├── /vpc                # Network configuration
│   │   ├── /subnets       # Network segmentation
│   │   └── /security      # Security groups
│   │
│   └── /ec2                # Compute resource management
│       └── /gpu           # GPU resource configurations
│
├── /docker                 # Container configurations
│   ├── /bedrock           # LLM service Dockerfile
│   ├── /dynamodb          # Database Dockerfile
│   ├── /apigateway        # API Gateway Dockerfile
│   └── docker-compose.yml # Service orchestration
│
├── /shared                 # Shared utilities and configurations
│   ├── /utils             # Common utility functions
│   └── /config            # Configuration management
│
└── /docs                  # Documentation
    ├── /api              # API specifications
    └── /architecture     # System design documents
```

## Service Naming Convention

Our naming convention directly maps local implementations to their AWS counterparts:

### Compute Services
- `bedrock/`: Local implementation of AWS Bedrock-style LLM service
- `ec2/`: Resource management similar to EC2 instances
- `lambda/`: Serverless-style function execution (future implementation)

### Storage Services
- `dynamodb/`: Document database service implementing DynamoDB-style APIs
- `s3/`: Object storage service (future implementation)

### Networking
- `apigateway/`: API management service similar to Amazon API Gateway
- `vpc/`: Network isolation and security similar to Amazon VPC

### Monitoring
- `cloudwatch/`: Monitoring and logging service similar to Amazon CloudWatch
- `cloudwatch/metrics/`: Metric collection and storage
- `cloudwatch/alarms/`: Alert configuration and management

### Security
- `iam/`: Identity and access management similar to AWS IAM
- `iam/roles/`: Service role definitions
- `iam/policies/`: Access control policies

## File Naming Convention

Individual files should follow AWS naming patterns:

### Configuration Files
- `bedrock-config.yml`: Configuration for LLM service
- `dynamodb-table-def.json`: Table definitions for document store
- `cloudwatch-metrics.yml`: Metric collection configuration

### Implementation Files
- `bedrock-inference.py`: LLM inference implementation
- `dynamodb-operations.py`: Database operations
- `apigateway-router.py`: API routing logic

### Docker Files
- `Dockerfile.bedrock`: LLM service container
- `Dockerfile.dynamodb`: Database container
- `docker-compose.yml`: Service orchestration

## Component Mapping Examples

Here's how our local components map to AWS services:

1. LLM Service Implementation:
   ```
   /services/bedrock/models/llama.py → AWS Bedrock
   /services/bedrock/inference/endpoint.py → Bedrock Runtime
   ```

2. Database Implementation:
   ```
   /services/dynamodb/tables/definition.py → DynamoDB Tables
   /services/dynamodb/indexes/manager.py → DynamoDB Indexes
   ```

3. API Management:
   ```
   /services/apigateway/routes/router.py → API Gateway Routes
   /services/apigateway/authorizers/auth.py → API Gateway Authorizers
   ```

This structure ensures that:
- Each component's purpose is immediately clear to AWS users
- Services maintain separation of concerns
- Future AWS-style services can be easily added
- Migration paths to actual AWS services are obvious