CC ?= cc
PKG_CONFIG ?= pkg-config
CFLAGS ?= -O2 -g -Wall -Wextra -Werror -fstack-protector-strong -D_FORTIFY_SOURCE=3
LDFLAGS ?= -Wl,-z,relro,-z,now

LUA_CFLAGS ?= $(shell $(PKG_CONFIG) --cflags lua5.4 2>/dev/null)
LUA_LIBS ?= $(shell $(PKG_CONFIG) --libs lua5.4 2>/dev/null)

MODULE = proc17_repository_fs.so
TEST = tests/test_proc17_repository_fs
TEST_CREATE = tests/test_proc17_repository_fs_create
FIXTURE_HELPER = tests/proc17_fixture_guard
WRONG_ABI_MODULE = tests/proc17_repository_fs_wrong_abi.so

.PHONY: all test test-create test-read clean toolchain-check provider-shell loader-test-fixture \
	fixture-helper fixture-test contract-test-syntax

all: toolchain-check $(MODULE)

toolchain-check:
	@test -n "$(LUA_CFLAGS)" || { \
		echo "Lua 5.4 development headers are required" >&2; \
		exit 1; \
	}

$(MODULE): proc17_repository_fs.c
	$(CC) $(CFLAGS) -fPIC -shared $(LUA_CFLAGS) $(LDFLAGS) -o $@ $< $(LUA_LIBS)

provider-shell: toolchain-check $(MODULE)

$(WRONG_ABI_MODULE): tests/proc17_repository_fs_wrong_abi.c
	$(CC) $(CFLAGS) -fPIC -shared $(LUA_CFLAGS) $(LDFLAGS) -o $@ $< $(LUA_LIBS)

loader-test-fixture: toolchain-check $(WRONG_ABI_MODULE)

$(TEST): tests/test_proc17_repository_fs.c proc17_repository_fs.c proc17_repository_fs_test.h
	$(CC) $(CFLAGS) $(LUA_CFLAGS) -DPROC17_REPOSITORY_FS_TESTING -o $@ \
		tests/test_proc17_repository_fs.c proc17_repository_fs.c $(LDFLAGS) $(LUA_LIBS)

$(TEST_CREATE): tests/test_proc17_repository_fs.c proc17_repository_fs.c proc17_repository_fs_test.h
	$(CC) $(CFLAGS) $(LUA_CFLAGS) -DPROC17_REPOSITORY_FS_TESTING \
		-DPROC17_REPOSITORY_FS_CREATE_ONLY -o $@ \
		tests/test_proc17_repository_fs.c proc17_repository_fs.c $(LDFLAGS) $(LUA_LIBS)

$(FIXTURE_HELPER): tests/proc17_fixture_guard.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

fixture-helper: $(FIXTURE_HELPER)

fixture-test: $(FIXTURE_HELPER)
	./$(FIXTURE_HELPER) self-test

contract-test-syntax: proc17_repository_fs_test.h tests/test_proc17_repository_fs.c
	$(CC) $(CFLAGS) -DPROC17_REPOSITORY_FS_TESTING -fsyntax-only \
		tests/test_proc17_repository_fs.c

test: toolchain-check $(TEST)
	./$(TEST)

test-create: toolchain-check $(TEST_CREATE)
	./$(TEST_CREATE)

test-read: test

clean:
	rm -f $(MODULE) $(TEST) $(TEST_CREATE) $(FIXTURE_HELPER) $(WRONG_ABI_MODULE)
