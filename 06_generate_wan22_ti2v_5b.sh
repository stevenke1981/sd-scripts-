#!/bin/bash
# Generate video with Wan2.2 TI2V 5B (Q8_0) — Vulkan
# No CLIP-Vision required; faster inference; 8-11 GB VRAM
set -euo pipefail

# ====== USER CONFIG ======
SD_BIN="$HOME/stable-diffusion.cpp/build/bin/sd"
MODEL_DIR="$HOME/models/wan22_ti2v_5b"

INPUT_IMAGE="${1:-input.jpg}"          # arg 1: reference image for I2V
PROMPT="${2:-A cinematic scene, smooth motion, high quality, 4K}"
NEG_PROMPT="blurry, distorted, ugly, low quality, artifacts"

WIDTH=480
HEIGHT=832
FRAMES=33
STEPS=30
CFG_SCALE=7.0
SEED=-1
FPS=16
VK_DEVICE=0

OUTPUT_DIR="$HOME/sd-outputs/wan22_5b"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT="$OUTPUT_DIR/output_${TIMESTAMP}.mp4"
# =========================

mkdir -p "$OUTPUT_DIR"

MAIN_MODEL=$(find "$MODEL_DIR/main"  -name "*.gguf" | sort | head -1)
T5_MODEL=$(find   "$MODEL_DIR/t5xxl" -name "*.gguf" | sort | head -1)
VAE_MODEL=$(find  "$MODEL_DIR/vae"   -name "*.gguf" | sort | head -1)

echo "======================================"
echo " Wan2.2 TI2V 5B — Vulkan (No CLIP-Vision)"
echo "======================================"
echo " Input image  : $INPUT_IMAGE"
echo " Prompt       : $PROMPT"
echo " Resolution   : ${WIDTH}x${HEIGHT}  Frames: $FRAMES  FPS: $FPS"
echo " Steps        : $STEPS   CFG: $CFG_SCALE   Seed: $SEED"
echo " Main model   : $MAIN_MODEL"
echo " T5 encoder   : $T5_MODEL"
echo " VAE          : $VAE_MODEL"
echo " Output       : $OUTPUT"
echo "======================================"

if [ ! -f "$INPUT_IMAGE" ]; then
    echo "ERROR: Input image not found: $INPUT_IMAGE"
    echo "Usage: $0 <input_image.jpg> [\"prompt\"]"
    exit 1
fi

"$SD_BIN" \
    --model         "$MAIN_MODEL" \
    --t5xxl         "$T5_MODEL" \
    --vae           "$VAE_MODEL" \
    --vae-on-cpu \
    --init-img      "$INPUT_IMAGE" \
    --prompt        "$PROMPT" \
    --negative-prompt "$NEG_PROMPT" \
    -W $WIDTH \
    -H $HEIGHT \
    --video-frames  $FRAMES \
    --fps           $FPS \
    --steps         $STEPS \
    --cfg-scale     $CFG_SCALE \
    --seed          $SEED \
    --vk-device     $VK_DEVICE \
    --output        "$OUTPUT"

echo ""
echo "Done! Output saved to: $OUTPUT"
