// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import encoding.json
import fs
import host.file
import http
import io
import monitor
import net
import simple-config
import simple-config.resources as simple-config
import simple-config.store as simple-config
import system

SCHEMA ::= {
  "title": "Some title",
  "description": "Some description",
  "type": "object",
  "properties": {
    "cat": {
      "type": "object",
      "id": "cat",
      "title": "Cat title",
      "description": "Cat description",
      "properties": {
        "value": {
          "type": "string",
          "title": "Value title",
          "description": "Value description",
          "default": "default value",
        },
        "some-url":{
          "type": "string",
          "format": "uri",
          "title": "URL title",
          "description": "URL description",
          "default": "http://www.example.com",
        },
        "value2": {
          "type": "boolean",
          "title": "BBB",
          "description": "B Value description",
        },
        "value3": {
          "type": "integer",
          "title": "some-int",
          "description": "B Value description",
        },
      },
    },
    "ll": {
      "type": "array",
      "title": "List title",
      "description": "List description",
      "items": {
        "type": "integer",
        "title": "Value title x",
        "description": "Value description x",
      },
    },
    "cat2": {
      "type": "object",
      "folded": true,
      "title": "Cat title2",
      "description": "Cat description2",
      "properties": {
        "cat3": {
          "type": "object",
          "title": "Cat title3",
          "description": "Cat description3",
          "properties": {
            "value":{
              "type": "string",
              "format": "password",
              "title": "Value title",
              "description": "Value description",
              "default": "default value",
            },
          },
        },
        "cat enum": {
          "type": "object",
          "title": "Cat enum",
          "description": "Cat enum description",
          "properties": {
            "value": {
              "type": "string",
              "enum": ["a", "b", "c"],
              "title": "Value title",
              "description": "Value description",
              "default": "a",
            },
          },
          "oneOf": [
            {
              "properties": {
                "value": {
                  "const": "a",
                },
                "dep-a": {
                  "type": "string",
                  "title": "AA",
                  "description": "AA description",
                },
              },
            },
            {
              "properties": {
                "value": {
                  "const": "b",
                },
                "dep-b": {
                  "type": "string",
                  "title": "BB",
                  "description": "BB description",
                },
              },
            },
            {
              "properties": {
                "value": {
                  "const": "c",
                },
                "dep-c": {
                  "type": "string",
                  "title": "CC",
                  "description": "CC description",
                },
              },
            },
          ],
        }
      },
    },
  },
}

class ResourcesLocal implements simple-config.Resources:
  dir_ ::= fs.dirname system.program-path

  index -> io.Data:
    return file.read-contents "$dir_/index.html"

  config-js -> io.Data:
    return file.read-contents "$dir_/config.js"

  styles-css -> io.Data:
    return file.read-contents "$dir_/styles.css"

  close -> none: /* Do nothing. */

class StoreNull implements simple-config.Store:
  save values/Map -> none:
    // Do nothing.

  load -> Map?:
    return null

  close -> none: /* Do nothing. */

main:
  values := {
    "cat": {
      "value": "valueX",
      "value2": false,
    },
  }

  config := simple-config.Config
      --store=StoreNull
      --schema=SCHEMA
      --resources=ResourcesLocal
      --init=(: values)

  config.serve --port=7017

  latch := monitor.Latch
  // Wait indefinitely.
  latch.get
