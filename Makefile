KONG_HOME = `pwd`

export SILENT_FLAG ?=
export COVERAGE_FLAG ?=

TESTS_CONF ?= kong_TEST.yml
DEVELOPMENT_CONF ?= kong_DEVELOPMENT.yml

.PHONY: install dev seed drop test coverage run-integration-tests test-web test-proxy test-all

install:
	@if [ `uname` == "Darwin" ]; then \
		luarocks make kong-*.rockspec; \
	else \
		luarocks make kong-*.rockspec \
		PCRE_LIBDIR=`find / -type f -name "libpcre.so*" -print -quit | xargs dirname` \
		OPENSSL_LIBDIR=`find / -type f -name "libssl.so*" -print -quit | xargs dirname`; \
	fi

dev:
	@scripts/dev_rocks.sh
	@scripts/config.lua -k $(KONG_HOME) -e TEST create
	@scripts/config.lua -k $(KONG_HOME) -e DEVELOPMENT create
	@scripts/db.lua -c $(DEVELOPMENT_CONF) migrate

run:
	@bin/kong -c $(DEVELOPMENT_CONF) start

seed:
	@scripts/db.lua -c $(DEVELOPMENT_CONF) seed

drop:
	@scripts/db.lua -c $(DEVELOPMENT_CONF) drop

test:
	@busted $(COVERAGE_FLAG) spec/unit

coverage:
	@rm -f luacov.*
	@$(MAKE) test COVERAGE_FLAG=--coverage
	@luacov -c spec/.luacov

lint:
	@luacheck kong*.rockspec

run-integration-tests:
	@busted $(COVERAGE_FLAG) $(FOLDER) || (bin/kong stop; scripts/db.lua -c $(TESTS_CONF) $(SILENT_FLAG) reset; exit 1)

test-web:
	@$(MAKE) run-integration-tests FOLDER=spec/web SILENT_FLAG=-s

test-proxy:
	@$(MAKE) run-integration-tests FOLDER=spec/proxy SILENT_FLAG=-s

test-server:
	@busted $(COVERAGE_FLAG) spec/server

test-all:
	@$(MAKE) run-integration-tests FOLDER=spec SILENT_FLAG=-s
	@busted $(COVERAGE_FLAG) spec/server
