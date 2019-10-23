binary := dist/pi.sh
checksums := $(patsubst src/%,dist/%,$(wildcard src/checksums/*.sha256))
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

dist/checksums/%.sha256: src/checksums/%.sha256
	mkdir -p $(dir $@)
	cp $< $@

dist/scripts/%.sh: src/scripts_head.sh src/helpers.sh src/scripts/%.sh src/scripts_tail.sh
	mkdir -p $(dir $@)
	cat $^ > $@
	chmod +x $@
	sha256sum < $@ > dist/checksums/$(notdir $@).sha256

dist/targets/%.slist: src/targets/%.slist
	mkdir -p $(dir $@)
	cp $< $@
	sha256sum < $@ > dist/checksums/$(notdir $@).sha256

# Development

excluded_warnings := 2230

.PHONY: ci
ci: clean all lint

.PHONY: lint
lint:
	shellcheck -e "$(excluded_warnings)" -s sh $$(find dist/ -type f -name "*.sh")

