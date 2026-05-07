#!/bin/bash
# Download Wan2.1 I2V 14B 720p (Q8_0) + supporting models
# Priority: ALTERNATIVE — higher resolution, needs 12-15 GB VRAM
# VRAM estimate: 12-15 GB (reduce frames to 17 if OOM)
set -euo pipefail

MODEL_DIR="$HOME/models/wan21_i2v_720p"
mkdir -p "$MODEL_DIR"

echo "======================================"
echo " Wan2.1 I2V 14B 720p  Q8_0 Download"
echo "======================================"

VENV="$HOME/.sd-scripts-venv"

if ! command -v uv &>/dev/null; then
    echo "[INFO] Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ ! -x "$VENV/bin/python" ]; then
    echo "[INFO] Creating venv..."
    uv venv "$VENV"
fi

if ! "$VENV/bin/python" -c "import huggingface_hub" 2>/dev/null; then
    echo "[INFO] Installing huggingface-hub..."
    uv pip install --python "$VENV" -q huggingface-hub
fi

hf_download() {
    local repo="$1"; shift
    local include_pattern="" local_dir=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --include)   include_pattern="$2"; shift 2 ;;
            --local-dir) local_dir="$2";       shift 2 ;;
            *)           shift ;;
        esac
    done
    mkdir -p "$local_dir"

    local check_pattern="${include_pattern:-*.gguf}"
    if [ -n "$(find "$local_dir" -maxdepth 2 -name "$check_pattern" 2>/dev/null | head -1)" ]; then
        echo "  [SKIP] Already downloaded: $local_dir"
        return 0
    fi

    if [ -x "$VENV/bin/hf" ]; then
        local args=("$repo")
        [ -n "$include_pattern" ] && args+=(--include "$include_pattern")
        args+=(--local-dir "$local_dir")
        "$VENV/bin/hf" download "${args[@]}"
    else
        echo "[INFO] hf not found, using wget..."
        local regex
        regex=$(printf '%s' "$include_pattern" | sed 's/\./\\./g; s/\*/.*/g')
        curl -fsSL "https://huggingface.co/api/models/${repo}" \
            | grep -o '"rfilename":"[^"]*"' \
            | sed 's/"rfilename":"//; s/"//' \
            | grep -E "$regex" \
            | while IFS= read -r f; do
                echo "  -> $f"
                wget -q --show-progress -c \
                    "https://huggingface.co/${repo}/resolve/main/${f}" \
                    -O "$local_dir/$(basename "$f")"
              done
    fi
}
HF_DL=hf_download

# ---------- 1. Main model ----------
echo "[1/4] Downloading main model (Wan2.1-I2V-14B-720P Q8_0)..."
echo "      Source: city96/Wan2.1-I2V-14B-720P-gguf"
$HF_DL \
    city96/Wan2.1-I2V-14B-720P-gguf \
    --include "*.gguf" \
    --local-dir "$MODEL_DIR/main"

# ---------- 2. T5-XXL text encoder ----------
echo "[2/4] Downloading T5-XXL text encoder (Q8_0)..."
echo "      Source: city96/t5-v1_1-xxl-encoder-gguf"
$HF_DL \
    city96/t5-v1_1-xxl-encoder-gguf \
    --include "*Q8_0*" \
    --local-dir "$MODEL_DIR/t5xxl"

# ---------- 3. CLIP Vision encoder (ViT-H) ----------
echo "[3/4] Downloading CLIP Vision ViT-H encoder..."
echo "      Source: mys/ggml_CLIP-ViT-H-14-laion2B-s32B-b79K"
$HF_DL \
    mys/ggml_CLIP-ViT-H-14-laion2B-s32B-b79K \
    --include "*vision-model-q8_0*" \
    --local-dir "$MODEL_DIR/clip_vision"

# ---------- 4. VAE ----------
echo "[4/4] Downloading Wan VAE..."
echo "      Source: city96/Wan2.1-VAE-gguf"
$HF_DL \
    city96/Wan2.1-VAE-gguf \
    --include "*.gguf" \
    --local-dir "$MODEL_DIR/vae"

echo ""
echo "======================================"
echo " Download complete!"
echo " Model dir : $MODEL_DIR"
echo ""
echo " Expected files:"
echo "   main/        ← Wan2.1-I2V-14B-720P-Q8_0.gguf"
echo "   t5xxl/       ← t5-v1_1-xxl-encoder-Q8_0.gguf"
echo "   clip_vision/ ← clip-vit-H-14-*.gguf"
echo "   vae/         ← Wan2.1-vae.gguf"
echo ""
echo " WARNING: 720p needs 12-15 GB VRAM."
echo " If you get OOM, use 05_generate_wan21_480p.sh instead,"
echo " or reduce --video-frames to 17 in the generation script."
echo "======================================"
echo ""
ls -lh "$MODEL_DIR"/*/  2>/dev/null || true
