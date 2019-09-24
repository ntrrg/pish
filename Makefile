binary := pi.sh
src := $(wildcard src/scripts/*.sh)
scripts := $(patsubst src/%,%,$(src))

.PHONY: all
all: $(binary) $(scripts)

clean:
	rm -rf $(binary) scripts/

# Development

.PHONY: ci
ci: clean all

$(binary): src/head.sh src/helpers.sh src/$(binary) src/tail.sh
	cat $^ > $@
	shellcheck -s sh $@
	chmod +x $@

scripts/%.sh: src/scripts_head.sh src/helpers.sh src/scripts/%.sh src/scripts_tail.sh
	mkdir -p scripts
	cat $^ > $@
	shellcheck -s sh $@
	chmod +x $@

