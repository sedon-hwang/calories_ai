from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import torch
from PIL import Image
import io
import numpy as np
from ultralytics import YOLO
from transformers import CLIPProcessor, CLIPModel
import uuid
import os
from datetime import datetime

app = FastAPI()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 실제 배포 시에는 구체적인 도메인으로 변경
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 모델 로드
yolo_model = YOLO('yolov8n.pt')  # 또는 커스텀 학습된 모델
clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

# 한식 메뉴 리스트 (CLIP 분류용)
KOREAN_FOODS = [
    "김치찌개", "된장찌개", "비빔밥", "불고기", "삼겹살",
    "김밥", "떡볶이", "라면", "만두", "잡채",
    "김치", "콩나물", "시금치나물", "멸치볶음", "계란말이"
]

class DetectionResponse(BaseModel):
    items: List[dict]
    image_id: str

@app.post("/v1/detect")
async def detect_food(file: UploadFile = File(...)):
    try:
        # 이미지 읽기
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # YOLO로 객체 감지
        results = yolo_model(image)
        detections = results[0].boxes.data  # xy1xy2 -> xywh 형식으로 변환 필요
        
        items = []
        for det in detections:
            x1, y1, x2, y2, conf, cls = det
            # 바운딩 박스를 xywh 형식으로 변환
            w = x2 - x1
            h = y2 - y1
            x = x1
            y = y1
            
            # 객체 영역 크롭
            crop = image.crop((x1, y1, x2, y2))
            
            # CLIP으로 음식 분류
            inputs = clip_processor(images=crop, text=KOREAN_FOODS, return_tensors="pt", padding=True)
            outputs = clip_model(**inputs)
            probs = outputs.logits_per_image.softmax(dim=1)
            food_idx = probs.argmax().item()
            
            items.append({
                "name": KOREAN_FOODS[food_idx],
                "confidence": float(conf),
                "bbox": {
                    "x": float(x),
                    "y": float(y),
                    "width": float(w),
                    "height": float(h)
                }
            })
        
        # 이미지 ID 생성
        image_id = str(uuid.uuid4())
        
        return DetectionResponse(items=items, image_id=image_id)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class UpdateRequest(BaseModel):
    image_id: str
    food_name: str
    item_index: int

@app.post("/v1/update-classification")
async def update_classification(request: UpdateRequest):
    try:
        # TODO: 데이터베이스에 수정된 분류 결과 저장
        # 이 데이터는 나중에 모델 재학습에 사용할 수 있음
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 