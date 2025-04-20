// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import .webdriver-utils
import .webdriver

main args/List:
  web-driver-main args: (BooleanTypeTester it).test

class BooleanTypeTester extends TypeTester:
  static BOOLEAN-SCHEMA ::= {
    "title": "Test",
    "description": "different types",
    "type": "object",
    "properties": {
      "prop": {
        "type": "boolean",
        "title": "Title",
        "description": "Some description",
        "default": false,
      },
    },
  }

  constructor driver/WebDriver:
    super driver

  schema/Map ::= BOOLEAN-SCHEMA
  default-value ::= false
  cleared-value-saved ::= false
  test-value ::= true
  other-test-value ::= false
  selector -> string: return ".toggle-switch input[type='checkbox']"

  clear-input input/string -> none:
    set-value input false

  get-value input/string -> any:
    result := driver.get-property input "checked"
    return result

  set-value input/string value/any -> none:
    current := get-value input
    if current != value:
      element := (driver.find --selector=".toggle-switch").first
      driver.click element

