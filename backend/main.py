import os
import uuid
from datetime import datetime
from typing import List, Optional, Dict
from fastapi import FastAPI, UploadFile, File, Depends, HTTPException, Query
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel, Field, create_engine, Session, select
from pydantic import BaseModel
import redis
from rq import Queue
import logging

# --- Logging ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- Database Setup ---
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:pass@localhost:5432/bluerays")
engine = create_engine(DATABASE_URL)

class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    email: str = Field(unique=True, index=True)
    password: str
    credits: int = 20
    is_pro: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)

class Video(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    user_id: int
    original_video_url: str
    enhanced_video_url: Optional[str] = None # Direct MP4 (Watermark-free)
    preview_video_url: Optional[str] = None # Direct MP4 (Watermarked)
    hls_url: Optional[str] = None # For adaptive streaming
    thumbnail_url: Optional[str] = None
    status: str = "pending" # pending, processing, completed, failed
    progress: int = 0
    duration: float = 0.0
    resolution: str = "1080p"
    fps: int = 30
    is_unlocked: bool = False 
    preset: str = "Full HD" 
    created_at: datetime = Field(default_factory=datetime.utcnow)

class Payment(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    user_id: int
    video_id: str
    amount: float
    currency: str
    provider: str 
    status: str # "pending", "success", "failed"
    created_at: datetime = Field(default_factory=datetime.utcnow)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

# --- Redis Queue ---
redis_conn = redis.from_url(os.getenv("REDIS_URL", "redis://localhost:6379/0"))
task_queue = Queue("video_processing", connection=redis_conn)

# --- FastAPI App ---
app = FastAPI(title="Bluerays Pro AI API")

# Mount Static Files for HLS segments and uploads
os.makedirs("storage/uploads", exist_ok=True)
os.makedirs("storage/processed", exist_ok=True)
app.mount("/storage", StaticFiles(directory="storage"), name="storage")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

# --- Schemas ---
class EnhancementRequest(BaseModel):
    video_id: str
    user_id: int
    preset: str = "Full HD"
    options: Dict[str, bool]

# --- Routes ---

@app.post("/videos/upload")
async def upload_video(user_id: int, file: UploadFile = File(...)):
    file_id = str(uuid.uuid4())
    original_path = f"storage/uploads/{file_id}-{file.filename}"
    
    with open(original_path, "wb") as buffer:
        buffer.write(await file.read())

    with Session(engine) as session:
        video = Video(
            user_id=user_id, 
            original_video_url=original_path,
            status="pending"
        )
        session.add(video)
        session.commit()
        session.refresh(video)
        return video

@app.post("/videos/enhance")
async def start_enhancement(req: EnhancementRequest):
    with Session(engine) as session:
        video = session.get(Video, req.video_id)
        if not video:
            raise HTTPException(status_code=404, detail="Video not found")
        
        video.status = "processing"
        video.preset = req.preset
        video.progress = 5 # Initial kick-off
        session.add(video)
        session.commit()
        
        # Pass preset to worker
        job = task_queue.enqueue("worker.process_video_task", req.video_id, req.preset, req.options)
        logger.info(f"Pro Enhancement queued: {video.id} with preset {req.preset}")
    
    return {"job_id": job.id, "status": "processing"}

@app.get("/videos/{video_id}")
async def get_video(video_id: str):
    with Session(engine) as session:
        video = session.get(Video, video_id)
        if not video:
            raise HTTPException(status_code=404)
        
        # Return internal URLs as public storage paths
        base_url = "http://localhost:8000"
        return {
            **video.dict(),
            "preview_url": f"{base_url}/{video.preview_video_url}" if video.preview_video_url else None,
            "hls_url": f"{base_url}/{video.hls_url}" if video.hls_url else None,
            "enhanced_video_url": f"{base_url}/{video.enhanced_video_url}" if video.enhanced_video_url and video.is_unlocked else None,
        }

@app.get("/user/{user_id}/library")
async def get_library(user_id: int):
    with Session(engine) as session:
        videos = session.exec(select(Video).where(Video.user_id == user_id).order_by(Video.created_at.desc())).all()
        return videos

@app.delete("/videos/{video_id}")
async def delete_video(video_id: str):
    with Session(engine) as session:
        video = session.get(Video, video_id)
        if video:
            session.delete(video)
            session.commit()
            return {"success": True}
        raise HTTPException(status_code=404)

# --- Payment Flow ---

@app.post("/payments/initiate")
async def initiate_payment(user_id: int, video_id: str, provider: str):
    with Session(engine) as session:
        payment = Payment(user_id=user_id, video_id=video_id, amount=4.99, currency="USD", provider=provider, status="pending")
        session.add(payment)
        session.commit()
        
        # Return mock checkout
        return {"checkout_url": "https://checkout.stripe.com/demo", "payment_id": payment.id}

@app.post("/payments/verify/{payment_id}")
async def verify_payment(payment_id: str):
    with Session(engine) as session:
        payment = session.get(Payment, payment_id)
        if not payment: raise HTTPException(status_code=404)
        
        payment.status = "success"
        session.add(payment)
        
        video = session.get(Video, payment.video_id)
        if video:
            video.is_unlocked = True
            session.add(video)
        
        session.commit()
        return {"success": True, "is_unlocked": True}