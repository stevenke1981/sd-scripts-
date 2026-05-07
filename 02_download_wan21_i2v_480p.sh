#!/bin/bash
# Download Wan2.1 I2V 14B 480p (Q8_0) + supporting models
# Priority: HIGHEST — best image quality for 16 GB VRAM
# VRAM estimate: 10-13 GB + CPU offload for VAE
set -euo pipefail

MODEL_DIR="$HOME/models/wan21_i2v_480p"
mkdir -p "$MODEL_DIR"

echo "======================================"
echo " Wan2.1 I2V 14B 480p  Q8_0 Download"
echo "======================================"

# ---------- check huggingface-hub ----------
if ! python3 -c "import huggingface_hub" 2>/dev/null; then
    echo "[INFO] Installing huggingface-hub..."
    pip install -q huggingface-hub
fi

HF_DL="python3 -m huggingface_hub download"

# ---------- 1. Main model ----------
echo "[1/4] Downloading main model (Wan2.1-I2V-14B-480P Q8_0)..."
echo "      Source: city96/Wan2.1-I2V-14B-480P-gguf"
$HF_DL \
    city96/Wan2.1-I2V-14B-480P-gguf \
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
# Wan2.1 I2V requires a CLIP vision encoder to encode the reference image.
echo "[3/4] Downloading CLIP Vision ViT-H encoder..."
echo "      Source: city96/clip-vit-H-14-laion2B-s32B-b79K-GGUF"
$HF_DL \
    city96/clip-vit-H-14-laion2B-s32B-b79K-GGUF \
    --include "*Q8_0*" \
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
echo "   main/        ← Wan2.1-I2V-14B-480P-Q8_0.gguf (main model)"
echo "   t5xxl/       ← t5-v1_1-xxl-encoder-Q8_0.gguf"
echo "   clip_vision/ ← clip-vit-H-14-*.gguf"
echo "   vae/         ← Wan2.1-vae.gguf"
echo ""
echo " NOTE: If any repo name is wrong, search at:"
echo "   https://huggingface.co/city96"
echo "======================================"
echo ""
ls -lh "$MODEL_DIR"/*/  2>/dev/null || true
