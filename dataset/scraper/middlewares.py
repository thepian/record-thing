import hashlib
import os
import torch
import torchvision.transforms as transforms
from PIL import Image
import io

class DinoV2EmbeddingMiddleware:
    def __init__(self, download_dir):
        self.download_dir = download_dir
        
        # Load DINO v2 model (base version)
        self.model = torch.hub.load('facebookresearch/dinov2', 'dinov2_vits14')
        self.model.eval()
        
        # Preprocessing transform
        self.transform = transforms.Compose([
            transforms.Resize(224),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            )
        ])
    
    @classmethod
    def from_crawler(cls, crawler):
        return cls(
            download_dir=crawler.settings.get('IMAGES_STORE', './downloads')
        )
    
    def process_item(self, item, spider):
        # Generate SHA1 hash for the image
        with open(item['file_path'], 'rb') as f:
            file_hash = hashlib.sha1(f.read()).hexdigest()
        item['sha1_hash'] = file_hash
        
        # Extract DINO v2 embedding
        try:
            with Image.open(item['file_path']) as img:
                input_tensor = self.transform(img).unsqueeze(0)
                
                with torch.no_grad():
                    embedding = self.model(input_tensor)
                
                # Convert embedding to list for JSON serialization
                item['dino_embedding'] = embedding.squeeze().tolist()
        except Exception as e:
            spider.logger.error(f"Error processing embedding for {item['url']}: {e}")
        
        return item

