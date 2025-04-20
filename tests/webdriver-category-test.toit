// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import simple-config show *

import .webdriver-utils
import .webdriver

main args/List:
  web-driver-main args: (CategoryTester it).test

class CategoryTester extends Tester:
  static CATEGORY-SCHEMA ::= {
    "title": "Category Test",
    "description": "Testing category functionality",
    "type": "object",
    "properties": {
      "category1": {
        "type": "object",
        "title": "Category 1",
        "description": "First category",
        "folded": true,
        "properties": {
          "prop1": {
            "type": "string",
            "title": "Property 1",
            "description": "A property in category 1",
            "default": "default value 1",
          },
          "category2": {
            "type": "object",
            "title": "Category 2",
            "description": "Nested category",
            "folded": false,
            "properties": {
              "prop2": {
                "type": "string",
                "title": "Property 2",
                "description": "A property in category 2",
                "default": "default value 2",
              },
            },
          },
        },
      },
    },
  }

  constructor driver/WebDriver:
    super driver

  test -> none:
    test-folded-property
    test-fold-unfold
    test-nested-categories
    test-fold-state-persists-after-save

  with-config [block]:
    with-config --init=(: {:}) block

  with-config [--init] [block]:
    with-test-config CATEGORY-SCHEMA --init=init: | config/Config url/string |
      driver.goto url
      block.call config

  is-folded category/string -> bool:
    category-contents := driver.find --selector="#$category .category-content"
    expect-not category-contents.is-empty
    category-content := category-contents.first
    style := driver.get-attribute category-content "style"
    return style.contains "none"

  toggle-fold category/string -> none:
    category-header := driver.find --selector="#$category .category-header"
    driver.click category-header.first

  is-displayed category/string -> bool:
    category-content := driver.find --selector="#$category .category-content"
    return driver.is-displayed category-content.first

  test-folded-property -> none:
    with-config: | config/Config |
      // Test that the first category is folded by default.
      expect (is-folded "category1")

      expect-not (is-displayed "category1-category2")
      // Test that the nested category is not folded by default.
      expect-not (is-folded "category1-category2")

  test-fold-unfold -> none:
    with-config: | config/Config |
      // Test folding and unfolding the first category.
      expect (is-folded "category1")
      toggle-fold "category1"
      expect-not (is-folded "category1")
      toggle-fold "category1"
      expect (is-folded "category1")

  test-nested-categories -> none:
    with-config: | config/Config |
      toggle-fold "category1"

      // Test that the nested category is shown correctly.
      category2-content := driver.find --selector="#category1-category2 .category-content"
      expect-not category2-content.is-empty

      // Test folding and unfolding the nested category.
      expect-not (is-folded "category1-category2")
      expect (is-displayed "category1-category2")
      toggle-fold "category1-category2"
      expect (is-folded "category1-category2")
      expect-not (is-displayed "category1-category2")
      toggle-fold "category1-category2"
      expect-not (is-folded "category1-category2")
      expect (is-displayed "category1-category2")

  test-fold-state-persists-after-save -> none:
    with-config: | config/Config |
      // Open the first category.
      toggle-fold "category1"
      expect-not (is-folded "category1")

      // Close the nested category.
      expect-not (is-folded "category1-category2")
      toggle-fold "category1-category2"
      expect (is-folded "category1-category2")

      // Make a change to trigger save.
      input-field := driver.find --selector="#category1 input[type='text']"
      expect-not input-field.is-empty
      driver.type input-field.first "X"

      save

      // Verify fold state remains the same after save.
      expect-not (is-folded "category1")
      expect (is-folded "category1-category2")

      // Check that no element has the "modified" class.
      modified-elements := driver.find --selector=".modified"
      expect modified-elements.is-empty
