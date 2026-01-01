#!/usr/bin/env bash
set -euo pipefail

MODEL_ID="${MODEL_ID:-FunAudioLLM/Fun-CosyVoice3-0.5B-2512}"
MODEL_ROOT="${MODEL_ROOT:-/models}"
MODEL_DIR="${MODEL_DIR:-${MODEL_ROOT}/Fun-CosyVoice3-0.5B-2512}"
PORT="${PORT:-50000}"

mkdir -p "${MODEL_ROOT}" "${MODEL_DIR}"

# Put HF cache under the mounted volume by default (avoids redownloading across container runs).
export HF_HOME="${HF_HOME:-${MODEL_ROOT}/.hf}"
mkdir -p "${HF_HOME}"

has_model_manifest() {
  [[ -f "${MODEL_DIR}/cosyvoice3.yaml" ]] || [[ -f "${MODEL_DIR}/cosyvoice2.yaml" ]] || [[ -f "${MODEL_DIR}/cosyvoice.yaml" ]]
}

if ! has_model_manifest; then
  echo "[entrypoint] Model not found in ${MODEL_DIR}. Downloading from HuggingFace: ${MODEL_ID}"
  python3 - <<'PY'
import os
from huggingface_hub import snapshot_download

repo_id = os.environ.get("MODEL_ID")
model_dir = os.environ.get("MODEL_DIR")
hf_home = os.environ.get("HF_HOME")
token = os.environ.get("HF_TOKEN") or os.environ.get("HUGGINGFACE_HUB_TOKEN")

assert repo_id, "MODEL_ID is required"
assert model_dir, "MODEL_DIR is required"

print(f"[entrypoint] HF_HOME={hf_home}")
print(f"[entrypoint] snapshot_download(repo_id={repo_id}, local_dir={model_dir})")

snapshot_download(
    repo_id=repo_id,
    local_dir=model_dir,
    local_dir_use_symlinks=False,
    resume_download=True,
    token=token,
)
PY
else
  echo "[entrypoint] Found existing model in ${MODEL_DIR}, skip download."
fi

echo "[entrypoint] Starting FastAPI server on 0.0.0.0:${PORT} with model_dir=${MODEL_DIR}"
exec python3 runtime/python/fastapi/server.py --port "${PORT}" --model_dir "${MODEL_DIR}"

