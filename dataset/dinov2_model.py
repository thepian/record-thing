"""
MIT Indoor Scenes
Indoor Scene Recognition CVPR
https://csail.mit.edu/research/vision/indoor-scene-recognition

https://www.kaggle.com/datasets/itsahmad/indoor-scenes-cvpr-2019


"""
import os
from os.path import dirname
import torch
# import torchvision.transforms as transforms

hub_cache_dir = os.path.join(dirname(dirname(__file__)), ".cache", "torch", "hub")
os.makedirs(hub_cache_dir, exist_ok=True)

hf_cache_dir = os.path.join(dirname(dirname(__file__)), ".cache", "torch", "hf")
os.makedirs(hf_cache_dir, exist_ok=True)

torch.hub.set_dir(hub_cache_dir)

dinov2_vits14 = torch.hub.load("facebookresearch/dinov2", "dinov2_vits14")

os.environ['HF_HOME'] = hf_cache_dir
