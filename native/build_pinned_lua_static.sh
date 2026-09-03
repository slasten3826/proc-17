#!/bin/sh
set -eu

VERSION=5.4.8
SOURCE_SIZE=374332
SOURCE_SHA256=4f18ddae154e793e46eeab727c59ef1c0c0c2b744e7b94219710d76f530629ae

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
SOURCE_ARCHIVE="$REPOSITORY_ROOT/third_party/lua-$VERSION/lua-$VERSION.tar.gz"
BUILD_PARENT="$SCRIPT_DIR/build/deps"
FINAL_ROOT="$BUILD_PARENT/lua-$VERSION"

fail() {
    printf 'pinned Lua build: %s\n' "$*" >&2
    exit 1
}

require_tool() {
    command -v "$1" >/dev/null 2>&1 || fail "required tool is unavailable: $1"
}

require_verification_tools() {
    for tool in ar cut grep sha256sum tr wc; do
        require_tool "$tool"
    done
}

verify_source() {
    test -f "$SOURCE_ARCHIVE" || fail "source archive is missing: $SOURCE_ARCHIVE"
    actual_size=$(wc -c < "$SOURCE_ARCHIVE" | tr -d '[:space:]')
    test "$actual_size" = "$SOURCE_SIZE" \
        || fail "source size mismatch: expected $SOURCE_SIZE, got $actual_size"
    actual_digest=$(sha256sum "$SOURCE_ARCHIVE" | cut -d' ' -f1)
    test "$actual_digest" = "$SOURCE_SHA256" \
        || fail "source digest mismatch: expected $SOURCE_SHA256, got $actual_digest"
}

verify_output() {
    root=$1
    header="$root/src/lua.h"
    archive="$root/src/liblua.a"

    test -f "$header" || fail "Lua header is missing: $header"
    test -f "$archive" || fail "Lua static archive is missing: $archive"
    grep -Eq '^#define LUA_VERSION_MAJOR[[:space:]]+"5"$' "$header" \
        || fail "Lua major version is not 5"
    grep -Eq '^#define LUA_VERSION_MINOR[[:space:]]+"4"$' "$header" \
        || fail "Lua minor version is not 4"
    grep -Eq '^#define LUA_VERSION_RELEASE[[:space:]]+"8"$' "$header" \
        || fail "Lua release version is not 8"

    members=$(ar t "$archive")
    for member in lapi.o lstate.o lvm.o lauxlib.o lbaselib.o linit.o; do
        printf '%s\n' "$members" | grep -Fxq "$member" \
            || fail "Lua static archive lacks required member: $member"
    done

    sha256sum "$archive"
}

build() {
    require_verification_tools
    require_tool tar
    require_tool make
    require_tool "${CC:-cc}"
    require_tool "${AR:-ar}"
    require_tool "${RANLIB:-ranlib}"
    verify_source

    mkdir -p "$BUILD_PARENT"
    temp_parent=$(mktemp -d "$BUILD_PARENT/lua-$VERSION.tmp.XXXXXX")
    backup_root="$BUILD_PARENT/lua-$VERSION.backup.$$"
    installed=0
    cleanup() {
        rm -rf -- "$temp_parent"
        if test "$installed" -eq 0 && test -d "$backup_root" && ! test -e "$FINAL_ROOT"; then
            mv -- "$backup_root" "$FINAL_ROOT"
        fi
    }
    trap cleanup EXIT HUP INT TERM

    tar -xzf "$SOURCE_ARCHIVE" -C "$temp_parent"
    extracted="$temp_parent/lua-$VERSION"
    test -d "$extracted/src" || fail "archive root is not lua-$VERSION"

    make -C "$extracted/src" a \
        "CC=${CC:-cc} -std=gnu99" \
        "AR=${AR:-ar} rcsD" \
        "RANLIB=${RANLIB:-ranlib} -D" \
        SYSCFLAGS=-DLUA_USE_LINUX \
        'MYCFLAGS=-fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=3'
    verify_output "$extracted" >/dev/null

    test ! -e "$backup_root" || fail "owned backup path already exists: $backup_root"
    if test -e "$FINAL_ROOT"; then
        mv -- "$FINAL_ROOT" "$backup_root"
    fi
    if ! mv -- "$extracted" "$FINAL_ROOT"; then
        test ! -d "$backup_root" || mv -- "$backup_root" "$FINAL_ROOT"
        fail "could not install complete Lua build"
    fi
    installed=1
    rm -rf -- "$backup_root"
    verify_output "$FINAL_ROOT"
}

verify() {
    require_verification_tools
    verify_source
    test -d "$FINAL_ROOT" || fail "local Lua build is missing: $FINAL_ROOT"
    verify_output "$FINAL_ROOT"
}

case "${1:-}" in
    build)
        build
        ;;
    verify)
        verify
        ;;
    *)
        printf 'usage: %s {build|verify}\n' "$0" >&2
        exit 2
        ;;
esac
