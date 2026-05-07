#!/bin/bash
# Generate video with Wan2.1 I2V 14B 720p (Q8_0) — Vulkan
# Higher resolution; 12-15 GB VRAM; reduce FRAMES to 17 if OOM
set -euo pipefail

# ====== USER CONFIG ======
SD_BIN="$HOME/stable-diffusion.cpp/build/bin/sd-cli"
MODEL_DIR="$HOME/models/wan21_i2v_720p"

INPUT_IMAGE="${1:-input.jpg}"
# arg 2: prompt string or path to a .txt file
if [ -f "${2:-}" ]; then
    PROMPT=$(cat "$2")
else
    PROMPT="${2:-A cinematic scene, smooth camera motion, high quality, ultra HD}"
fi
NEG_PROMPT="blurry, distorted, ugly, low quality, artifacts"

WIDTH=720
HEIGHT=1280
# 16 GB VRAM: 33 frames may OOM at 720p 14B.
# Try 33 first; drop to 17 if you see out-of-memory errors.
FRAMES=33
STEPS=30
CFG_SCALE=7.0
SEED=-1
FPS=16

OUTPUT_DIR="$HOME/sd-outputs/wan21_720p"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT="$OUTPUT_DIR/output_${TIMESTAMP}.mp4"
# =========================

mkdir -p "$OUTPUT_DIR"

MAIN_MODEL=$(find "$MODEL_DIR/main"        -name "*Q8_0*" | head -1)
T5_MODEL=$(find   "$MODEL_DIR/t5xxl"       -name "*.gguf" | sort | head -1)
CLIP_VIS=$(find   "$MODEL_DIR/clip_vision" -name "*.gguf" | sort | head -1)
VAE_MODEL=$(find  "$MODEL_DIR/vae"         \( -name "*.safetensors" -o -name "*.gguf" \) | sort | head -1)

echo "======================================"
echo " Wan2.1 I2V 14B 720p — Vulkan"
echo "======================================"
echo " Input image  : $INPUT_IMAGE"
echo " Prompt       : $PROMPT"
echo " Resolution   : ${WIDTH}x${HEIGHT}  Frames: $FRAMES  FPS: $FPS"
echo " Steps        : $STEPS   CFG: $CFG_SCALE   Seed: $SEED"
echo " Main model   : $MAIN_MODEL"
echo " T5 encoder   : $T5_MODEL"
echo " CLIP-Vision  : $CLIP_VIS"
echo " VAE          : $VAE_MODEL"
echo " Output       : $OUTPUT"
echo ""
echo " NOTE: 720p 14B uses 12-15 GB VRAM."
echo "       If OOM → edit FRAMES=17 in this script."
echo "======================================"

if [ ! -f "$INPUT_IMAGE" ]; then
    echo "ERROR: Input image not found: $INPUT_IMAGE"
    echo "Usage: $0 <input_image.jpg> [\"prompt\"]"
    exit 1
fi

"$SD_BIN" \
    --model          "$MAIN_MODEL" \
    --t5xxl          "$T5_MODEL" \
    --clip_vision    "$CLIP_VIS" \
    --vae            "$VAE_MODEL" \
    --vae-on-cpu \
    --init-img       "$INPUT_IMAGE" \
    --prompt         "$PROMPT" \
    --negative-prompt "$NEG_PROMPT" \
    -W $WIDTH \
    -H $HEIGHT \
    --video-frames   $FRAMES \
    --fps            $FPS \
    --steps          $STEPS \
    --cfg-scale      $CFG_SCALE \
    --seed           $SEED \
    --output         "$OUTPUT"

echo ""
echo "Done! Output saved to: $OUTPUT"
