// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import simple-config show *

import .webdriver-utils
import .webdriver

main args/List:
  web-driver-main args: (OneOfTester it).test


class OneOfTester extends Tester:
  static ONEOF-SCHEMA ::= {
    "title": "OneOf Test",
    "description": "Testing oneOf functionality",
    "type": "object",
    "properties": {
      "testOneOf": {
        "type": "object",
        "title": "Test oneOf",
        "description": "Basic oneOf test",
        "properties": {
          "type": {
            "type": "string",
            "enum": ["option1", "option2", "option3"],
            "title": "Type",
            "description": "Select which option to show",
            "default": "option1",
          },
        },
        "oneOf": [
          {
            "properties": {
              "type": {
                "const": "option1",
              },
              "option1Value": {
                "type": "string",
                "title": "Option 1 Value",
                "description": "Value for option 1",
                "default": "default option 1",
              },
            },
          },
          {
            "properties": {
              "type": {
                "const": "option2",
              },
              "option2Value": {
                "type": "number",
                "title": "Option 2 Value",
                "description": "Value for option 2",
                "default": 42.0,
              },
            },
          },
          {
            "properties": {
              "type": {
                "const": "option3",
              },
              "option3Value": {
                "type": "integer",
                "title": "Option 3 Value",
                "description": "Value for option 3",
                "default": 1,
              },
            },
          },
        ],
      },
    },
  }

  static ONEOF-IN-LIST-SCHEMA ::= {
    "title": "OneOf in List Test",
    "description": "Testing oneOf in list functionality",
    "type": "object",
    "properties": {
      "listOfOneOfs": {
        "type": "array",
        "title": "List of OneOfs",
        "description": "Testing oneOf inside a list",
        "items": {
          "type": "object",
          "title": "OneOf Item",
          "properties": {
            "itemType": {
              "type": "string",
              "enum": ["typeA", "typeB"],
              "title": "Item Type",
              "description": "Type of this item",
              "default": "typeA",
            },
          },
          "oneOf": [
            {
              "properties": {
                "itemType": {
                  "const": "typeA",
                },
                "typeAValue": {
                  "type": "string",
                  "title": "Type A Value",
                  "description": "Value for type A",
                  "default": "default A",
                },
              },
            },
            {
              "properties": {
                "itemType": {
                  "const": "typeB",
                },
                "typeBValue": {
                  "type": "number",
                  "title": "Type B Value",
                  "description": "Value for type B",
                  "default": 3.14,
                },
              },
            },
          ],
        },
      },
    },
  }

  static BOOLEAN_ONEOF_SCHEMA ::= {
    "title": "Boolean OneOf Test",
    "description": "Testing oneOf controlled by a boolean",
    "type": "object",
    "properties": {
      "boolOneOf": {
        "type": "object",
        "title": "Boolean oneOf",
        "description": "Test oneOf controlled by a boolean",
        "properties": {
          "isEnabled": {
            "type": "boolean",
            "title": "Is Enabled?",
            "description": "Controls which section is shown",
            "default": false,
          },
        },
        "oneOf": [
          {
            "properties": {
              "isEnabled": {
                "const": true, // Note: JSON boolean true
              },
              "enabledValue": {
                "type": "string",
                "title": "Enabled Value",
                "description": "Value when enabled",
                "default": "I am enabled",
              },
            },
          },
          {
            "properties": {
              "isEnabled": {
                "const": false, // Note: JSON boolean false
              },
              "disabledValue": {
                "type": "integer",
                "title": "Disabled Value",
                "description": "Value when disabled",
                "default": 0,
              },
            },
          },
        ],
      },
    },
  }

  constructor driver/WebDriver:
    super driver

  test -> none:
    test-visibility
    test-default-values
    test-number-types
    test-oneOf-in-list
    test-boolean-oneOf // Add call to the new test

  with-config schema/Map [--init] [block]:
    with-test-config schema --init=init: | config/Config url/string |
      driver.goto url
      block.call config

  test-visibility -> none:
    with-config ONEOF-SCHEMA --init=(: {:}): | config/Config |
      select := driver.find --selector="#testOneOf-type"
      expect-equals 1 select.size

      option1-section := driver.find --selector="#testOneOf-option1-section"
      expect-not option1-section.is-empty
      expect (driver.is-displayed option1-section.first)

      option2-section := driver.find --selector="#testOneOf-option2-section"
      expect-not option2-section.is-empty
      expect-not (driver.is-displayed option2-section.first)

      option3-section := driver.find --selector="#testOneOf-option3-section"
      expect-not option3-section.is-empty
      expect-not (driver.is-displayed option3-section.first)

      // Select option2.
      driver.select select.first "option2"

      // Check that sections visibility has changed.
      expect-not (driver.is-displayed option1-section.first)
      expect (driver.is-displayed option2-section.first)
      expect-not (driver.is-displayed option3-section.first)

      // Select option3.
      driver.select select.first "option3"

      // Check that only option3 section is visible now.
      expect-not (driver.is-displayed option1-section.first)
      expect-not (driver.is-displayed option2-section.first)
      expect (driver.is-displayed option3-section.first)

  test-default-values -> none:
    with-config ONEOF-SCHEMA --init=(: {:}): | config/Config |
      // Don't change anything, just save with default values.
      save

      // Since no changes were made, the saved object is still empty.
      expect-equals 0 config.values.size

      // Change the option1Value.
      option1-input := driver.find --selector="#testOneOf-option1-section input"
      expect-not option1-input.is-empty

      driver.clear option1-input.first
      driver.type option1-input.first "changed"
      save

      // Check that we now have the option1Value in the config.
      expect-equals "changed" config.values["testOneOf"]["option1Value"]
      expect-equals 1 config.values["testOneOf"].size

      // Change to option2 without modifying its value
      select := driver.find --selector="#testOneOf-type"
      driver.select select.first "option2"
      save

      // Check that none of the default values were saved.
      expect-equals "option2" config.values["testOneOf"]["type"]
      print config.values
      // We still have the old option1Value.
      expect-equals "changed" config.values["testOneOf"]["option1Value"]
      expect-not (config.values["testOneOf"].contains "option2Value")
      expect-not (config.values["testOneOf"].contains "option3Value")

  test-number-types -> none:
    with-config ONEOF-SCHEMA --init=(: {:}): | config/Config |
      // Test that option2 (number type) keeps the proper type.
      select := driver.find --selector="#testOneOf-type"
      expect-equals 1 select.size
      driver.select select.first "option2"

      // Set a whole number in the float field.
      number-input := driver.find --selector="#testOneOf-option2-section input"
      driver.clear number-input.first
      driver.type number-input.first "40"
      save

      select = driver.find --selector="#testOneOf-type"

      // Verify it's saved as float despite being a whole number.
      expect-equals 40.0 config.values["testOneOf"]["option2Value"]
      expect config.values["testOneOf"]["option2Value"] is float

      // Test that option3 (integer type) keeps the proper type.
      driver.select select.first "option3"

      // Set a value in the integer field
      int-input := driver.find --selector="#testOneOf-option3-section input"
      driver.clear int-input.first
      driver.type int-input.first "40.5"
      save

      // Verify it's saved as integer
      expect-equals 40 config.values["testOneOf"]["option3Value"]
      expect config.values["testOneOf"]["option3Value"] is int

  test-oneOf-in-list -> none:
    with-config ONEOF-IN-LIST-SCHEMA --init=(: {:}): | config/Config |
      // Add two items to the list.
      add-button := driver.find --selector=".secondary-button"
      driver.click add-button.first
      add-button = driver.find --selector=".secondary-button"
      driver.click add-button.first

      // Find both select elements for item types.
      selects := driver.find --selector="select[id^='listOfOneOfs-'][id\$='-itemType']"
      expect-equals 2 selects.size

      // Keep first as typeA (default), change second to typeB.
      driver.select selects.last "typeB"

      // Find the type A section (first item) and the type B section (second item)
      typeA-section := driver.find --selector="#listOfOneOfs-0-typeA-section"
      expect-equals 1 typeA-section.size
      expect (driver.is-displayed typeA-section.first)

      typeB-section := driver.find --selector="#listOfOneOfs-1-typeB-section"
      expect-equals 1 typeB-section.size
      expect (driver.is-displayed typeB-section.first)

      // Modify values in both types by finding inputs within their sections
      typeA-input := driver.find --selector="#listOfOneOfs-0-typeA-section input"
      expect-equals 1 typeA-input.size
      driver.clear typeA-input.first
      driver.type typeA-input.first "modified A value"

      typeB-input := driver.find --selector="#listOfOneOfs-1-typeB-section input"
      expect-equals 1 typeB-input.size
      driver.clear typeB-input.first
      driver.type typeB-input.first "9.99"

      save

      // Verify the saved values.
      expect-equals 2 config.values["listOfOneOfs"].size

      first-item := config.values["listOfOneOfs"][0]
      expect-equals "typeA" first-item["itemType"]
      expect-equals "modified A value" first-item["typeAValue"]
      expect-not (first-item.contains "typeBValue")

      second-item := config.values["listOfOneOfs"][1]
      expect-equals "typeB" second-item["itemType"]
      expect-equals 9.99 second-item["typeBValue"]
      expect second-item["typeBValue"] is float
      expect-not (second-item.contains "typeAValue")

  test-boolean-oneOf -> none:
    with-config BOOLEAN_ONEOF_SCHEMA --init=(: {:}): | config/Config |
      // Find the boolean toggle switch.
      check-box := driver.find --selector=".toggle-switch input[type='checkbox']"
      click-area := driver.find --selector=".toggle-switch"
      expect-equals 1 check-box.size

      // Find the sections controlled by the boolean.
      true-section := driver.find --selector="#boolOneOf-true-section"
      expect-not true-section.is-empty
      false-section := driver.find --selector="#boolOneOf-false-section"
      expect-not false-section.is-empty

      // Check initial state (default is false).
      expect-not (driver.is-displayed true-section.first)
      expect (driver.is-displayed false-section.first)
      expect (not (driver.get-property check-box.first "checked"))

      // Click the toggle switch (the label) to enable it.
      driver.click click-area.first

      // Check visibility after toggle.
      expect (driver.is-displayed true-section.first)
      expect-not (driver.is-displayed false-section.first)
      expect (driver.get-property check-box.first "checked")

      // Modify the value in the 'true' section.
      enabled-input := driver.find --selector="#boolOneOf-true-section input"
      expect-equals 1 enabled-input.size
      driver.clear enabled-input.first
      driver.type enabled-input.first "Now it is true"

      save

      // Verify saved state.
      expect-equals true config.values["boolOneOf"]["isEnabled"]
      expect-equals "Now it is true" config.values["boolOneOf"]["enabledValue"]
      expect-not (config.values["boolOneOf"].contains "disabledValue")

      // Toggle back to false.
      driver.click click-area.first

      // Check visibility again.
      expect-not (driver.is-displayed true-section.first)
      expect (driver.is-displayed false-section.first)

      // Modify the value in the 'false' section.
      disabled-input := driver.find --selector="#boolOneOf-false-section input"
      expect-equals 1 disabled-input.size
      driver.clear disabled-input.first
      driver.type disabled-input.first "99"

      save

      // Verify saved state.
      expect-equals false config.values["boolOneOf"]["isEnabled"]
      expect-equals 99 config.values["boolOneOf"]["disabledValue"]
      print config.values
      // The old value is still there, but the important part is that the
      // correct value for the current state is saved.
      expect-equals "Now it is true" config.values["boolOneOf"]["enabledValue"]
