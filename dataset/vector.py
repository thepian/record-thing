import struct
from typing import List


def serialize_f32(vector: List[float]) -> bytes:
    """serializes a list of floats into a compact "raw bytes" format"""
    return struct.pack("%sf" % len(vector), *vector)

def deserialize_f32(data: bytes) -> List[float]:
    """deserializes a list of floats from a compact "raw bytes" format"""
    return list(struct.unpack("%sf" % (len(data) // 4), data))

