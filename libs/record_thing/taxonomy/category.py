from collections import namedtuple
from typing import Generator
from .google_product import GoogleProductTaxonomyManager
from ..db.test_data import DOCUMENT_PROVIDERS
from ..commons import commons

# Define namedtuples for each category type
BaseType = namedtuple('BaseType', ['lang', 'rootName', 'name', 'url'])
ProductType = namedtuple('ProductType', BaseType._fields + ('gpcRoot', 'gpcName', 'gpcCode', 'unspscID'))
DocumentType = namedtuple('DocumentType', BaseType._fields)
EvidenceType = namedtuple('EvidenceType', BaseType._fields + ('gpcRoot', 'gpcName', 'gpcCode', 'unspscID'))

# Sample document types with hierarchy
DOCUMENT_HIERARCHY = {
    "Receipt": ["Purchase", "Payment", "Refund"],
    "Document": ["Contract", "Insurance", "Warranty", "Manual"],
    "Card": ["Gift", "Membership", "ID", "Credit"],
    "Certificate": ["Authenticity", "Ownership", "Insurance"],
    "Image": ["Photo", "Scan", "Screenshot"],
    "Report": ["Appraisal", "Inspection", "Assessment"]
}

# Sample evidence types with hierarchy and GPC codes
EVIDENCE_TYPES = [
    ("Physical", "Original Item", 70001),
    ("Physical/Documentation", "Original Document", 70002),
    ("Digital/Image", "Photograph", 70003),
    ("Digital/Document", "Scanned Document", 70004),
    ("Digital/Media", "Video Recording", 70005),
    ("Digital/Model", "3D Scan", 70006),
]

def generate_document_types() -> Generator[DocumentType, None, None]:
    """Generate document type entries with hierarchy."""
    for category, subtypes in DOCUMENT_HIERARCHY.items():
        # Generate root category
        yield DocumentType(
            lang='en',
            rootName=category.lower(),
            name=category,
            url=f"https://example.com/documents/{category.lower()}"
        )
        
        # Generate subtypes
        for subtype in subtypes:
            yield DocumentType(
                lang='en',
                rootName=f"{category.lower()}/{subtype.lower()}",
                name=subtype,
                url=f"https://example.com/documents/{category.lower()}/{subtype.lower()}"
            )

def generate_evidence_types() -> Generator[EvidenceType, None, None]:
    """
    Generate evidence type entries combining product and document types.
    Uses Google Product Taxonomy and document types from test data.
    """
    # Add document-based evidence types
    for provider, doc_types in DOCUMENT_PROVIDERS:
        for doc_type in doc_types:
            root_name = f"document/{provider.lower()}"
            yield EvidenceType(
                lang='en',
                rootName=f"{root_name}/{doc_type.lower()}",
                name=f"{provider} {doc_type}",
                url=f"https://example.com/evidence/document/{provider.lower()}/{doc_type.lower()}",
                gpcRoot="Document",
                gpcName=doc_type,
                gpcCode=80000 + hash(f"{provider}_{doc_type}") % 1000,  # Generate stable code
                unspscID=None
            )

    # Add product-based evidence types
    taxonomy_manager = GoogleProductTaxonomyManager(commons['account_id'])
    taxonomy_manager.update_taxonomy()
    categories = taxonomy_manager.categories_list[:100]  # Limit to first 100 for practical purposes

    for category in categories:
        root_name = category['parent_path']
        name = category['name']
        yield EvidenceType(
            lang='en',
            rootName=root_name,
            name=name,
            url=f"https://example.com/evidence/product/{name}/{category['hash']}",
            gpcRoot=root_name,
            gpcName=name,
            gpcCode=90000 + category['idx'] % 1000,  # Generate stable code
            unspscID=None
        )


product_type_tuple = namedtuple('product_type', ['lang', 'rootName', 'name', 'url', 'gpcRoot', 'gpcName', 'gpcCode', 'unspscID'])

def gen_from_node(node, base = []):
    base_names = ">".join(base)
    yield product_type_tuple('en', base_names, node['name'], None, base_names, node['name'], int(node['code']), None)
    for child in node['children']:
        yield from gen_from_node(child, base + [node['name']])

