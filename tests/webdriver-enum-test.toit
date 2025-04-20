// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import simple-config show *

import .webdriver-utils
import .webdriver

main args/List:
  web-driver-main args: (EnumTypeTester it).test

class EnumTypeTester extends TypeTester:
  static ENUM-SCHEMA ::= {
    "title": "Test",
    "description": "different types",
    "type": "object",
    "properties": {
      "prop": {
        "type": "string",
        "title": "Title",
        "description": "Some description",
        "enum": ["option1", "option2", "option3"],
        "default": "option1",
      },
    },
  }

  constructor driver/WebDriver:
    super driver

  schema/Map ::= ENUM-SCHEMA
  default-value ::= "option1"
  cleared-value-saved ::= "option1"
  test-value ::= "option2"
  other-test-value ::= "option3"
  selector -> string: return "select"

  can-clear -> bool: return false
  clear-input input/string -> none: unreachable

  test:
    super
    test-enum-options

  test-enum-options:
    with-config: | config/Config |
      // Test that the select element has the correct options.
      options := driver.find --selector="select option"
      expect-equals 3 options.size
      expect-equals "option1" (driver.get-text options[0])
      expect-equals "option2" (driver.get-text options[1])
      expect-equals "option3" (driver.get-text options[2])
