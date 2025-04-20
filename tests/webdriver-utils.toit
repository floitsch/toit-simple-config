// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.

import expect show *
import monitor
import net
import simple-config show *
import simple-config.store show *

import .webdriver

class StoreTest implements Store:
  stored-values/Map? := null

  save values/Map -> none:
    stored-values = values

  load -> Map?:
    return stored-values

  close -> none: /* Do nothing. */

with-test-config schema/Map [--init] [block]:
  store := StoreTest
  config := Config --store=store --schema=schema --init=init
  try:
    port := config.serve --port=0
    block.call config "http://localhost:$port"
  finally:
    config.close

with-test-config schema/Map [block]:
  with-test-config schema --init=(: {:}) block

wait-for --max-attempts=30 [block] -> bool:
  max-attempts.repeat:
    if block.call: return true
    sleep --ms=(it * 10)
  return false

web-driver-main args/List [block]:
  if args.is-empty: return

  network := net.open

  browser := args.first

  if browser == "--serve":
    // Just run the server.
    return

  if not DRIVERS_.get browser:
    // This test may be called from the Toit repository with the wrong arguments.
    // We don't want to fail in that case.
    print "*********************************************"
    print "IGNORING UNSUPPORTED BROWSER: $browser"
    print "*********************************************"
    return

  web-driver := WebDriver browser
  web-driver.start
  try:
    block.call web-driver
  finally:
    web-driver.close

abstract class Tester:
  driver/WebDriver

  constructor .driver:

  save -> none:
    save-button := driver.find --selector="#saveButton"
    expect-not save-button.is-empty
    driver.click save-button.first

    toast-appeared := wait-for:
      saved-toast := driver.find --selector=".toast-container"
      not saved-toast.is-empty
    expect toast-appeared
    // Click on the saved toast to dismiss it.
    saved-toast := driver.find --selector=".toast-container"
    if not saved-toast.is-empty:
      sleep --ms=300
      driver.click saved-toast.first


abstract class TypeTester extends Tester:
  input_/string? := null

  constructor driver/WebDriver:
    super driver

  test -> none:
    test-basics
    test-with-value
    test-modifications

  abstract schema -> Map
  abstract selector -> string
  abstract default-value -> any
  abstract cleared-value-saved -> any
  abstract test-value -> any
  abstract other-test-value -> any
  abstract clear-input input/string -> none
  can-clear -> bool: return true
  get-value input/string -> any: return driver.get-property input "value"
  set-value input/string value/any -> none: driver.type input value

  input -> string:
    if not input_:
      for i := 0; i < 3; i++:
        found := driver.find --selector=selector
        if not found.is-empty:
          input_ = found.first
          break
        sleep --ms=300
    return input_

  save -> none:
    sleep --ms=100  // Firefox sometimes needs a bit of time.
    super
    input_ = null

  with-config [block]:
    with-config --init=(: {:}) block

  with-config [--init] [block]:
    with-test-config schema --init=init: | config/Config url/string |
      input_ = null
      driver.goto url
      block.call config

  test-basics -> none:
    with-config: | config/Config |
      // Test that the input field is shown.
      succeeded := wait-for:
        elements := driver.find --selector=selector
        expect-not-null elements
        elements.size == 1
      expect succeeded

      // Test that the field label displays the title.
      title-elements := driver.find --selector=".value-title"
      expect-not title-elements.is-empty
      title-text := driver.get-text title-elements.first
      expect-equals "Title" title-text

      // Test that the description is shown.
      description-elements := driver.find --selector=".value-description"
      expect-not description-elements.is-empty
      description-text := driver.get-text description-elements.first
      expect-equals "Some description" description-text

      // Test no value.
      input-value := get-value input
      expect-equals default-value input-value

  test-with-value -> none:
    initial := { "prop": test-value }
    with-config --init=(: initial): | config/Config |
      // Test the initial value.
      string-input-value := get-value input
      expect-equals test-value string-input-value

  test-modifications -> none:
    initial := { "prop": test-value }
    with-config --init=(: initial): | config/Config |
      // Test modifying the string value.
      driver.clear input
      set-value input other-test-value
      save

      // Verify the config object has been updated.
      expect-equals other-test-value config.values["prop"]

      if not can-clear: return

      clear-input input
      save

      expect-equals cleared-value-saved config.values["prop"]

