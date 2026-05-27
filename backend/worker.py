import os
import subprocess
import time
import logging
import cloudinary
import cloudinary.uploader
from backend.main import engine, Video
from sqlmodel import Session

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

def process_video_task(video_id: str, preset: str, options: dict):
    logger.info(f"Starting Pro Processing: {video_id} | Preset: {preset}")
    
    with Session(engine) as session:
        video = session.get(Video, video_id)
        if not video: return
        
        try:
            # Paths setup
            base_dir = f"storage/processed/{video_id}"
            os.makedirs(base_dir, exist_ok=True)
            enhanced_mp4 = f"{base_dir}/enhanced.mp4"
            watermarked_mp4 = f"{base_dir}/preview_watermarked.mp4"
            hls_output = f"{base_dir}/index.m3u8"
            thumbnail = f"{base_dir}/thumb.jpg"

            # 1. CORE AI ENHANCEMENT (SIMULATED)
            # In production: run Real-ESRGAN -> GFPGAN -> RIFE
            logger.info("Step 1: Running AI Models...")
            video.progress = 20
            session.add(video); session.commit()
            time.sleep(3)

            # 2. APPLY PRESET & EXPORT (FFmpeg)
            # Presets: TikTok (1080x1920), 4K (3840x2160), Full HD (1920x1080)
            res_map = {"TikTok": "1080:1920", "Instagram Reels": "1080:1920", "4K": "3840:2160", "Full HD": "1920:1080"}
            target_res = res_map.get(preset, "1920:1080")
            
            logger.info(f"Step 2: Exporting with preset {preset}...")
            subprocess.run([
                "ffmpeg", "-y", "-i", video.original_video_url,
                "-vf", f"scale={target_res}:force_original_aspect_ratio=increase,crop={target_res}",
                "-c:v", "libx264", "-crf", "18", "-preset", "slow",
                enhanced_mp4
            ], check=True)
            video.progress = 50
            session.add(video); session.commit()

            # 3. GENERATE WATERMARKED PREVIEW
            logger.info("Step 3: Creating watermarked preview...")
            subprocess.run([
                "ffmpeg", "-y", "-i", enhanced_mp4,
                "-t", "15", # 15s preview
                "-vf", "drawtext=text='BLUERAYS AI PRO':x=w-tw-20:y=h-th-20:fontsize=32:fontcolor=white@0.4:box=1:boxcolor=black@0.2",
                "-c:v", "libx264", "-crf", "28",
                watermarked_mp4
            ], check=True)

            # 4. GENERATE HLS (ADAPTIVE STREAMING)
            logger.info("Step 4: Generating HLS segments...")
            subprocess.run([
                "ffmpeg", "-y", "-i", watermarked_mp4,
                "-codec:v", "libx264", "-codec:a", "aac",
                "-hls_time", "6", "-hls_playlist_type", "vod",
                "-hls_segment_filename", f"{base_dir}/seg%03d.ts",
                hls_output
            ], check=True)

            # 5. GENERATE THUMBNAIL
            subprocess.run([
                "ffmpeg", "-y", "-i", enhanced_mp4, "-ss", "00:00:01", "-vframes", "1", thumbnail
            ], check=True)

            # 6. CLOUD UPLOAD & UPDATE
            logger.info("Step 6: Syncing to Cloud Library...")
            # (Upload calls here...)
            # For brevity in this fix, assume local storage paths or successful Cloudinary upload
            thumb_upload = cloudinary.uploader.upload(thumbnail, folder="bluerays/thumbs")
            
            video.status = "completed"
            video.progress = 100
            video.enhanced_video_url = enhanced_mp4 # HD Link
            video.preview_video_url = watermarked_mp4 # Watermarked Link
            video.thumbnail_url = thumb_upload.get("secure_url")
            video.hls_url = hls_output
            
            session.add(video)
            session.commit()
            logger.info(f"Pro Pipeline Complete: {video_id}")

        except Exception as e:
            logger.error(f"Pro Pipeline Failed: {e}")
            video.status = "failed"
            session.add(video); session.commit()

if __name__ == "__main__":
    pass