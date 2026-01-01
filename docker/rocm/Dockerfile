ARG BASE_IMAGE=rocm/pytorch:rocm7.1.1_ubuntu22.04_py3.10_pytorch_release_2.9.1
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
SHELL ["/bin/bash", "-lc"]

# System deps for audio + common Python wheels (e.g. pyworld) build
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      ffmpeg \
      sox \
      libsox-dev \
      build-essential \
      pkg-config \
      libsndfile1 \
      libsndfile1-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/CosyVoice
COPY . /opt/CosyVoice

ENV PYTHONPATH="/opt/CosyVoice:/opt/CosyVoice/third_party/Matcha-TTS"

# Prevent pip from swapping the ROCm PyTorch in the base image with CUDA wheels.
# Some dependencies only declare "torch" and pip may try to resolve by upgrading.
RUN python3 - <<'PY'
import importlib.metadata as md

# Lock ROCm stack shipped by base image to prevent pip from trying to swap wheels.
pkgs = ["torch", "torchaudio", "torchvision", "triton"]
lines = []
for p in pkgs:
    try:
        lines.append(f"{p}=={md.version(p)}")
    except md.PackageNotFoundError:
        pass

path = "/tmp/pip-constraints.txt"
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print("[rocm] constraints:")
print(open(path, "r", encoding="utf-8").read())
PY

RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install --no-cache-dir -c /tmp/pip-constraints.txt -r /opt/CosyVoice/requirements-rocm.txt

# Install openai-whisper WITHOUT dependencies:
# - We only need the `whisper.tokenizer` module.
# - `openai-whisper` depends on `triton<3` which conflicts with ROCm PyTorch (triton>=3).
RUN python3 -m pip install --no-cache-dir --no-deps openai-whisper==20231117

RUN chmod +x /opt/CosyVoice/docker/rocm/entrypoint.sh

EXPOSE 50000

# Auto-download model to mounted volume, then start FastAPI.
ENTRYPOINT ["/opt/CosyVoice/docker/rocm/entrypoint.sh"]
