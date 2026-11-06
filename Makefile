.PHONY: lint
lint:
	luacheck ./lua

.PHONY: format-check
format-check:
	stylua --check lua

.PHONY: test
test:
	vusted --output=gtest ./lua

.PHONY: pre-commit
pre-commit:
	luacheck lua
	vusted lua

.PHONY: integration
integration:
	luacheck lua
	vusted lua
