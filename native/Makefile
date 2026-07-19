CC ?= cc
PKG_CONFIG ?= pkg-config
CFLAGS ?= -O2 -g -Wall -Wextra -Werror

LUA_CFLAGS ?= $(shell $(PKG_CONFIG) --cflags lua5.4 2>/dev/null)
LUA_LIBS ?= $(shell $(PKG_CONFIG) --libs lua5.4 2>/dev/null)

MODULE = proc17_repository_fs.so
TEST = tests/test_proc17_repository_fs

.PHONY: all test clean toolchain-check

all: toolchain-check $(MODULE)

toolchain-check:
	@test -n "$(LUA_CFLAGS)" || { \
		echo "Lua 5.4 development headers are required" >&2; \
		exit 1; \
	}

$(MODULE): proc17_repository_fs.c
	$(CC) $(CFLAGS) -fPIC -shared $(LUA_CFLAGS) -o $@ $< $(LUA_LIBS)

$(TEST): tests/test_proc17_repository_fs.c proc17_repository_fs.c proc17_repository_fs_test.h
	$(CC) $(CFLAGS) -DPROC17_REPOSITORY_FS_TESTING -o $@ \
		tests/test_proc17_repository_fs.c proc17_repository_fs.c

test: toolchain-check $(TEST)
	./$(TEST)

clean:
	rm -f $(MODULE) $(TEST)
