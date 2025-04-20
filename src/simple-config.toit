// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import http
import encoding.json
import monitor
import net
import net.tcp
import system.storage

import .resources
import .store

class Config:
  schema/Map
  values/Map := ?
  resources_/Resources? := ?
  updated/monitor.Signal ::= monitor.Signal
  store_/Store? := ?
  server-task_/Task? := null

  constructor storage-path/string --schema/Map [--init]:
    store := Store.ram storage-path
    resources := Resources
    return Config
        --store=store
        --schema=schema
        --init=init

  constructor storage-path/string --schema/Map:
    return Config storage-path --schema=schema --init=(: {:})

  constructor
      --store/Store
      --.schema
      --resources/Resources=Resources
      [--init]:
    store_ = store
    resources_ = resources
    values = store.load or init.call

  close:
    if server-task_:
      server-task_.cancel
    if store_:
      store_.close
      store_ = null
    if resources_:
      resources_.close
      resources_ = null

  update new-values/Map:
    values = new-values
    store_.save new-values
    updated.raise

  operator[] key/string -> any:
    return values[key]

  operator[]= key/string value:
    values[key] = value
    updated.raise

  get key/string -> any:
    return values.get key

  serve --port/int=80 -> int:
    network := net.open
    server-socket := network.tcp-listen port
    local-port := server-socket.local-address.port
    print "Server on http://$network.address:$local-port/"
    server := http.Server --max-tasks=10
    server-task_ = task --background::
      try:
        listen_ server server-socket
      finally:
        server-socket.close
        network.close
        server-task_ = null
    return local-port

  listen_ server/http.Server server-socket/tcp.ServerSocket:
    server.listen server-socket:: | request/http.RequestIncoming writer/http.ResponseWriter |
      resource := request.query.resource
      if resource == "/schema":
        writer.headers.set "Content-Type" "application/json"
        payload := json.encode schema
        writer.out.write payload
      else if resource == "/values":
        writer.headers.set "Content-Type" "application/json"
        payload := json.encode values
        writer.out.write payload
      else if resource == "/update":
        decoded := json.decode-stream request.body
        fix-numbers_ --in-place decoded schema
        update decoded
        writer.headers.set "Content-Type" "text/plain"
        writer.out.write "OK"
      else if resource == "/" or resource == "/index.html":
        writer.headers.set "Content-Type" "text/html"
        writer.out.write resources_.index
      else if resource == "/config.js":
        writer.headers.set "Content-Type" "text/javascript"
        writer.out.write resources_.config-js
      else if resource == "/styles.css":
        writer.headers.set "Content-Type" "text/css"
        writer.out.write resources_.styles-css
      else:
          writer.headers.set "Content-Type" "text/plain"
          writer.write-headers 404
          writer.out.write "Not found: $resource"
      writer.close

  find-discriminator_ current-schema/Map -> string?:
    if not current-schema.contains "properties": return null
    if not current-schema.contains "oneOf": return null
    // The first property in the oneOf must be a const, pointing to the enum.
    first := current-schema["oneOf"][0]
    if not first.contains "properties": return null
    first["properties"].do: | key/string value |
      if value is Map and value.contains "const":
        return key
    return null

  fix-numbers_ --in-place/True decoded/any current-schema/Map:
    if decoded is not Map: return
    props := current-schema.get "properties"
    if props is not Map: return
    discriminator := find-discriminator_ current-schema
    discriminator-value := discriminator and decoded.get discriminator
    if discriminator and discriminator-value == null:
      discriminator-schema := props.get discriminator
      if discriminator-schema and discriminator-schema is Map:
        discriminator-value = discriminator-schema.get "default"
    decoded.map --in-place: | key/string value |
      sub-schema/Map? := null
      if props.contains key:
        sub-schema = props[key]
      else if discriminator:
        one-ofs := current-schema["oneOf"]
        for i := 0; i < one-ofs.size; i++:
          one-of-schema := one-ofs[i]
          if not one-of-schema.contains "properties": continue
          one-of-properties := one-of-schema["properties"]
          if not one-of-properties.contains discriminator: continue
          const-value := one-of-properties[discriminator]
          if const-value is not Map or not const-value.contains "const": continue
          if const-value["const"] != discriminator-value: continue
          if one-of-properties.contains key:
            sub-schema = one-of-properties[key]
            break

      if sub-schema:
        if sub-schema["type"] == "integer":
          if value is not int:
            if value is not float:
              // Should not happen, since the UI should have validated.
              value = 0
            else:
              value = (value as float).to-int
        else if sub-schema["type"] == "number":
          if value is not float:
            if value is not int:
              // Should not happen, since the UI should have validated.
              value = 0.0
            else:
              value = (value as int).to-float
        else if sub-schema["type"] == "object":
          fix-numbers_ --in-place value sub-schema
        else if sub-schema["type"] == "array":
          value.do: | item |
            fix-numbers_ --in-place item sub-schema["items"]
      value
