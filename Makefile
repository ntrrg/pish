excluded_warnings := 2230
binary := dist/pi.sh

src := $(wildcard src/scripts/*.sh)
scripts := $(patsubst src/%,dist/%,$(src))

trg := $(wildcard src/targets/*.slist)
targets := $(patsubst src/%,dist/%,$(trg))

.PHONY: all
all: build

.PHONY: build
build: $(targets) $(binary) $(scripts)

clean:
	rm -rf dist/

# Development

.PHONY: ci
ci: clean all

$(binary): src/head.sh src/helpers.sh src/$(notdir $(binary)) src/tail.sh
	mkdir -p $(dir $@)
	cat $^ > $@
	shellcheck -e "$(excluded_warnings)" -s sh $@
	chmod +x $@

dist/scripts/%.sh: src/scripts_head.sh src/helpers.sh src/scripts/%.sh src/scripts_tail.sh
	mkdir -p $(dir $@)
	cat $^ > $@
	shellcheck -e "$(excluded_warnings)" -s sh $@
	chmod +x $@

dist/targets/%.slist: src/targets/%.slist
	mkdir -p $(dir $@)
	cp $< $@

