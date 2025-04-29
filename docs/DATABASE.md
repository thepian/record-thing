# Database

The database contains the following tables:

|---------------|------------------------------|
| Table         | Description                  |
|===============|==============================|
| Universe      | Each is defined by a downloading a ZIP file that contains a description and assets. It describes a complete set of functionality for the App.              |
| Things        | Things belonging to the user. It has been identified by the user by scanning and recording. |
| Evidence      | Evidence is a set of records that are evidence of the thing. |
| Requests      | Requests are a set of Evidence Gathering actions that the user is asked to complete. |
| Accounts      | Accounts are the users of the RecordThing App. RecordThing App has a single account. |
| Owners        | Owners are the owners of the things. |
| ProductType   | Global product types with common identifiers and iconic images.                 |
| DocumentType  | Global document types with common identifiers and iconic images.                 |
|===============|==============================|

The database is a SQLite database, created by running(in order):

* `libs/record_thing/db/account.sql`
* `libs/record_thing/db/evidence.sql`
* `libs/record_thing/db/assets.sql`
* `libs/record_thing/db/auth.sql`
* `libs/record_thing/db/product.sql`
* `libs/record_thing/db/agreements.sql`
* `libs/record_thing/db/translations.sql`

One file is skipped for now as it breaks Blackbird support.

* `libs/record_thing/db/vector.sql`


## Account (accounts)

The RecordThing App will be tied to a single account at a time. Servers can work across accounts. The owners table points to the active account on the Phone.

### Team

The team is define by the account information

- Team name
- Team DB URL
- Team Primary Bucket URL
- Team Fallback Bucket URL
- Team invite token
- Team access token

The user can backup the local SQLite DB to the Team Buckets.
The user can reset the local SQLite DB to a state saved/published on the Team Buckets.
The user can sync certain content in the local SQLite DB with the Team Postgres DB Server.
The user can sync recording files with the Team Buckets(per user home folder)

A demo team is created with generated Sample recordings and Belongings.


## Feed

The Feed is a table that contains the user's feed. It is used to show the main feed for a user in the app. A feed entry can be a Thing, a Request, an Agreement, an Event, a single piece of evidence, or a Chat.

## Universe

Each universe is defined by a downloading a ZIP file that contains a description and assets. It describes a complete set of functionality for the App.

Universes are remote sources of MLPrograms, Processes and Configuration. They are identified by a URL and points to a ZIP file. It has fields for URL, name, description, isDownloaded, enabledMenus, enabledFeatures, flags.

The URL field is unique per record.
The Primary Key is a locally generated integer.

## Products

Products in the world are identified by a ProductType and a Brand. The cannonical descriptions is constructed by a node in the network. Descriptions are compared by text embedding to merge duplicate products. A central product database is maintained and replicated among users based on their reference from things.

A thing might be constructed and be tied to a product later.
The product might be constructed based on the first piece of evidence after which the thing is created.
Products have a canonical URL for the official product website, support website, Canonical Wikipedia page, Wikidata page.


## Brands

Brands are the manufacturers of products. They are identified by a name and an iconic image.
The website of the brand is a URL with a DNS domain that has been verified to belong to the correct company.
The record can hold contact information, support information, legal status, etc.
Brands can be grouped under a common name by a parent_brand_id.
The brand description is a text field that can be used to store information about the brand. The description is used to merge duplicate brand records.
Brands have canonical URLs for official brand websites, support website, Canonical Wikipedia page, Wikidata page, isni code.


## Things

Things belonging to the user. It has been identified by the user by scanning and recording. They tend to be luxury goods or high status belongings that the user wants to keep track of for insurance purposes.
Multiple records can be made for the same thing.
The owner of the thing is identified by the account_id.

The Things Primary Key is the account_id plus a locally generated text id(KSUID)

## Evidence

Evidence is a set of records that are evidence of the thing or event.
Evidence will often relate to a thing.
Evidence can relate to a request.
Evidence can relate to an event.

## Requests

Requests are a set of Evidence Gathering actions that the user is asked to complete.

A request can be sent by another user or registered 3rd party. It can be sent as a card or link in a message or e-mail.
The link points to a custom state in the RecordThing App. The RecordThing App translates this to a Universe like URL.
It works like a Universe with refinements. The outcome of the request is a set of Evidence, which is wrapped up and sent as an e-mail or HTTP POST.

The URL field is unique per record.
The Requests Primary Key is a locally generated integer.

## Agreements

Agreements are rights and obligations the user is involved in. It can be insurance, lease, purchase, etc. They will be valid for a period of time, and have renewal dates.

## Accounts, Owners, Passkey_credentials

Accounts are the users of the RecordThing App. The database used by the RecordThing App has a single account.

The Accounts Primary Key(id) is a locally generated text KSUID

The Owners Primary Key(account_id) is a locally generated text KSUID

The Passkey_credentials Primary Key is a locally generated text KSUID

## ProductType

Global product types with common identifiers and iconic images.
ProductTypes are categories of objects identified by various naming conventions. They are tied to individual images.

## DocumentType

Global document types with common identifiers and iconic images.
DocumentTypes are categories of documents identified by various naming conventions. They are tied to individual images.

## Translations

I would like to extend the translations in a SwiftUI application by loading them from a SQLite table. The database(record-thing.sqlite) is stored in the App Documents folder. If no database is found a default image is copied from the App Resources. How do I do it so the application loads fast and translations are applied to all translated texts in the application. I want to use the text localisation built into SwiftUI labels. Use Blackbird to access the SQLite Database.


## Image Asset

`libs/record_thing/db/assets.sql` contains the image assets for the application. Small versions of the images are stored in a SQLite database. The images are stored in a table with a unique path and a binary iconic_png blob. The images are loaded from the database and displayed in the application. The original image is saved in the Apps documents directory and in the associated remote Bucket.
`alt_url` and `original_url` are used to manage where to download originals missing from the local cache, and where to find the original locally. Columns sha1/md5 save hashes for the original.


# Collecting brands

The brands are collected from Wikidata. The script is in `libs/record_thing/db/collect_brands.py`.

Added multiple entity types:
Q431289 (brand)
Q167270 (trademark)
Q4830453 (business with industry)
Q2088357 (retail chain)
2. Reduced statement count filter from 10 to 5
Used UNION to combine different types
Maintained all existing property fetching
This should capture:
Traditional brands
Registered trademarks
Notable businesses
Retail chains
More niche or regional brands



# Generating examples

Add brand lists in addition to types for brand names that produce  the types of products

Add 10 showcase product examples to each group with name, product description, designed year, product shot description (pose, background, subject, style)


# Generating examples

Add 10 showcase product examples to each group with name, product description, designed year, product shot description (pose, background, subject, style)

I'll help add showcase examples for each category. Let's start with watches and cameras as examples:
documentation

Add showcase product examples to watches with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to cameras with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to musical instruments with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to art with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to collectibles with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to fine jewelry with name, product description, designed year, product shot description (pose, background, subject, style)

Add showcase product examples to vehicles with name, product description, designed year, product shot description (pose, background, subject, style)

TODO the rest...

