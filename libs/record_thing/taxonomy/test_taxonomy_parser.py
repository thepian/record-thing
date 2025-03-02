import pytest
from unittest.mock import patch
from .category import (
    load_taxonomy_hierarchy,
    lookupCodeByName,
    lookupAllCodes,
    generate_product_type
)

# Sample taxonomy data for testing
SAMPLE_TAXONOMY = """# Google Shopping Category Taxonomy
1 - Animals & Pet Supplies
2 - Animals & Pet Supplies > Pet Supplies
3 - Animals & Pet Supplies > Pet Supplies > Bird Supplies
3001 - Apparel & Accessories
3002 - Apparel & Accessories > Clothing
3003 - Apparel & Accessories > Clothing > Activewear
"""

@pytest.fixture
def mock_taxonomy_response():
    with patch('requests.get') as mock_get:
        mock_get.return_value.text = SAMPLE_TAXONOMY
        yield mock_get

def test_load_taxonomy_hierarchy():
    root = {'name': 'root', 'code': None}
    hierarchy = load_taxonomy_hierarchy(root, SAMPLE_TAXONOMY, True)
    
    # Verify root level categories
    assert len(hierarchy['children']) == 2
    categories = [child['name'] for child in hierarchy['children']]
    assert 'Animals & Pet Supplies' in categories
    assert 'Apparel & Accessories' in categories
    
    # Verify nested structure
    pets = next(c for c in hierarchy['children'] if c['name'] == 'Animals & Pet Supplies')
    assert len(pets['children']) == 1
    assert pets['children'][0]['name'] == 'Pet Supplies'
    assert pets['children'][0]['children'][0]['name'] == 'Bird Supplies'

def test_lookup_code_by_name():
    code = lookupCodeByName('Animals & Pet Supplies', SAMPLE_TAXONOMY)
    assert code == '1'
    
    code = lookupCodeByName('Apparel & Accessories > Clothing > Activewear', SAMPLE_TAXONOMY)
    assert code == '3003'

def test_generate_product_type(mock_taxonomy_response):
    product_types = list(generate_product_type())
    
    # Verify structure of generated product types
    assert len(product_types) > 0
    sample_type = product_types[0]
    assert sample_type.lang == 'en'
    assert sample_type.gpcCode is not None
    assert isinstance(sample_type.gpcCode, int)
    
    # Verify hierarchy is preserved in names
    activewear = next(pt for pt in product_types 
                     if pt.name == 'Activewear' and 'Clothing' in pt.rootName)
    assert 'Apparel & Accessories > Clothing' in activewear.rootName

def test_lookup_all_codes():
    root = {'name': 'root', 'code': None, 'children': [
        {'name': 'Animals & Pet Supplies', 'code': None, 'children': []}
    ]}
    with patch('requests.get') as mock_get:
        mock_get.return_value.text = SAMPLE_TAXONOMY
        lookupAllCodes(root, None)
        assert root['children'][0]['code'] == '1' 