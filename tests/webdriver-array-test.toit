// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import simple-config show *

import .webdriver-utils
import .webdriver

main args/List:
  web-driver-main args: (ArrayTypeTester it).test

class ArrayTypeTester extends Tester:
  static ARRAY-SCHEMA ::= {
    "title": "Test",
    "description": "different types",
    "type": "object",
    "properties": {
      "prop": {
        "type": "array",
        "title": "Array Test",
        "description": "Testing array functionality",
        "items": {
          "type": "string",
          "title": "Item",
          "description": "An array item"
        }
      },
    },
  }

  static ARRAY-MIN-MAX-SCHEMA ::= {
    "title": "Test",
    "description": "different types",
    "type": "object",
    "properties": {
      "prop": {
        "type": "array",
        "title": "Array Test",
        "description": "Testing array functionality with min/max",
        "minItems": 1,
        "maxItems": 3,
        "items": {
          "type": "string",
          "title": "Item",
          "description": "An array item"
        }
      },
    },
  }

  constructor driver/WebDriver:
    super driver

  test -> none:
    test-basics
    test-add-remove-items
    test-with-min-max

  with-config [block]:
    with-config --init=(: {:}) block

  with-config [--init] [block]:
    with-test-config ARRAY-SCHEMA --init=init: | config/Config url/string |
      driver.goto url
      block.call config

  with-min-max-config [--init] [block]:
    with-test-config ARRAY-MIN-MAX-SCHEMA --init=init: | config/Config url/string |
      driver.goto url
      block.call config

  test-basics -> none:
    with-config: | config/Config |
      // Test that the list container is shown.
      list-containers := driver.find --selector=".list-container"
      expect-not list-containers.is-empty

      // Test that the list title displays correctly.
      title-elements := driver.find --selector=".list-title"
      expect-not title-elements.is-empty
      title-text := driver.get-text title-elements.first
      expect-equals "Array Test" title-text

      // Test that the description is shown.
      description-elements := driver.find --selector=".list-description"
      expect-not description-elements.is-empty
      description-text := driver.get-text description-elements.first
      expect-equals "Testing array functionality" description-text

      // Test that the list is initially empty.
      list-items := driver.find --selector=".list-item"
      expect list-items.is-empty

      // Test that there's an Add button.
      add-buttons := driver.find --selector=".secondary-button"
      expect-not add-buttons.is-empty
      add-button-text := driver.get-text add-buttons.first
      expect-equals "Add Item" add-button-text

  test-add-remove-items -> none:
    with-config: | config/Config |
      // Find and click the Add button to add an item.
      add-buttons := driver.find --selector=".secondary-button"
      expect-not add-buttons.is-empty
      driver.click add-buttons.first

      // Verify an item was added.
      list-items := driver.find --selector=".list-item"
      expect-not list-items.is-empty
      expect-equals 1 list-items.size

      // Add value to the item.
      input := (driver.find --selector="input[type='text']").first
      driver.type input "test item 1"

      // Save and verify.
      save

      // Check that value was saved in the config.
      expect-equals ["test item 1"] config.values["prop"]

      // Add another item
      add-buttons = driver.find --selector=".secondary-button"
      driver.click add-buttons.first

      // Set value for the second item
      inputs := driver.find --selector="input[type='text']"
      expect-equals 2 inputs.size
      driver.type inputs.last "test item 2"

      // Save and verify.
      save

      // Check that both values are in the config.
      expect-equals ["test item 1", "test item 2"] config.values["prop"]

      // Remove the first item.
      delete-buttons := driver.find --selector=".delete-button"
      expect-equals 2 delete-buttons.size
      driver.click delete-buttons.first

      // Check that the item was removed from the UI.
      list-items = driver.find --selector=".list-item"
      expect-equals 1 list-items.size

      // Save and verify.
      save

      // Check that only the second item remains in the config.
      expect-equals ["test item 2"] config.values["prop"]

  test-with-min-max -> none:
    with-min-max-config --init=(: { "prop": ["default item"] }): | config/Config |
      // Verify we start with one item.
      list-items := driver.find --selector=".list-item"
      expect-not list-items.is-empty
      expect-equals 1 list-items.size

      // Add two more items to reach maxItems=3.
      add-buttons := driver.find --selector=".secondary-button"
      expect-not add-buttons.is-empty
      driver.click add-buttons.first
      add-buttons = driver.find --selector=".secondary-button"
      driver.click add-buttons.first

      // Check that we now have 3 items.
      list-items = driver.find --selector=".list-item"
      expect-equals 3 list-items.size

      // Check that the Add button is now gone (reached maxItems=3).
      add-buttons = driver.find --selector=".secondary-button"
      expect add-buttons.is-empty

      // Try to remove an item.
      delete-buttons := driver.find --selector=".delete-button"
      driver.click delete-buttons.first

      // Check that we now have 2 items.
      list-items = driver.find --selector=".list-item"
      expect-equals 2 list-items.size

      // Save and check config.
      save

      // Check that the config has the right number of items.
      expect-equals 2 config.values["prop"].size

      // Try to delete the last item too, which should be prevented due to minItems=1.
      delete-buttons = driver.find --selector=".delete-button"
      driver.click delete-buttons.first

      // We should still have 1 item.
      list-items = driver.find --selector=".list-item"
      expect-equals 1 list-items.size

      // And the delete button should be gone.
      delete-buttons = driver.find --selector=".delete-button"
      expect delete-buttons.is-empty
