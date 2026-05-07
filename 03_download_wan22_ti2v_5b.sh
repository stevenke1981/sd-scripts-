#!/bin/bash
# Download Wan2.2 TI2V 5B (Q8_0) + supporting models
# Priority: HIGH — no CLIP-Vision needed, faster inference
# VRAM estimate: 8-11 GB
set -euo pipefail

MODEL_DIR="$HOME/models/wan22_ti2v_5b"
mkdir -p "$MODEL_DIR"

echo "======================================"
echo " Wan2.2 TI2V 5B  Q8_0 Download"
echo " (No CLIP-Vision required)"
echo "======================================"

if ! python3 -c "import huggingface_hub" 2>/dev/null; then
    echo "[INFO] Installing huggingface-hub..."
    pip install -q huggingface-hub
fi

HF_DL="python3 -m huggingface_hub download"

# ---------- 1. Main model ----------
echo "[1/3] Downloading main model (Wan2.2-TI2V-5B Q8_0)..."
echo "      Source: QuantStack/Wan2.2-TI2V-5B-GGUF"
$HF_DL \
    QuantStack/Wan2.2-TI2V-5B-GGUF \
    --include "*Q8_0*" \
    --local-dir "$MODEL_DIR/main"

# ---------- 2. T5-XXL text encoder ----------
echo "[2/3] Downloading T5-XXL text encoder (Q8_0)..."
echo "      Source: city96/t5-v1_1-xxl-encoder-gguf"
$HF_DL \
    city96/t5-v1_1-xxl-encoder-gguf \
    --include "*Q8_0*" \
    --local-dir "$MODEL_DIR/t5xxl"

# ---------- 3. VAE ----------
# Wan2.2 uses the same Wan VAE family.
echo "[3/3] Downloading Wan VAE..."
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
echo "   main/  ← Wan2.2-TI2V-5B-Q8_0.gguf (main model)"
echo "   t5xxl/ ← t5-v1_1-xxl-encoder-Q8_0.gguf"
echo "   vae/   ← Wan2.1-vae.gguf"
echo ""
echo " NOTE: Wan2.2 TI2V does NOT require CLIP-Vision."
echo " If QuantStack repo name is wrong, search at:"
echo "   https://huggingface.co/QuantStack"
echo "======================================"
echo ""
ls -lh "$MODEL_DIR"/*/  2>/dev/null || true
