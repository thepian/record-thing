# Datasets

Training must be done using
- Foundation Models (DINO or SimCLR)
- Publicly available datasets (ImageNet, CIFAR-10, CIFAR-100, etc.)
- Specialised datasets for brands, products, bills
- Personal datasets
- 

We try to avoid the need for large static datasets. The datasets are built ad hoc as needed based on the products that our users actually record.30


Search Kaggle for
- brands
- household items
- products
- cosmetics
- electronics
- 

## Specialised datasets for brands, products, bills

- [Stanford Cars](https://paperswithcode.com/dataset/stanford-cars)
- [Car Brand Images](https://www.kaggle.com/jessicali9530/stanford-cars-dataset)
- [Car Brand Images](https://www.kaggle.com/datasets/yamaerenay/100-images-of-top-50-car-brands)
- [Alibaba Open Brand](https://alibaba.github.io/OpenBrand/) doesn't seem to be available
- 


## Multi-party subject identity voting

Unlabelled images centrally. Are matched with personal images that have more precise labels. Each personal image is a vote on the data for the central image. The central image is labelled with the most votes.

We fetch images from the brand website to suggest as related photos. Ask the user to pick the best related photos.


## Datasette

Consider using [Datasette](https://datasette.io/) to serve the sqlite-vec.

## Vector Searching and Lookup

A core dataset is maintained for identifying images added by users to their personal dataset.
