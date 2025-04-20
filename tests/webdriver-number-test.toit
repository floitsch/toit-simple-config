// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import simple-config show *

import .webdriver-utils
import .webdriver

main args/List:
  web-driver-main args: (NumberTypeTester it).test

class NumberTypeTester extends TypeTester:
  static NUMBER-SCHEMA ::= {
    "title": "Test",
    "description": "different types",
    "type": "object",
    "properties": {
      "prop": {
        "type": "number",
        "title": "Title",
        "description": "Some description",
        "default": 0.0,
      },
    },
  }

  constructor driver/WebDriver:
    super driver

  schema/Map ::= NUMBER-SCHEMA
  default-value ::= 0.0
  cleared-value-saved ::= 0.0
  test-value ::= 3.14
  other-test-value ::= -2.718
  selector -> string: return "input[type='number']"

  clear-input input/string -> none:
    driver.type input "\uE003" * 50
    driver.type input "\uE017" * 50

  get-value input/string -> any:
    result := driver.get-property input "value"
    if result == "": return ""
    return float.parse result

  set-value input/string value/any -> none:
    driver.type input "$value"

  test:
    super
    test-invalid-input

  test-invalid-input:
    initial := { "prop": test-value }
    with-config --init=(: initial): | config/Config |
      // Test the initial value.
      string-input-value := get-value input
      expect-equals test-value string-input-value

      // Test modifying the string value.
      driver.clear input
      set-value input "not a number"
      save

      // Verify the config object uses the default value.
      expect-equals cleared-value-saved config.values["prop"]

      driver.clear input
      set-value input "42"
      save

      expect-equals 42.0 config.values["prop"]
      expect config.values["prop"] is float

      driver.clear input
      set-value input 42.5
      save

      expect-equals 42.5 config.values["prop"]
      expect config.values["prop"] is float

      driver.clear input
      set-value input 42
      save

      expect-equals 42.0 config.values["prop"]
      expect config.values["prop"] is float

