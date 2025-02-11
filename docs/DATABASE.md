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

* `dataset/db/account.sql`
* `dataset/db/evidence.sql`
* `dataset/db/assets.sql`
* `dataset/db/auth.sql`

## Universe

Each universe is defined by a downloading a ZIP file that contains a description and assets. It describes a complete set of functionality for the App.

Universes are remote sources of MLPrograms, Processes and Configuration. They are identified by a URL and points to a ZIP file. It has fields for URL, name, description, isDownloaded, enabledMenus, enabledFeatures, flags.

The URL field is unique per record.
The Primary Key is a locally generated integer.


## Things

Things belonging to the user. It has been identified by the user by scanning and recording.
Multiple records can be made for the same thing.
The owner of the thing is identified by the account_id.

The Things Primary Key is the account_id plus a locally generated text id(KSUID)


## Evidence

Evidence is a set of records that are evidence of the thing.
Evidence will often relate to a thing.
Evidence can relate to a request.





## Requests

Requests are a set of Evidence Gathering actions that the user is asked to complete.

A request can be sent by another user or registered 3rd party. It can be sent as a card or link in a message or e-mail.
The link points to a custom state in the RecordThing App. The RecordThing App translates this to a Universe like URL.
It works like a Universe with refinements. The outcome of the request is a set of Evidence, which is wrapped up and sent as an e-mail or HTTP POST.

The URL field is unique per record.
The Requests Primary Key is a locally generated integer.


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


