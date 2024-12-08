# ©2024 Thepia GmbH

from typing import Optional, List, Annotated
import os
import io
from dataset.commons import commons, create_uid
import torch
import hashlib
from transformers import AutoImageProcessor, AutoModel
from PIL import Image, UnidentifiedImageError
import requests
from .vector import serialize_f32

# from sqlmodel import Field, SQLModel, Relationship, Column, JSON, Binary
# from datetime import date, datetime
# from pydantic import validator, BaseModel
# from torchvision import transforms


url = 'http://images.cocodataset.org/val2017/000000039769.jpg'
image = Image.open(requests.get(url, stream=True).raw)

from .models.dinov2_model import hf_cache_dir

processor = AutoImageProcessor.from_pretrained('facebook/dinov2-base')
model = AutoModel.from_pretrained('facebook/dinov2-base')

# create AutoImageProcessor for a specific device:

class ImageAssetDescription:
    def __init__(self, url: str = None, image: Image = None):
        self.url = url
        self.image = image
        self.status_code = None
        self.sha1 = None
        self.embedding = None

    def __repr__(self):
        return f"ImageAssetDescription(url={self.url}, image={repr(self.image)})"
    
    def download(self):
        # response = requests.get(self.url, stream=True)
        # self.image = Image.open(response.raw)

        try:
            # response = requests.get(self.url, stream=True)
            # image = Image.open(response.raw)
            # sha1 = compute_sha1_from_raw(response.raw)
            r = requests.get(self.url)
            self.status_code = r.status_code
            if self.status_code == 200:
                self.image = Image.open(io.BytesIO(r.content))
                self.sha1 = hashlib.sha1(r.content).hexdigest()
        except UnidentifiedImageError as ex:
            print("UnidentifiedImageError", ex, self.url)
            self.ex = ex


        # TODO embedding, sha1


def compute_sha1_from_raw(raw_stream):
    sha1_hash = hashlib.sha1()
    
    # Read the raw stream in chunks
    chunk = raw_stream.read(8192)
    while chunk:
        sha1_hash.update(chunk)
        chunk = raw_stream.read(8192)
    
    return sha1_hash.hexdigest()


class Ingestor:
    def __init__(self, cursor, model = model, processor: AutoImageProcessor = processor, device: torch.device = None):
        self.device = device
        self.model = model.to(device) if device else model
        self.processor = processor
        self.cursor = cursor

    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_value, traceback):
        self.close()
        
    def ingest(self, dir = None, url = None, image = None, tags = []):
        if dir:
            self._ingest_dir(dir, tags = tags)
        elif url:
            self._ingest_url(url, tags = tags)
        elif image:
            self._ingest_image(image, tags = tags)

        # embedding = self.embedding(url, image)

        # embedding = torch.mean(embedding, dim=1)

        # embedding = torch.nn.functional.normalize(embedding, p=2, dim=1)

        # save the embedding

        # return embedding

    def _ingest_dir(self, dir, tags):
        for file_name in os.listdir(dir):   
            file_path = os.path.join(dir, file_name)
            with open(file_path, 'rb') as f:
                content: bytes = f.read()
                self._ingest_image(content, tags, original_url= f"file://{file_path}")

    def _ingest_url(self, url, tags):
        file = requests.get(url, stream=True).raw
        image = Image.open(file)
        self._ingest_image(image, tags)

    def _ingest_image(self, content, tags, original_url = None):
        tags_as_text = f",{','.join(tags)},"
        sha1 = hashlib.sha1(content).hexdigest()

        # does it already exist?
        found = self.cursor.execute("SELECT id FROM clip_assets WHERE sha1 = ?", [sha1]).fetchone()
        id = None
        if not found:
            id = create_uid()
            self.cursor.execute("INSERT INTO clip_assets(account, id, dino_vec_rowid, name, tags, sha1) VALUES (?, ?, ?, ?, ?, ?)", 
                [commons['account_id'], id, None, "clip1", tags_as_text, sha1])
        else:
            id = found[0]
            print("already exists,", id)

        print("clip asset id:", id, original_url)

        found = self.cursor.execute("SELECT asset_id FROM dino_embedding WHERE asset_id = ?", [id]).fetchone()
        if not found:
            image = Image.open(io.BytesIO(content))
            embedding = self.embedding(image = image).numpy().astype('float32') #np.float32
            print(embedding.shape)
            self.cursor.execute("INSERT INTO dino_embedding(asset_id, embedding) VALUES (?, ?)", 
                [id, serialize_f32(embedding)]) # TODO try passing the embedding directly

# SELECT * from users WHERE column LIKE "%,pineapple,%";

    def features(self, image):
        with torch.inference_mode():
            inputs = self.processor(images=image, return_tensors="pt")
            if self.device:
                inputs = inputs.to(self.device)
            outputs = self.model(**inputs)

            return outputs.last_hidden_state

    def embedding(self, url = None, image = None):
        """
        The features in this case will be a PyTorch tensor of shape (batch_size, num_image_patches, embedding_dim). So one can turn them into a single vector by averaging over the image patches, like so:
        """
        asset = self.product_image(url, image)
        return asset.embedding
    
    def product_image(self, url = None, image = None):
        """
        The features in this case will be a PyTorch tensor of shape (batch_size, num_image_patches, embedding_dim). So one can turn them into a single vector by averaging over the image patches, like so:
        """
        asset = ImageAssetDescription(url, image)
        asset.download()
        if asset.image is not None:
            features = self.features(image=asset.image)
            embedding = features.mean(dim=1).squeeze() if features is not None else None
            asset.embedding = embedding
            # TODO sha1
            return asset

        return asset
    
    def close(self):
        """
        from contextlib import closing
        with closing(Ingestor(cursor)) as ingestor:
            ingestor.ingest(url = url)
        """
        self.cursor.close()
        self.cursor = None
