// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import host.file
import host.pipe

main args:
  in/string := args[0]

  data := (file.read-contents in).to-string
  data = data.replace --all "\\" "\\\\"
  data = data.replace --all "\$" "\\\$"
  last-separator := max (in.index-of --last "/") (in.index-of --last "\\")
  name := in[last-separator + 1..].replace "." "-"
  name = name.to-ascii-upper
  data = """
  $name ::= \"""
  $data
  \"""
  """
  pipe.stdout.out.write data
