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