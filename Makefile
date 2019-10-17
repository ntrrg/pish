binary := dist/pi.sh
scripts := $(patsubst src/%,dist/%,$(wildcard src/scripts/*.sh))
targets := $(patsubst src/%,dist/%,$(wildcard src/targets/*.slist))

.PHONY: all
all: build

.PHONY: build
build: $(binary) $(targets) $(scripts)

clean:
	rm -rf dist/

$(binary): src/head.sh src/helpers.sh src/$(notdir $(binary)) src/tail.sh
	mkdir -p $(dir $@)
	cat $^ > $@
	chmod +x $@

dist/scripts/%.sh: src/scripts_head.sh src/helpers.sh src/scripts/%.sh src/scripts_tail.sh
	mkdir -p $(dir $@)
	cat $^ > $@
	chmod +x $@

dist/targets/%.slist: src/targets/%.slist
	mkdir -p $(dir $@)
	cp $< $@

# Development

excluded_warnings := 2230

.PHONY: ci
ci: clean all lint

.PHONY: lint
lint:
	shellcheck -e "$(excluded_warnings)" -s sh $$(find dist/ -type f -name "*.sh")

