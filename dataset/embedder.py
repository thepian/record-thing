import hashlib
# from typing import Optional, List, Annotated
# from sqlmodel import Field, SQLModel, Relationship, Column, JSON, Binary
# from datetime import date, datetime
# from pydantic import validator, BaseModel
import torch
from torchvision import transforms
from PIL import Image

# DINOv2 Model Loading
class DINOv2Embedder:
    def __init__(self, model_name='dinov2_vits14'):
        self.model = torch.hub.load('facebookresearch/dinov2', model_name)
        self.model.eval()
        
        # Preprocessing transforms
        self.transform = transforms.Compose([
            transforms.Resize(224),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            )
        ])
    
    def get_embedding(self, image_path: str) -> bytes:
        """
        Generate DINOv2 embedding for an image
        Returns embedding as bytes for SQLite storage
        """
        with Image.open(image_path) as img:
            # Preprocess image
            processed_img = self.transform(img).unsqueeze(0)
            
            # Generate embedding
            with torch.no_grad():
                embedding = self.model.get_intermediate_layers(processed_img, n=1)[0]
            
            # Flatten and convert to numpy
            embedding_np = embedding.squeeze().numpy()
            
            # Convert to bytes for storage
            return embedding_np.tobytes()
    
    @staticmethod
    def compute_sha1(image_path: str) -> str:
        """
        Compute SHA1 hash of image file
        """
        sha1_hash = hashlib.sha1()
        with open(image_path, "rb") as f:
            # Read and update hash in chunks
            for chunk in iter(lambda: f.read(4096), b""):
                sha1_hash.update(chunk)
        return sha1_hash.hexdigest()
