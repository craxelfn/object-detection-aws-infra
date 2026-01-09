
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import numpy as np
from PIL import Image
import base64
import io
from typing import List
from ultralytics import YOLO

app = FastAPI(title="Object Detection API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "https://car-nu-eight.vercel.app"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = None

class DetectionRequest(BaseModel):
    imageData: str
    width: int
    height: int

class Detection(BaseModel):
    class_name: str
    score: float
    bbox: List[float]

class DetectionResponse(BaseModel):
    success: bool
    predictions: List[Detection]

@app.on_event("startup")
async def load_model():
    global model
    print("Loading YOLOv8 model...")
    model = YOLO("yolov8s.pt")
    print("Model ready")

@app.get("/health")
async def health_check():
    return {"status": "healthy", "model_loaded": model is not None, "model_type": "YOLOv8s"}

@app.post("/detect", response_model=DetectionResponse)
async def detect_objects(request: DetectionRequest):
    global model
    
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded yet")
    
    try:
        image_bytes = base64.b64decode(request.imageData)
        image = Image.open(io.BytesIO(image_bytes))
        
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        image_np = np.array(image)
        
        results = model(image_np, conf=0.5, verbose=False)
        
        predictions = []
        
        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for i in range(len(boxes)):
                    box = boxes.xyxy[i].cpu().numpy()
                    x1, y1, x2, y2 = box
                    
                    box_width = x2 - x1
                    box_height = y2 - y1
                    
                    scale_x = request.width / image_np.shape[1]
                    scale_y = request.height / image_np.shape[0]
                    
                    bbox = [
                        float(x1 * scale_x),
                        float(y1 * scale_y),
                        float(box_width * scale_x),
                        float(box_height * scale_y)
                    ]
                    
                    cls_id = int(boxes.cls[i].cpu().numpy())
                    confidence = float(boxes.conf[i].cpu().numpy())
                    class_name = model.names[cls_id]
                    
                    predictions.append(Detection(
                        class_name=class_name,
                        score=confidence,
                        bbox=bbox
                    ))
        
        print(f"Detected {len(predictions)} objects")
        return DetectionResponse(success=True, predictions=predictions)
        
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
