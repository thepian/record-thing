import os
from os.path import dirname
from transformers import AutoImageProcessor, AutoModel

hf_cache_dir = os.path.join(dirname(dirname(__file__)), ".cache", "torch", "hf")
os.makedirs(hf_cache_dir, exist_ok=True)
os.environ['HF_HOME'] = hf_cache_dir

MODEL_NAME = 'facebook/dinov2-base'

processor = AutoImageProcessor.from_pretrained(MODEL_NAME)
model = AutoModel.from_pretrained(MODEL_NAME)

