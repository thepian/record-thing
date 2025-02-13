# Bucketh Library

A Bucketh follows a file structure in a Storage Bucket. It defines how a user database used by apps like RecordThing or Evidently can be backed up and restored from a cloud storage bucket.

A bucketh path points to a directory in a cloud storage bucket. The default suffix is `bk`.
Alternately it can be a path to an equivalet zip file with a default suffix of `bkz`.

- SQLite DB with application context and related data
- Raw Recorded Media Files
- Converted Media Files
- Application Resources

Image paths have a root image name and suffix that points to a directory. The original file name begins with original. Alternative formats sizes and variants are stored in the same directory with different names.

