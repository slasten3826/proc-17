# Lua 5.4.8 Source

This directory contains the exact upstream Lua 5.4.8 source archive used to
build the static runtime embedded in the proc-17 QA supervisor.

```text
project: Lua
version: 5.4.8
release date: 2025-05-21
source URL: https://www.lua.org/ftp/lua-5.4.8.tar.gz
archive: lua-5.4.8.tar.gz
size: 374332 bytes
SHA-256: 4f18ddae154e793e46eeab727c59ef1c0c0c2b744e7b94219710d76f530629ae
license: MIT
copyright: Copyright 1994-2025 Lua.org, PUC-Rio
```

Ordinary builds and tests must use this committed archive without accessing
the network. `native/build_pinned_lua_static.sh` verifies the source digest
before extraction.
