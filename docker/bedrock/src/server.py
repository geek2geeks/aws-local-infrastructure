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