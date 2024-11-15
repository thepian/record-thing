import rdflib
from rdflib import Graph

p = "/Users/henrikvendelbo/Library/Mobile Documents/com~apple~CloudDocs/Downloads/english-wordnet-2023.ttl"
g = Graph()
# g.parse("demo.nt")
g.parse(p)

print(len(g))
print(rdflib.term.Literal('Hello World'))
