EMBEDMD ?= embedmd
EMBEDMD_VERSION ?= latest
README_FILES := $(shell find . -name README.md -not -path '*/.*')

.PHONY: docs docs-check install-embedmd

# Rewrite all README.md files in place from their embedmd directives.
docs: install-embedmd
	$(EMBEDMD) -w $(README_FILES)

# Fail (non-zero exit) if any README is out of date — useful in CI.
docs-check: install-embedmd
	$(EMBEDMD) -d $(README_FILES)

# Install embedmd only if it is not already available on PATH.
install-embedmd:
	@command -v $(EMBEDMD) >/dev/null 2>&1 || \
		go install github.com/campoy/embedmd@$(EMBEDMD_VERSION)
