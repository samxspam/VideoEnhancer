#!/bin/bash

# Ask for video file
read -p "🎥 Enter the input video file name (with extension): " input_video

# Exit if file doesn't exist
if [ ! -f "$input_video" ]; then
  echo "❌ File '$input_video' not found!"
  exit 1
fi

cd /workspace

# =============================
# 1️⃣ Clone RIFE if not exists
# =============================
if [ ! -d "ECCV2022-RIFE" ]; then
  echo "📥 Cloning RIFE..."
  git clone https://github.com/megvii-research/ECCV2022-RIFE.git
  cd ECCV2022-RIFE
  pip install -r requirements.txt
  echo "📥 Downloading RIFE model..."
  apt install -y gdown
  gdown 1APIzVeI-4ZZCEuIRE1m6WYfSCaOsi_7_ -O RIFE_trained_model_v3.6.zip
  unzip RIFE_trained_model_v3.6.zip
  cd ..
fi

# =============================
# 2️⃣ Clone Real-ESRGAN if not exists
# =============================
if [ ! -d "Real-ESRGAN" ]; then
  echo "📥 Cloning Real-ESRGAN..."
  git clone https://github.com/xinntao/Real-ESRGAN.git
  cd Real-ESRGAN
  pip install -r requirements.txt
  pip install numpy==1.23.5
  python setup.py develop
  wget https://github.com/ai-forever/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth -P weights
  cd ..
fi

# =============================
# 3️⃣ Generate Unique Output Name
# =============================
filename=$(basename -- "$input_video")
name="${filename%.*}"
ext="${filename##*.}"
output_video="${name}_hq.${ext}"

counter=1
while [[ -e "$output_video" ]]; do
  output_video="${name}_hq_${counter}.${ext}"
  ((counter++))
done

# =============================
# 4️⃣ Interpolate with RIFE
# =============================
echo "🚀 Interpolating to 60 FPS with RIFE..."
mkdir -p interpolated_frames
cd ECCV2022-RIFE
python3 inference_video.py --video "../$input_video" --output ../interpolated_60fps.mp4 --fps 60
cd ..

# =============================
# 5️⃣ Extract Frames
# =============================
mkdir -p extracted_frames
echo "📸 Extracting frames from 60 FPS video..."
ffmpeg -y -i interpolated_60fps.mp4 extracted_frames/%08d.png

# =============================
# 6️⃣ Upscale Frames
# =============================
mkdir -p upscaled_frames
echo "🧠 Upscaling frames with Real-ESRGAN..."
cd Real-ESRGAN
python inference_realesrgan.py -n RealESRGAN_x4plus -i ../extracted_frames -o ../upscaled_frames --suffix out
cd ..

# =============================
# 7️⃣ Reassemble Final Video with GPU
# =============================
echo "🎬 Reassembling final video with NVENC (GPU)..."
ffmpeg -framerate 60 -i upscaled_frames/%08d_out.png -c:v h264_nvenc -pix_fmt yuv420p "$output_video"

echo "✅ Done! Output saved as: $output_video"
