binary := dist/pi.sh
checksums := $(patsubst src/%,dist/%,$(wildcard src/checksums/*.b2))
scripts := $(patsubst src/%,dist/%,$(wildcard src/scripts/*.sh))
targets := $(patsubst src/%,dist/%,$(wildcard src/targets/*.slist))

.PHONY: all
all: build

.PHONY: build
build: $(binary) $(checksums) $(targets) $(scripts)

clean:
	rm -rf dist/

$(binary): src/head.sh src/helpers.sh src/$(notdir $(binary)) src/tail.sh
	mkdir -p $(dir $@)
	cat $^ > $@
	chmod +x $@

dist/checksums/%.b2: src/checksums/%.b2
	mkdir -p $(dir $@)
	cp $< $@

dist/scripts/%.sh: src/scripts_head.sh src/helpers.sh src/scripts/%.sh src/scripts_tail.sh
	mkdir -p $(dir $@)
	cat $^ > $@
	chmod +x $@
	b2sum < $@ > dist/checksums/$(notdir $@).b2

dist/targets/%.slist: src/targets/%.slist
	mkdir -p $(dir $@)
	cp $< $@
	b2sum < $@ > dist/checksums/$(notdir $@).b2

# Development

excluded_warnings := 2230

.PHONY: ci
ci: clean all lint

.PHONY: lint
lint:
	shellcheck -e "$(excluded_warnings)" -s sh $$(find dist/ -type f -name "*.sh")

