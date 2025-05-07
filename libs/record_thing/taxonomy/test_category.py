import pytest
from .category import (
    generate_document_types,
    generate_evidence_types,
    DocumentType,
    EvidenceType,
)


def test_generate_document_types():
    doc_types = list(generate_document_types())

    # Verify structure
    assert len(doc_types) > 0
    assert all(isinstance(dt, DocumentType) for dt in doc_types)

    # Check hierarchy
    receipts = [dt for dt in doc_types if dt.rootName.startswith("receipt")]
    assert any(dt.name == "Purchase" for dt in receipts)
    assert all(dt.lang == "en" for dt in doc_types)
    assert all(dt.url.startswith("https://") for dt in doc_types)


def test_generate_evidence_types():
    evidence_types = list(generate_evidence_types())

    # Verify structure
    assert len(evidence_types) > 0
    assert all(isinstance(et, EvidenceType) for et in evidence_types)

    # Check base evidence types
    photo = next(et for et in evidence_types if et.name == "Photograph")
    assert photo.gpcCode == 70003
    assert "Digital" in photo.gpcRoot

    # Check document-based evidence types
    doc_evidence = [et for et in evidence_types if et.rootName.startswith("document/")]
    assert len(doc_evidence) > 0
    assert all(et.gpcRoot == "Document" for et in doc_evidence)
    assert all(80000 <= et.gpcCode < 81000 for et in doc_evidence)

    # Check product-based evidence types
    product_evidence = [
        et for et in evidence_types if et.rootName.startswith("product/")
    ]
    assert len(product_evidence) > 0
    assert all(90000 <= et.gpcCode < 91000 for et in product_evidence)
    assert all("/" in et.rootName for et in product_evidence)
