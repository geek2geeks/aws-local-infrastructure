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