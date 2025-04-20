// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import simple-config show *

import .webdriver-utils
import .webdriver

main args/List:
  web-driver-main args:
    (StringTypeTester it).test
    (PasswordTypeTester it).test
    (UriTypeTester it).test

class StringTypeTester extends TypeTester:
  static STRING-SCHEMA ::= {
    "title": "Test",
    "description": "different types",
    "type": "object",
    "properties": {
      "prop": {
        "type": "string",
        "title": "Title",
        "description": "Some description",
        "default": "default value",
      },
    },
  }

  constructor driver/WebDriver:
    super driver

  schema/Map ::= STRING-SCHEMA
  default-value ::= "default value"
  cleared-value-saved ::= ""
  test-value ::= "some string"
  other-test-value ::= "another string"
  selector -> string: return "input[type='text']"

  clear-input input/string -> none:
    driver.type input "\uE003" * 50
    driver.type input "\uE017" * 50

class PasswordTypeTester extends StringTypeTester:
  static PASSWORD-SCHEMA ::= {
    "title": "Test",
    "description": "different types",
    "type": "object",
    "properties": {
      "prop": {
        "type": "string",
        "title": "Title",
        "description": "Some description",
        "default": "default value",
        "format": "password",
      },
    },
  }

  constructor driver/WebDriver:
    super driver

  schema/Map ::= PASSWORD-SCHEMA
  test-value ::= "some string"
  other-test-value ::= "another string"
  selector -> string: return "input[type='password']"

  test:
    super
    test-hidden-shown

  test-hidden-shown:
    initial := { "prop": test-value }
    with-config --init=(: initial): | config/Config |
      // First check that it's hidden (type="password")
      type := driver.get-attribute input "type"
      expect-equals "password" type

      // Find and click the toggle button
      toggle-buttons := driver.find --selector=".toggle-password"
      expect-not toggle-buttons.is-empty
      driver.click toggle-buttons.first

      // Check that the input is now visible (type="text")
      type = driver.get-attribute input "type"
      expect-equals "text" type

      // Toggle back to hidden
      driver.click toggle-buttons.first

      // Verify it's hidden again
      type = driver.get-attribute input "type"
      expect-equals "password" type

class UriTypeTester extends StringTypeTester:
  static URI-SCHEMA ::= {
    "title": "Test",
    "description": "different types",
    "type": "object",
    "properties": {
      "prop": {
        "type": "string",
        "title": "Title",
        "description": "Some description",
        "default": "http://example.com",
        "format": "uri",
      },
    },
  }

  constructor driver/WebDriver:
    super driver

  schema/Map ::= URI-SCHEMA
  default-value ::= "http://example.com"
  test-value ::= "http://example.com"
  other-test-value ::= "https://test.com"
  selector -> string: return "input[type='url']"

