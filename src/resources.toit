// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import io

import .html.config-js
import .html.index-html
import .html.styles-css

interface Resources:
  constructor: return ResourcesPkg_

  index -> io.Data
  config-js -> io.Data
  styles-css -> io.Data

  close -> none

class ResourcesPkg_ implements Resources:
  index -> string: return INDEX-HTML
  config-js -> string: return CONFIG-JS
  styles-css -> string: return STYLES-CSS

  close -> none:  /* Do nothing. */
