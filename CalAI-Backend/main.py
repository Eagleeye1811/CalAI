import json
import os
from typing import Any, Dict
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi import File, UploadFile
from fastapi.staticfiles import StaticFiles
import uuid
from app.agent import agent
from app.endpoints import nutrition
from app.utils.envManager import get_env_variable, get_env_variable_safe
from app.middleware.exception_handlers import setup_exception_handlers
# AFTER (Disabled):
import logfire

# Disable Logfire in development
logfire.configure(
    send_to_logfire=False,  # Completely disable
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for FastAPI app."""
    yield


isProd = get_env_variable_safe("PROD", "false").lower() == "true"

app = FastAPI(
    title="CalAI Nutrition API",
    description="AI-powered nutrition analysis API with chat functionality",
    version="1.0.0",
    debug=not isProd,
    lifespan=lifespan,
)

app = setup_exception_handlers(app)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(nutrition.router, prefix="/nutrition")
app.include_router(agent.router, prefix="/chat")

# Create uploads directory on startup
os.makedirs("uploads", exist_ok=True)

@app.post("/upload/image")
async def upload_image(image: UploadFile = File(...)):
    """
    Upload image and return a publicly accessible URL
    """
    try:
        # # Validate file is an image (check extension since content_type may be missing)
        # if image.content_type and not image.content_type.startswith('image/'):
        #     # If content_type exists but isn't an image, check file extension as fallback
        #     allowed_extensions = ('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp')
        #     if not image.filename.lower().endswith(allowed_extensions):
        #         raise HTTPException(
        #             status_code=400,
        #             detail="File must be an image (jpg, jpeg, png, gif, bmp, webp)"
        #         )
        
        # Generate unique filename
        file_extension = image.filename.split('.')[-1] if '.' in image.filename else 'jpg'
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = os.path.join("uploads", unique_filename)
        
        # Save file
        with open(file_path, "wb") as f:
            content = await image.read()
            f.write(content)
        
        # Return URL
        # For local: http://10.0.2.2:8000/uploads/filename.jpg
        # For production: https://your-railway-url.up.railway.app/uploads/filename.jpg
        base_url = os.getenv("BASE_URL", "http://localhost:8000")
        image_url = f"{base_url}/uploads/{unique_filename}"
        
        return {
            "success": True,
            "imageUrl": image_url,
            "filename": unique_filename
        }
    except Exception as e:
        logfire.error(f"Image upload failed: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Upload failed: {str(e)}"
        )

# Serve uploaded images as static files
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

@app.get("/")
async def root():
    """Health check and API info"""
    return {
        "status": "healthy",
        "service": "CalAI Nutrition API",
        "version": "1.0.0",
        "endpoints": {
            "docs": "/docs",
            "nutrition_image": "/nutrition/get",
            "nutrition_description": "/nutrition/description",
            "chat": "/chat/",
            "chat_messages": "/chat/messages"
        }
    }

@app.get("/health")
async def health_check():
    """Detailed health check"""
    import os
    
    checks = {
        "status": "healthy",
        "google_api_configured": bool(os.getenv("GOOGLE_API_KEY")),
        "openai_api_configured": bool(os.getenv("OPENAI_API_KEY")),
        "supabase_configured": bool(os.getenv("SUPABASE_URL") and os.getenv("SUPABASE_KEY")),
        "environment": "production" if os.getenv("PROD", "false").lower() == "true" else "development",
    }
    
    return checks

if __name__ == "__main__":
    host = get_env_variable_safe("HOST", "0.0.0.0")
    port = int(get_env_variable_safe("PORT", "8000"))

    uvicorn.run(app, host=host, port=port, reload=not isProd)
