REBAR = $(shell pwd)/rebar

.PHONY: deps rel stagedevrel package version all

all: cp-hooks deps compile

cp-hooks:
	cp hooks/* .git/hooks

quick-xref:
	$(REBAR) xref skip_deps=true -r

quick-test:
	$(REBAR) skip_deps=true eunit -r

version:
	@echo "$(shell git symbolic-ref HEAD 2> /dev/null | cut -b 12-)-$(shell git log --pretty=format:'%h, %ad' -1)" > howl.version

version_header: version
	@echo "-define(VERSION, <<\"$(shell cat howl.version)\">>)." > apps/howl/include/howl_version.hrl

compile: version_header
	$(REBAR) compile -r

deps:
	$(REBAR) get-deps -r

clean:
	$(REBAR) clean -r
	make -C rel/pkg clean

distclean: clean devclean relclean
	$(REBAR) delete-deps

test: all xref
	$(REBAR) skip_deps=true eunit

rel: all zabbix
	-rm -r rel/howl/share 2> /dev/null || true
	$(REBAR) generate

relclean:
	-rm -rf rel/howl 2> /dev/null || true

devrel: dev1 dev2 dev3 dev4

package: rel
	make -C rel/pkg package

zabbix:
	sh generate_zabbix_template.sh
###
### Docs
###
docs:
	$(REBAR) skip_deps=true doc

##
## Developer targets
##

stage : rel
	$(foreach dep,$(wildcard deps/* wildcard apps/*), rm -rf rel/howl/lib/$(shell basename $(dep))-* && ln -sf $(abspath $(dep)) rel/howl/lib;)


stagedevrel: dev1 dev2 dev3 dev4
	$(foreach dev,$^,\
	  $(foreach dep,$(wildcard deps/* wildcard apps/*), rm -rf dev/$(dev)/lib/$(shell basename $(dep))-* && ln -sf $(abspath $(dep)) dev/$(dev)/lib;))

devrel: dev1 dev2 dev3 dev4


devclean:
	rm -rf dev

dev1 dev2 dev3 dev4: all zabbix
	mkdir -p dev
	($(REBAR) generate target_dir=../dev/$@ overlay_vars=vars/$@.config)

xref: all
	$(REBAR) xref skip_deps=true -r

##
## Dialyzer
##
APPS = kernel stdlib sasl erts ssl tools os_mon runtime_tools crypto inets \
	xmerl webtool snmp public_key mnesia eunit syntax_tools compiler
COMBO_PLT = $(HOME)/.howl_combo_dialyzer_plt

check_plt: deps compile
	dialyzer --check_plt --plt $(COMBO_PLT) --apps $(APPS) \
		deps/*/ebin apps/*/ebin

build_plt: deps compile
	dialyzer --build_plt --output_plt $(COMBO_PLT) --apps $(APPS) \
		deps/*/ebin apps/*/ebin

dialyzer: deps compile
	@echo
	@echo Use "'make check_plt'" to check PLT prior to using this target.
	@echo Use "'make build_plt'" to build PLT prior to using this target.
	@echo
	@sleep 1
	dialyzer -Wno_return --plt $(COMBO_PLT) deps/*/ebin apps/*/ebin | grep -v -f dialyzer.mittigate


cleanplt:
	@echo
	@echo "Are you sure?  It takes about 1/2 hour to re-build."
	@echo Deleting $(COMBO_PLT) in 5 seconds.
	@echo
	sleep 5
	rm $(COMBO_PLT)
