"""
Test data structures for populating the RecordThing database with realistic samples.
"""

from enum import Enum

class Region(str, Enum):
    """Major global regions"""
    EU = "EU"
    US = "US"
    APAC = "APAC"
    LATAM = "LATAM"
    MENA = "MENA"
    AFRICA = "AFRICA"

class Status(str, Enum):
    """Common status values"""
    ACTIVE = "active"
    PENDING = "pending"
    COMPLETED = "completed"
    EXPIRED = "expired"
    CANCELLED = "cancelled"

class Condition(str, Enum):
    """Asset conditions"""
    NEW = "new"
    LIKE_NEW = "like_new"
    USED = "used"
    DAMAGED = "damaged"
    UNKNOWN = "unknown"

THINGS_PRESET_IDS = [
    "2siiVeL3SRmN4zsoVI1FjBlizix",
    "2siiVekqjse9pzmyCzaz2zxFcz1",
    "2siiVfDvsIophC53BzfEskWmXEW",
]

# Use cases with their associated data types
USE_CASES = {
    "home_inventory": {
        "things": ["Electronics", "Furniture", "Appliances", "Tools", "Sports Equipment"],
        "evidence": ["Purchase Receipts", "Warranty Cards", "Photos", "Manuals"],
        "document_types": ["Receipt", "Warranty", "Manual", "Insurance Policy", "Photo"]
    },
    "business_assets": {
        "things": ["Office Equipment", "Vehicles", "IT Hardware", "Furniture", "Tools"],
        "evidence": ["Invoices", "Maintenance Records", "Registration Docs", "Insurance"],
        "document_types": ["Invoice", "Service Record", "Registration", "Insurance", "Lease"]
    },
    "collections": {
        "things": ["Art", "Antiques", "Collectibles", "Books", "Instruments"],
        "evidence": ["Certificates", "Appraisals", "Provenance Docs", "Photos"],
        "document_types": ["Certificate", "Appraisal", "History Record", "Photo", "Insurance"]
    }
}

# Brand data with their product lines
BRANDS = [
    ("Apple", ["iPhone", "MacBook", "iPad", "iMac", "AirPods"]),
    ("Samsung", ["TV", "Refrigerator", "Washer", "Smartphone", "Tablet"]),
    ("IKEA", ["Desk", "Chair", "Shelf", "Bed", "Cabinet"]),
    ("Sony", ["PlayStation", "TV", "Camera", "Headphones", "Speaker"]),
    ("LG", ["TV", "Refrigerator", "Washer", "AC", "Monitor"])
]

# Retailer information
RETAILERS = [
    ("Amazon", "amazon.com", "ASIN"),
    ("Best Buy", "bestbuy.com", "SKU"),
    ("Walmart", "walmart.com", "UPC"),
    ("Target", "target.com", "DPCI"),
    ("Home Depot", "homedepot.com", "SKU")
]

# Document providers and their document types
DOCUMENT_PROVIDERS = [
    ("Insurance Co", ["Policy", "Claim", "Assessment", "Quote"]),
    ("Manufacturer", ["Manual", "Warranty", "Spec Sheet", "Safety Guide"]),
    ("Government", ["Registration", "License", "Permit", "Certificate"]),
    ("Retailer", ["Receipt", "Invoice", "Order Confirmation", "Return Label"]),
    ("Service Provider", ["Service Record", "Maintenance Log", "Repair Quote"])
]

# Relationships between things and evidence
THING_EVIDENCE_TYPES = [
    ("Purchase", ["Receipt", "Invoice", "Order Confirmation", "Packing Slip"]),
    ("Ownership", ["Registration", "Title", "Certificate", "Bill of Sale"]),
    ("Maintenance", ["Service Record", "Repair Invoice", "Maintenance Log"]),
    ("Documentation", ["Manual", "Warranty Card", "Spec Sheet", "Safety Guide"]),
    ("Visual", ["Photo", "Video", "3D Scan", "Diagram"])
]

# Request types and required evidence
REQUEST_TYPES = [
    ("Insurance Claim", ["Photos", "Purchase Proof", "Condition Report", "Police Report"]),
    ("Warranty Service", ["Purchase Date", "Serial Number", "Problem Description", "Photos"]),
    ("Registration", ["Identity Proof", "Purchase Proof", "Address Proof"]),
    ("Appraisal", ["Photos", "History", "Condition Report", "Authenticity Proof"]),
    ("Service Request", ["Warranty Info", "Problem Description", "Purchase Proof"])
]

# Test scenarios for validation
TEST_SCENARIOS = [
    {
        "name": "Complete Home Inventory",
        "description": "Full inventory with all required evidence",
        "things_count": 50,
        "evidence_per_thing": 5,
        "requests": 10
    },
    {
        "name": "Business Asset Tracking",
        "description": "IT equipment and office furniture tracking",
        "things_count": 100,
        "evidence_per_thing": 3,
        "requests": 20
    },
    {
        "name": "Art Collection",
        "description": "High-value items with detailed provenance",
        "things_count": 25,
        "evidence_per_thing": 8,
        "requests": 5
    },
    {
        "name": "Mixed Use Case",
        "description": "Combination of personal and business assets",
        "things_count": 75,
        "evidence_per_thing": 4,
        "requests": 15
    }
]

# Common variations for attributes
VARIATIONS = {
    "regions": [r.value for r in Region],
    "conditions": [c.value for c in Condition],
    "statuses": [s.value for s in Status],
    "priorities": ["High", "Medium", "Low"],
    "currencies": ["USD", "EUR", "GBP", "JPY", "AUD"],
    "languages": ["en", "es", "fr", "de", "ja"]
} 

# TODO fill in database content if empty
DEFAULT_PRODUCT_TYPES = [
    "Electronics",
    "Electronics/Camera",
    "Electronics/Loudspeaker",
    "Electronics/Headphones",
    "Furniture",
    "Furniture/Chair",
    "Furniture/Table",
    "Appliances",
    "Tools",
    "Sports Equipment",
    "Sports/Equipment",
    "Sports/Equipment/Shoes/Football",
    "Sports/Equipment/Golf/Clubs",
    "Art",
    "Antiques",
    "Collectibles",
    "Books",
    "Instruments",
    "Jewelry/Necklace",
    "Jewelry/Wristwatch",
    "Jewelry/Pen/Fountain",
    "Pet",
    "Pet/Dog",
    "Pet/Cat",
    "Room/Livingroom",
    "Room/Bedroom",
    "Transportation",
    "Transportation/Car",
    "Transportation/Bicycle",
]

DEFAULT_DOCUMENT_TYPES = [
    "Document",
    "Receipt",
    "Card",
    "Document/Contract",
    "Document/Insurance",
    "Document/Warranty",
    "Recipt/Payment",
    "Card/Gift",
    "Card/Membership",
    "Card/ID",
]

# Common UI translations for English
DEFAULT_TRANSLATIONS = [
    # General UI elements
    ("en", "ui.add", "Add", "ui"),
    ("en", "ui.edit", "Edit", "ui"),
    ("en", "ui.delete", "Delete", "ui"),
    ("en", "ui.cancel", "Cancel", "ui"),
    ("en", "ui.save", "Save", "ui"),
    ("en", "ui.search", "Search", "ui"),
    ("en", "ui.filter", "Filter", "ui"),
    
    # Navigation
    ("en", "nav.home", "Home", "navigation"),
    ("en", "nav.things", "Things", "navigation"),
    ("en", "nav.evidence", "Evidence", "navigation"),
    ("en", "nav.requests", "Requests", "navigation"),
    ("en", "nav.settings", "Settings", "navigation"),
    
    # Thing-related
    ("en", "thing.add", "Add Thing", "thing"),
    ("en", "thing.edit", "Edit Thing", "thing"),
    ("en", "thing.delete", "Delete Thing", "thing"),
    ("en", "thing.details", "Thing Details", "thing"),
    ("en", "thing.category", "Category", "thing"),
    ("en", "thing.brand", "Brand", "thing"),
    ("en", "thing.model", "Model", "thing"),
    
    # Evidence-related
    ("en", "evidence.add", "Add Evidence", "evidence"),
    ("en", "evidence.edit", "Edit Evidence", "evidence"),
    ("en", "evidence.delete", "Delete Evidence", "evidence"),
    ("en", "evidence.details", "Evidence Details", "evidence"),
    ("en", "evidence.type", "Evidence Type", "evidence"),
    ("en", "evidence.date", "Date", "evidence"),
    
    # Request-related
    ("en", "request.new", "New Request", "request"),
    ("en", "request.edit", "Edit Request", "request"),
    ("en", "request.cancel", "Cancel Request", "request"),
    ("en", "request.status", "Request Status", "request"),
    ("en", "request.type", "Request Type", "request"),
    
    # Messages
    ("en", "msg.confirm_delete", "Are you sure you want to delete this?", "message"),
    ("en", "msg.save_success", "Successfully saved", "message"),
    ("en", "msg.save_error", "Error saving", "message"),
    ("en", "msg.load_error", "Error loading data", "message"),
    
    # Form labels
    ("en", "form.required", "Required", "form"),
    ("en", "form.optional", "Optional", "form"),
    ("en", "form.invalid", "Invalid input", "form"),
    ("en", "form.submit", "Submit", "form")
]
