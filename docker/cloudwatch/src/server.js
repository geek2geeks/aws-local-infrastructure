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
