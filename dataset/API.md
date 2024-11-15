# API

The client App captures clips of Objects owned by the user. It collects metadata about the objects.
The clips are organised in a personal dataset(ownership graph) on the device. 
The metadata is stored in a sqlite database.

The server is used to help refine the metadata. To correct errors based on a central knowledge base.
The central knowledge base is extended by querying the Web for additional information based on the objects owned by users.

Process:
1. User Captures a clip
2. User adds a description
3. The phone computes one or more embeddings for the clip
4. The server is queried with the embeddings and descriptions to refine the metadata.


### Get Embedding for image

The server provides a hosted version of the DINOv2 model. For privacy reasons this request is not made in production,
but instead done locally on the device.

Input: A captured image 
Output: A vector embedding for the image

Using DINOv2 an embedding is produced. The embedding is stored in a sqlite-vec database locally on the requesting device.

### Refine subject

A subject description is sent to the server and returned with additional information.

Input: A subject dictionary
Output: A refined subject dictionary


```
{
    "dino_embedding": "torch vector",
    "dbid": "database identifier",
    "uid": "unique identifier",
    "description": "subject description",
    "vendor": "vendor name",
    "brand": "brand name",
    "product": "product name",
    "tags": ["tag1", "tag2", "tag3"],
    "model": "model name",
    "year": "year of manufacture",
    "list_price": "price",
    "url": "url to product page",
    "owner": "user identifier",
    "created": "date created",
    "updated": "date updated",
    "personal_conviction": {
        "vendor": 1,
        "brand": 0.8,
        "year": 0.3,
    },
    "server_suggestions": {
        "vendor": "vendor name",
        "brand": "brand name"
    },
    "server_conviction": {
        "vendor": 0.9,
        "brand": 0.7
    }

}
```

### Example

Given the App requesting

{
    "dino_embedding": "torch vector",
    "dbid": "database identifier",
    "description": "My new car outside the house",
    "created": "202410100100"
}

the server might respond with

{
    "dino_embedding": "torch vector",
    "dbid": "database identifier",
    "uid": "unique identifier",
    "description": "My new car outside the house",
    "server_suggestions": {
        "vendor": "AUDI",
        "brand": "AUDI",
        "product": "AUDI A4",
        "model": "A4",
        "year": "2023",
        "list_price": "50000",
        "url": "https://audi.com/a4"
    },
    "server_conviction": {
        "vendor": 0.9,
        "brand": 0.7
    }

}
