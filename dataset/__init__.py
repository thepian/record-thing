import pathlib
from datasets import load_dataset, concatenate_datasets

evidentnet_path = pathlib.Path("/Volumes/Datasets/") / "evidentnet"

# data types
categories = [
    "qrcode",
    "barcode",
    "heldobject",
    "fullobject", # fully in view
    "logo",    # logo in the real world
    "idcard",  # id/drivers license/credit card/member card
    "receipt", # smaller bill/payment receipt
    "document", # contract, invoice, etc.

    "other", # no category
]

def get_qrcode_train_dataset():
    qrcodes = load_dataset(str(evidentnet_path / "qrcode"), split="train")
    qrcodes = qrcodes.rename_column("label", "mask")
    qrcodes = qrcodes.add_column("label", ["Barcode"] * len(qrcodes))
    qrcodes = qrcodes.add_column("category", ["qrcode"] * len(qrcodes))
    return qrcodes

def barcode_label_to_category(label: str) -> str:
    """
      class_label:
        names:
          '0': Barcode
          '1': Invoice
          '2': Object
          '3': Receipt
          '4': Non-Object
    """
    if label == "Barcode" or label == 0:
        return "barcode"
    if label == "Invoice" or label == 1:
        return "document"
    if label == "Receipt" or label == 3:
        return "receipt"
    if label == "Object" or label == 2:
        return "fullobject"
    return "other"

def get_barcode_train_dataset():
    barcodes = load_dataset(str(evidentnet_path / "barcode"), split="train")
    categories = [barcode_label_to_category(label) for label in barcodes["label"]]
    barcodes = barcodes.add_column("category", categories)
    barcodes = barcodes.rename_column("pixel_values", "image")
    barcodes = barcodes.add_column("mask", [None] * len(barcodes))
    return barcodes

def get_categories_train_dataset():
    qrcodes = get_qrcode_train_dataset()
    qrcodes = qrcodes.remove_columns(["bbox", "label"])

    barcodes = get_barcode_train_dataset()
    barcodes = barcodes.remove_columns(["ocr", "label"])

    return concatenate_datasets([qrcodes, barcodes])

# see https://huggingface.co/docs/datasets/image_dataset to load your own custom dataset
# dataset = load_dataset("timm/oxford-iiit-pet")
