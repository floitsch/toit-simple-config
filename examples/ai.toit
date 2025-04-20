// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import simple-config

CONFIG-SCHEMA ::= {
  "title": "AI Service Configuration",
  "description": "Configure AI service connection settings",
  "type": "object",
  "properties": {
    "service": {
      "type": "object",
      "title": "AI Service",
      "description": "AI service connection parameters",
      "properties": {
        "provider": {
          "type": "string",
          "title": "Provider",
          "description": "AI service provider",
          "enum": ["openai", "gemini", "mistral", "custom"],
          "default": "openai"
        },
        "model": {
          "type": "string",
          "title": "Model",
          "description": "AI model to use",
          "default": "gpt-3.5-turbo"
        },
        "api_key": {
          "type": "string",
          "format": "password",
          "title": "API Key",
          "description": "Authentication key for the AI service"
        },
        "max_tokens": {
          "type": "integer",
          "title": "Max Tokens",
          "description": "Maximum tokens in the response",
          "minimum": 1,
          "maximum": 4096,
          "default": 256
        },
        "temperature": {
          "type": "number",
          "title": "Temperature",
          "description": "Randomness of the output (0.0-2.0)",
          "minimum": 0.0,
          "maximum": 2.0,
          "default": 0.7
        }
      },
      "oneOf": [
        {
          "properties": {
            "provider": {
              "const": "custom"
            },
            "endpoint_url": {
              "type": "string",
              "format": "uri",
              "title": "Endpoint URL",
              "description": "URL of the custom AI service endpoint"
            }
          },
          "required": ["endpoint_url"]
        },
        {
          "properties": {
            "provider": {
              "enum": ["openai", "gemini", "mistral"]
            }
          }
        }
      ]
    },
    "usage": {
      "type": "object",
      "title": "Usage Settings",
      "description": "Configure AI usage parameters",
      "properties": {
        "cache_responses": {
          "type": "boolean",
          "title": "Cache Responses",
          "description": "Store responses to reduce API calls",
          "default": true
        },
        "rate_limit": {
          "type": "integer",
          "title": "Rate Limit",
          "description": "Maximum API calls per minute",
          "minimum": 1,
          "default": 10
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
