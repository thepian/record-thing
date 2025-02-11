# Gist https://gist.github.com/Keith-Hon/ac0c293e2b105343639d03abf7d77e84

# https://feedarmy.com/kb/google-merchant-taxonomy-list-for-all-countries/

from collections import namedtuple
import requests
en_content = requests.get('https://www.google.com/basepages/producttype/taxonomy-with-ids.en-US.txt')

def load_taxonomy_hierarchy(root, taxonomy_content, is_root):
  lines = taxonomy_content.split('\n')
  filtered_lines = lines[1:]
  filtered_lines = list(filter(lambda line: len(line) > 0, filtered_lines))
  # extract the root taxonomy from content
  root_taxonomy_set = set()
  
  for i, x in enumerate(filtered_lines):
    if(len(x) > 0):
      if(is_root):
        current_taxonomy_code = x.split("-", 1)[0]
        root_taxonomy_set.add(x.split("-", 1).pop().split('>')[0].strip())
      else:
        root_taxonomy_set.add(x.split('>')[0].strip())
  
  root['children'] = list()
  for i, x in enumerate(list(root_taxonomy_set)):
    ele_content_lines = list()
    ele_code = None

    for line in filtered_lines:
      if(is_root):
        root_category = line.split("-", 1).pop().split('>')[0].strip()      
      else:
        root_category = line.split('>')[0].strip()
      
      if x == root_category:
        if(is_root):
          ele_content_lines.append('>'.join(line.split("-", 1).pop().split('>')[1:]))
        else:
          ele_content_lines.append('>'.join(line.split('>')[1:]))    

    ele = {'name': x, 'content': "\n".join(ele_content_lines), 'code': ele_code}
    if is_root:
      ele['parent_name'] = None
    else:
      ele['parent_name'] = root['name']
    load_taxonomy_hierarchy(ele, ele['content'], False)
    root['children'].append(ele)
    
  return root

def lookupCodeByName(name, taxonomy_content):
  lines = taxonomy_content.split('\n')
  filtered_lines = lines[1:]
  filtered_lines = list(filter(lambda line: len(line) > 0, filtered_lines))
  for line in filtered_lines:
    if(line.split('-', 1).pop().strip() == name):
      return line.split('-', 1)[0].strip()
  return None

def lookupAllCodes(hierarchy, prefix):
  children = hierarchy['children']
  hierarchy['content'] = None
  if(len(children) > 0):
    for child in children:
      if prefix != None:
        lookupAllCodes(child, prefix + " > " + child['name'])
        child['code'] = lookupCodeByName(prefix + " > " + child['name'], en_content.text)
      else:
        lookupAllCodes(child, child['name'])
        child['code'] = lookupCodeByName(child['name'], en_content.text)
        


product_type_tuple = namedtuple('product_type', ['lang', 'rootName', 'name', 'url', 'gpcRoot', 'gpcName', 'gpcCode', 'unspscID'])

def gen_from_node(node, base = []):
  base_names = ">".join(base)
  yield product_type_tuple('en', base_names, node['name'], None, base_names, node['name'], int(node['code']), None)
  for child in node['children']:
    yield from gen_from_node(child, base + [node['name']])

def generate_product_type():
  root = {'name': 'root', 'code': None}
  hierarchy = load_taxonomy_hierarchy(root, en_content.text, True)
  lookupAllCodes(hierarchy, None)
  for child in root['children']:
    yield from gen_from_node(child, [])
    