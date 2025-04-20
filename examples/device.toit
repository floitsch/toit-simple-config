// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import simple-config

CONFIG-SCHEMA ::= {
  "title": "Device Settings",
  "description": "Basic device configuration options",
  "type": "object",
  "properties": {
    "device": {
      "type": "object",
      "title": "Device",
      "description": "General device settings",
      "properties": {
        "name": {
          "type": "string",
          "title": "Device Name",
          "description": "Friendly name for the device",
          "default": "IoT Device"
        },
        "location": {
          "type": "string",
          "title": "Location",
          "description": "Physical location of the device"
        },
        "log_level": {
          "type": "string",
          "title": "Log Level",
          "description": "Logging verbosity",
          "enum": ["debug", "info", "warning", "error"],
          "default": "info"
        }
      }
    },
    "power": {
      "type": "object",
      "title": "Power Settings",
      "folded": true,
      "description": "Power management configuration",
      "properties": {
        "sleep_mode": {
          "type": "boolean",
          "title": "Enable Sleep Mode",
          "description": "Enable deep sleep to save power",
          "default": true
        },
        "sleep_interval": {
          "type": "integer",
          "title": "Sleep Interval",
          "description": "Time in seconds between wake-ups",
          "minimum": 10,
          "default": 300
        },
        "battery_threshold": {
          "type": "integer",
          "title": "Low Battery Threshold",
          "description": "Battery percentage to trigger low power mode",
          "minimum": 5,
          "maximum": 50,
          "default": 20
        }
      }
    }
  }
}

main:
  config := simple-config.Config "toitware.com/toit-simple-config/example" --schema=CONFIG-SCHEMA
  config.serve --port=7017

  task::
    while true:
      config.updated.wait
      values := config.values

      print "Updated values: $values"
