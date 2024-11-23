"""
MIT Indoor Scenes
Indoor Scene Recognition CVPR
https://csail.mit.edu/research/vision/indoor-scene-recognition

https://web.mit.edu/torralba/www/indoor.html

https://www.kaggle.com/datasets/itsahmad/indoor-scenes-cvpr-2019


"""
import os
from os.path import dirname
import torch
from roboflow import Roboflow

roboflow_cache_dir = os.path.join(dirname(dirname(__file__)), ".cache", "roboflow")
os.makedirs(roboflow_cache_dir, exist_ok=True)

rf = Roboflow.login()

project = rf.workspace("popular-benchmarks").project("mit-indoor-scene-recognition")
indoor_dataset = project.version(5).download(roboflow_cache_dir)

