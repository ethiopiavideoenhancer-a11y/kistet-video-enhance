FROM python:3.10-slim

WORKDIR /app

# AI dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Clone models (Example)
# RUN git clone https://github.com/xinntao/Real-ESRGAN.git

COPY . .

# Run RQ worker
CMD ["python", "-m", "rq", "worker", "video_processing", "--url", "redis://redis:6379/0"]