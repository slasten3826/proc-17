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
QA_SHARED_ABI_TEST = tests/test_proc17_qa_launcher
QA_WIRE_TEST = tests/test_proc17_qa_wire
QA_SUPERVISOR = proc17_qa_supervisor
QA_LAUNCHER_MODULE = proc17_qa_launcher.so
QA_SUPERVISOR_TEST = tests/test_proc17_qa_supervisor
QA_RUN_TEST = tests/test_proc17_qa_run
QA_WRONG_ABI_MODULE = tests/proc17_qa_launcher_wrong_abi.so
QA_GENERATED_DIR = generated
QA_PREBUILD_IDENTITY = $(QA_GENERATED_DIR)/proc17_qa_prebuild.h
QA_BUILD_IDENTITY = $(QA_GENERATED_DIR)/proc17_qa_build_identity.h
QA_LUA_STATIC_ARCHIVE ?= /usr/lib/liblua5.4.a
QA_LIBC_STATIC_ARCHIVE ?= /usr/lib/libc.a
QA_LIBM_STATIC_ARCHIVE ?= /usr/lib/libm.a
QA_LIBDL_STATIC_ARCHIVE ?= /usr/lib/libdl.a
QA_LUA_STATIC_CFLAGS ?= -I/usr/include/lua5.4
QA_STATIC_LDFLAGS ?= -static-pie

.PHONY: all test test-create test-read clean toolchain-check provider-shell loader-test-fixture \
	fixture-helper fixture-test contract-test-syntax qa-host-contract-syntax \
	qa-wire-contract-syntax qa-wire-test qa-shared-abi-test \
	qa-static-closure-test qa-launcher-contract-test \
	qa-launcher-identity-test qa-launcher-exec-test qa-launcher-fd-test \
	qa-supervisor-namespace-test qa-supervisor-mount-test \
	qa-supervisor-lua-test qa-supervisor-seccomp-test \
	qa-supervisor-limits-test qa-native-probe-test qa-provider-shell \
	qa-loader-test-fixture qa-run-basic-internal-test \
	qa-supervisor-basic-fixtures-test

all: toolchain-check $(MODULE)

toolchain-check:
	@test -n "$(LUA_CFLAGS)" || { \
		echo "Lua 5.4 development headers are required" >&2; \
		exit 1; \
	}

$(MODULE): proc17_repository_fs.c proc17_repository_handle_abi.h
	$(CC) $(CFLAGS) -fPIC -shared $(LUA_CFLAGS) $(LDFLAGS) -o $@ $< $(LUA_LIBS)

provider-shell: toolchain-check $(MODULE)

$(WRONG_ABI_MODULE): tests/proc17_repository_fs_wrong_abi.c
	$(CC) $(CFLAGS) -fPIC -shared $(LUA_CFLAGS) $(LDFLAGS) -o $@ $< $(LUA_LIBS)

loader-test-fixture: toolchain-check $(WRONG_ABI_MODULE)

$(TEST): tests/test_proc17_repository_fs.c proc17_repository_fs.c \
		proc17_repository_fs_test.h proc17_repository_handle_abi.h
	$(CC) $(CFLAGS) $(LUA_CFLAGS) -DPROC17_REPOSITORY_FS_TESTING -o $@ \
		tests/test_proc17_repository_fs.c proc17_repository_fs.c $(LDFLAGS) $(LUA_LIBS)

$(TEST_CREATE): tests/test_proc17_repository_fs.c proc17_repository_fs.c \
		proc17_repository_fs_test.h proc17_repository_handle_abi.h
	$(CC) $(CFLAGS) $(LUA_CFLAGS) -DPROC17_REPOSITORY_FS_TESTING \
		-DPROC17_REPOSITORY_FS_CREATE_ONLY -o $@ \
		tests/test_proc17_repository_fs.c proc17_repository_fs.c $(LDFLAGS) $(LUA_LIBS)

$(QA_SHARED_ABI_TEST): tests/test_proc17_qa_launcher.c proc17_qa_launcher.c \
		proc17_qa_launcher_internal.h proc17_repository_fs.c \
		proc17_repository_handle_abi.h proc17_qa_wire.h proc17_qa_policy.h \
		proc17_sha256.c proc17_sha256.h $(QA_BUILD_IDENTITY) $(QA_PREBUILD_IDENTITY)
	$(CC) $(CFLAGS) $(LUA_CFLAGS) -o $@ \
		tests/test_proc17_qa_launcher.c proc17_qa_launcher.c \
		proc17_repository_fs.c proc17_sha256.c $(LDFLAGS) $(LUA_LIBS) -ldl

$(QA_WIRE_TEST): tests/test_proc17_qa_wire.c proc17_qa_wire.h \
		proc17_sha256.c proc17_sha256.h
	$(CC) $(CFLAGS) -o $@ tests/test_proc17_qa_wire.c \
		proc17_sha256.c $(LDFLAGS)

$(QA_GENERATED_DIR):
	mkdir -p $@

$(QA_PREBUILD_IDENTITY): Makefile proc17_qa_policy.h qa_probe_source/probe.lua \
		$(QA_LUA_STATIC_ARCHIVE) $(QA_LIBC_STATIC_ARCHIVE) \
		$(QA_LIBM_STATIC_ARCHIVE) $(QA_LIBDL_STATIC_ARCHIVE) | $(QA_GENERATED_DIR)
	@lua_digest=$$(sha256sum $(QA_LUA_STATIC_ARCHIVE) | cut -d' ' -f1); \
	libc_digest=$$(sha256sum $(QA_LIBC_STATIC_ARCHIVE) | cut -d' ' -f1); \
	libm_digest=$$(sha256sum $(QA_LIBM_STATIC_ARCHIVE) | cut -d' ' -f1); \
	libdl_digest=$$(sha256sum $(QA_LIBDL_STATIC_ARCHIVE) | cut -d' ' -f1); \
	policy_digest=$$(sha256sum proc17_qa_policy.h | cut -d' ' -f1); \
	probe_digest=$$(sha256sum qa_probe_source/probe.lua | cut -d' ' -f1); \
	closure_digest=$$(printf '%s\n' \
		"lua=$$lua_digest" \
		"libc=$$libc_digest" \
		"libm=$$libm_digest" \
		"libdl=$$libdl_digest" \
		"policy=$$policy_digest" \
		"probe=$$probe_digest" \
		"cc=$$($(CC) -dumpfullversion -dumpversion)" \
		"flags=$(CFLAGS) $(QA_STATIC_LDFLAGS)" | sha256sum | cut -d' ' -f1); \
	{ \
		echo '#ifndef PROC17_QA_PREBUILD_H'; \
		echo '#define PROC17_QA_PREBUILD_H'; \
		echo "#define PROC17_QA_RUNTIME_BUILD_ID_HEX \"$$lua_digest\""; \
		echo "#define PROC17_QA_RUNTIME_DEPENDENCY_CLOSURE_ID_HEX \"$$closure_digest\""; \
		echo "#define PROC17_QA_POLICY_DIGEST_HEX \"$$policy_digest\""; \
		echo "#define PROC17_QA_PROBE_SOURCE_ID_HEX \"$$probe_digest\""; \
		echo '#endif'; \
	} > $@.tmp
	mv $@.tmp $@

$(QA_SUPERVISOR): proc17_qa_supervisor.c proc17_qa_wire.h proc17_qa_policy.h \
		proc17_sha256.c proc17_sha256.h $(QA_PREBUILD_IDENTITY)
	$(CC) $(CFLAGS) -fPIE $(QA_LUA_STATIC_CFLAGS) -I. \
		-o $@ proc17_qa_supervisor.c proc17_sha256.c \
		$(QA_STATIC_LDFLAGS) $(QA_LUA_STATIC_ARCHIVE) -lm -ldl

$(QA_BUILD_IDENTITY): $(QA_SUPERVISOR) $(QA_PREBUILD_IDENTITY) | $(QA_GENERATED_DIR)
	@supervisor_digest=$$(sha256sum $(QA_SUPERVISOR) | cut -d' ' -f1); \
	{ \
		echo '#ifndef PROC17_QA_BUILD_IDENTITY_H'; \
		echo '#define PROC17_QA_BUILD_IDENTITY_H'; \
		echo "#define PROC17_QA_EXPECTED_SUPERVISOR_BUILD_ID_HEX \"$$supervisor_digest\""; \
		echo '#endif'; \
	} > $@.tmp
	mv $@.tmp $@

$(QA_LAUNCHER_MODULE): proc17_qa_launcher.c proc17_qa_launcher_internal.h \
		proc17_repository_handle_abi.h proc17_qa_wire.h proc17_qa_policy.h \
		proc17_sha256.c proc17_sha256.h $(QA_BUILD_IDENTITY) $(QA_PREBUILD_IDENTITY)
	$(CC) $(CFLAGS) -fPIC -shared $(LUA_CFLAGS) -I. -o $@ \
		proc17_qa_launcher.c proc17_sha256.c $(LDFLAGS) $(LUA_LIBS) -ldl

qa-provider-shell: toolchain-check $(QA_LAUNCHER_MODULE)

$(QA_WRONG_ABI_MODULE): tests/proc17_qa_launcher_wrong_abi.c
	$(CC) $(CFLAGS) -fPIC -shared $(LUA_CFLAGS) $(LDFLAGS) \
		-o $@ $< $(LUA_LIBS)

qa-loader-test-fixture: toolchain-check $(QA_WRONG_ABI_MODULE)

$(QA_SUPERVISOR_TEST): tests/test_proc17_qa_supervisor.c \
		$(QA_SHARED_ABI_TEST) $(QA_LAUNCHER_MODULE)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ tests/test_proc17_qa_supervisor.c

$(QA_RUN_TEST): tests/test_proc17_qa_run.c proc17_repository_fs.c \
		proc17_repository_handle_abi.h $(QA_LAUNCHER_MODULE)
	$(CC) $(CFLAGS) $(LUA_CFLAGS) -I. -o $@ \
		tests/test_proc17_qa_run.c proc17_repository_fs.c \
		$(LDFLAGS) $(LUA_LIBS) -ldl

qa-run-basic-internal-test: toolchain-check $(QA_RUN_TEST)
	./$(QA_RUN_TEST)

qa-supervisor-basic-fixtures-test: qa-run-basic-internal-test

qa-static-closure-test: $(QA_SUPERVISOR) $(QA_BUILD_IDENTITY)
	@! readelf -l $(QA_SUPERVISOR) | grep -q 'INTERP'
	@! readelf -d $(QA_SUPERVISOR) | grep -q 'NEEDED'
	./$(QA_SUPERVISOR) self-test

qa-launcher-contract-test: toolchain-check $(QA_LAUNCHER_MODULE) $(QA_SHARED_ABI_TEST)
	./$(QA_SHARED_ABI_TEST) contract

qa-launcher-identity-test: toolchain-check $(QA_LAUNCHER_MODULE) $(QA_SHARED_ABI_TEST)
	./$(QA_SHARED_ABI_TEST) identity

qa-launcher-exec-test: toolchain-check $(QA_LAUNCHER_MODULE) $(QA_SHARED_ABI_TEST)
	./$(QA_SHARED_ABI_TEST) exec

qa-launcher-fd-test: toolchain-check $(QA_LAUNCHER_MODULE) $(QA_SHARED_ABI_TEST)
	./$(QA_SHARED_ABI_TEST) fd

qa-native-probe-test: toolchain-check $(QA_SUPERVISOR_TEST)
	./$(QA_SUPERVISOR_TEST)

qa-supervisor-namespace-test: qa-native-probe-test

qa-supervisor-mount-test: qa-native-probe-test

qa-supervisor-lua-test: qa-native-probe-test

qa-supervisor-seccomp-test: qa-native-probe-test

qa-supervisor-limits-test: qa-native-probe-test

$(FIXTURE_HELPER): tests/proc17_fixture_guard.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

fixture-helper: $(FIXTURE_HELPER)

fixture-test: $(FIXTURE_HELPER)
	./$(FIXTURE_HELPER) self-test

contract-test-syntax: proc17_repository_fs_test.h tests/test_proc17_repository_fs.c
	$(CC) $(CFLAGS) -DPROC17_REPOSITORY_FS_TESTING -fsyntax-only \
		tests/test_proc17_repository_fs.c

qa-host-contract-syntax: tests/test_proc17_qa_host_contract.c
	$(CC) $(CFLAGS) -fsyntax-only tests/test_proc17_qa_host_contract.c

qa-wire-contract-syntax: proc17_qa_wire.h tests/test_proc17_qa_wire.c
	$(CC) $(CFLAGS) -fsyntax-only tests/test_proc17_qa_wire.c

qa-wire-test: $(QA_WIRE_TEST)
	./$(QA_WIRE_TEST)

qa-shared-abi-test: toolchain-check $(QA_SHARED_ABI_TEST)
	./$(QA_SHARED_ABI_TEST)

test: toolchain-check $(TEST)
	./$(TEST)

test-create: toolchain-check $(TEST_CREATE)
	./$(TEST_CREATE)

test-read: test

clean:
	rm -f $(MODULE) $(TEST) $(TEST_CREATE) $(FIXTURE_HELPER) \
		$(WRONG_ABI_MODULE) $(QA_SHARED_ABI_TEST) $(QA_WIRE_TEST) \
		$(QA_SUPERVISOR) $(QA_LAUNCHER_MODULE) $(QA_SUPERVISOR_TEST) \
		$(QA_WRONG_ABI_MODULE) $(QA_RUN_TEST)
	rm -rf $(QA_GENERATED_DIR)
