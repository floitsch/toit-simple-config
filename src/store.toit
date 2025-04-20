// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import system.storage

SIMPLE-CONFIG-KEY ::= "simple-config"

interface Store:
  constructor storage-uri/string:
    return StoreSystem_ storage-uri

  save values/Map -> none
  load -> Map?
  close -> none

class StoreSystem_ implements Store:
  bucket_/storage.Bucket? := ?

  constructor storage-uri/string:
    bucket_ = storage.Bucket.open storage-uri

  save values/Map:
    bucket_[SIMPLE-CONFIG-KEY] = values

  load -> Map?:
    return bucket_.get SIMPLE-CONFIG-KEY

  close:
    if bucket_:
      bucket_.close
      bucket_ = null
