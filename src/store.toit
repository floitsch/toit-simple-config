// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import system.storage

SIMPLE-CONFIG-KEY ::= "simple-config"

interface Store:
  constructor.ram storage-path/string:
    return StoreRam_ storage-path

  save values/Map -> none
  load -> Map?
  close -> none

class StoreRam_ implements Store:
  bucket_/storage.Bucket? := ?

  constructor storage-path/string:
    bucket_ = storage.Bucket.open --ram storage-path

  save values/Map:
    bucket_[SIMPLE-CONFIG-KEY] = values

  load -> Map?:
    return bucket_.get SIMPLE-CONFIG-KEY

  close:
    if bucket_:
      bucket_.close
      bucket_ = null
