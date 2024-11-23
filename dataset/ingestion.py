# ©2024 Thepia GmbH

import os
import io
from dataset.commons import commons, create_uid
import torch
import hashlib
from transformers import AutoImageProcessor, AutoModel
from PIL import Image
import requests
from .vector import serialize_f32

url = 'http://images.cocodataset.org/val2017/000000039769.jpg'
image = Image.open(requests.get(url, stream=True).raw)

from dinov2_model import hf_cache_dir

processor = AutoImageProcessor.from_pretrained('facebook/dinov2-base')
model = AutoModel.from_pretrained('facebook/dinov2-base')

# create AutoImageProcessor for a specific device:


class Ingestor:
    def __init__(self, cursor, model = model, processor = processor, device = None):
        self.device = device
        self.model = model.to(device) if device else model
        self.processor = processor
        self.cursor = cursor

    def ingest(self, dir = None, url = None, image = None, tags = []):
        if dir:
            self._ingest_dir(dir, tags = tags)
        elif url:
            self._ingest_url(url, tags = tags)
        elif image:
            self._ingest_image(image, tags = tags)

        # embeddings = self.embeddings(url, image)

        # embeddings = torch.mean(embeddings, dim=1)

        # embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)

        # save the embeddings

        # return embeddings

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
        md5 = hashlib.md5(content).hexdigest()

        # does it already exist?
        found = self.cursor.execute("SELECT id FROM clip_assets WHERE md5 = ?", [md5]).fetchone()
        id = None
        if not found:
            id = create_uid()
            self.cursor.execute("INSERT INTO clip_assets(account, id, dino_vec_rowid, name, tags, md5) VALUES (?, ?, ?, ?, ?, ?)", 
                [commons['account_id'], id, None, "clip1", tags_as_text, md5])
        else:
            id = found[0]
            print("already exists,", id)

        print("clip asset id:", id, original_url)

        found = self.cursor.execute("SELECT asset_id FROM dino_embedding WHERE asset_id = ?", [id]).fetchone()
        if not found:
            image = Image.open(io.BytesIO(content))
            embeddings = self.embeddings(image = image).numpy().astype('float32') #np.float32
            print(embeddings.shape)
            self.cursor.execute("INSERT INTO dino_embedding(asset_id, embedding) VALUES (?, ?)", 
                [id, serialize_f32(embeddings)]) # TODO try passing the embeddings directly

# SELECT * from users WHERE column LIKE "%,pineapple,%";

    def features(self, url = None, image = None):
        with torch.inference_mode():
            if url:
                image = Image.open(requests.get(url, stream=True).raw)
            inputs = self.processor(images=image, return_tensors="pt")
            if self.device:
                inputs = inputs.to(self.device)
            outputs = self.model(**inputs)

            return outputs.last_hidden_state

    def embeddings(self, url = None, image = None):
        """
        The features in this case will be a PyTorch tensor of shape (batch_size, num_image_patches, embedding_dim). So one can turn them into a single vector by averaging over the image patches, like so:
        """
        features = self.features(url, image)
        return features.mean(dim=1).squeeze()