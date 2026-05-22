# Watermarked by tc from github.com/sigil-enterprises/sigil-toolchain@v0.39.2
#
# type.mk for lib — managed by toolchain
# Required: setup, setup-dev, lint, test, coverage, docs

_check_required:
	@$(MAKE) --dry-run setup    2>/dev/null || (echo "ERROR: 'setup' target not implemented" && exit 1)
	@$(MAKE) --dry-run lint     2>/dev/null || (echo "ERROR: 'lint' target not implemented" && exit 1)
	@$(MAKE) --dry-run test     2>/dev/null || (echo "ERROR: 'test' target not implemented" && exit 1)
	@$(MAKE) --dry-run coverage 2>/dev/null || (echo "ERROR: 'coverage' target not implemented" && exit 1)
	@$(MAKE) --dry-run docs     2>/dev/null || (echo "ERROR: 'docs' target not implemented" && exit 1)
