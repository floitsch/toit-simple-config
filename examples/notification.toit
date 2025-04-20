// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import simple-config

CONFIG-SCHEMA ::= {
  "title": "Example",
  "description": "Example configuration schema",
  "type": "object",
  "properties": {
    "general": {
      "type": "object",
      "title": "General Settings",
      "description": "General settings for the application",
      "properties": {
        "Frequency": {
          "type": "integer",
          "title": "Frequency",
          "description": "Frequency in seconds for the application to run.",
          "default": 60,
        },
        "Remote": {
          "type": "string",
          "format": "uri",
          "title": "Remote URL",
          "description": "URL to fetch data from.",
          "default": "http://example.com",
        },
      },
    },
    "notification": {
      "type": "object",
      "title": "Notification",
      "description": "Notification end-point.",
      "properties": {
        "type": {
          "type": "string",
          "title": "Type",
          "description": "Type of notification.",
          "enum": [
            "telegram",
            "discord",
          ],
          "default": "telegram",
        },
      },
      "oneOf": [
        {
          "type": "object",
          "properties": {
            "type": {
              "const": "telegram"
            },
            "token": {
              "type": "string",
              "format": "password",
              "title": "Telegram Token",
              "description": "Telegram bot token."
            },
            "password": {
              "type": "string",
              "format": "password",
              "title": "Telegram Password",
              "description": "Telegram password.",
            },
          },
        },
        {
          "type": "object",
          "properties": {
            "type": {
              "const": "discord"
            },
            "token": {
              "type": "string",
              "format": "password",
              "title": "Discord Token",
              "description": "Discord token.",
              "comment": "Discord token."
            },
          },
        },
      ],
    },
  },
}

main:
  config := simple-config.Config "ram:toitware.com/toit-simple-config/example" --schema=CONFIG-SCHEMA
  config.serve --port=7017

  task::
    while true:
      config.updated.wait
      values := config.values

      print "Updated values: $values"
