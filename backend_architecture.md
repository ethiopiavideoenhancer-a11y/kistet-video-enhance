# Kistet Enhance AI - Backend Architecture (FastAPI)

## Stack
- **Framework**: FastAPI
- **DB**: PostgreSQL (SQLAlchemy)
- **Queue**: Redis + RQ
- **Auth**: JWT (OAuth2)
- **Processing**: FFmpeg + PyTorch (Real-ESRGAN, GFPGAN)

## Project Structure
```
backend/
├── app/
│   ├── main.py          # Entry point
│   ├── auth.py          # JWT, Login, Register
│   ├── models.py        # DB Models
│   ├── schemas.py       # Pydantic Schemas
│   ├── database.py      # Connection
│   ├── routes/
│   │   ├── videos.py    # Upload, Status, Download
│   │   └── payments.py  # Chapa & Stripe
│   └── utils/
│       ├── storage.py   # S3/Cloudinary wrappers
│       └── security.py  # Hashing, Token generation
├── worker/
│   ├── main.py          # Redis worker
│   ├── ai_engine.py     # AI Processing logic (ESRGAN, GFPGAN)
│   └── ffmpeg_utils.py  # Frame extraction & recomposition
├── Dockerfile
├── requirements.txt
└── .env
```

## Key Snippets

### AI Processing Logic (worker/ai_engine.py)
```python
import subprocess
import os

def enhance_video(video_path, options):
    # 1. Extract Frames
    subprocess.run(["ffmpeg", "-i", video_path, "frames/f%05d.png"])
    
    # 2. HD Upscale (Real-ESRGAN)
    if options.get('upscale'):
        subprocess.run(["python", "Real-ESRGAN/inference_realesrgan.py", "-i", "frames", "-o", "enhanced_frames"])
    
    # 3. Face Enhancement (GFPGAN)
    if options.get('face'):
        subprocess.run(["python", "GFPGAN/inference_gfpgan.py", "-i", "enhanced_frames", "-o", "face_frames", "-v", "1.3"])
    
    # 4. FPS Boost (RIFE)
    # ... logic ...

    # 5. Recompose Video
    subprocess.run([
        "ffmpeg", "-i", "face_frames/f%05d.png", 
        "-i", video_path, # original for audio
        "-map", "0:v", "-map", "1:a",
        "-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p",
        "final_output.mp4"
    ])
    return "final_output.mp4"
```

### Chapa Payment Integration (app/routes/payments.py)
```python
@router.post("/chapa/initiate")
async def init_chapa(amount: float, email: str, user_id: int):
    headers = {"Authorization": f"Bearer {CHAPA_SECRET_KEY}"}
    payload = {
        "amount": amount,
        "currency": "ETB",
        "email": email,
        "tx_ref": f"kistet-{uuid.uuid4()}",
        "callback_url": f"{BASE_URL}/verify-payment",
        "customization": {"title": "Kistet HD Unlock"}
    }
    response = requests.post("https://api.chapa.co/v1/transaction/initialize", json=payload, headers=headers)
    return response.json()