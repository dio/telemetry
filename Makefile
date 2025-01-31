# Copyright 2022 Tetrate
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

MODULE_PATH ?= $(shell sed -ne 's/^module //gp' go.mod)

# Tools
LINTER    := github.com/golangci/golangci-lint/cmd/golangci-lint@v1.43.0
LICENSER  := github.com/liamawhite/licenser@v0.6.1-0.20210729145742-be6c77bf6a1f
GOIMPORTS := golang.org/x/tools/cmd/goimports@v0.1.5

.PHONY: build
build:
	go build ./...

TEST_OPTS ?= -race
.PHONY: test
test:
	go test $(TEST_OPTS) ./...

BENCH_OPTS ?=
.PHONY: bench
bench:
	go test -bench=. $(BENCH_OPTS) ./...

.PHONY: coverage
coverage:
	mkdir -p build
	go test -coverprofile build/coverage.out -covermode atomic -coverpkg '$(MODULE_PATH)/...' ./...
	go tool cover -o build/coverage.html -html build/coverage.out

LINT_OPTS ?= --timeout 5m
.PHONY: lint
lint:
	go run $(LINTER) run $(LINT_OPTS) --config .golangci.yml

GO_SOURCES = $(shell git ls-files | grep '.go$$')
.PHONY: format
format:
	@for f in $(GO_SOURCES); do \
		awk '/^import \($$/,/^\)$$/{if($$0=="")next}{print}' "$$f" > /tmp/fmt; \
		mv /tmp/fmt "$$f"; \
	done
	go run $(GOIMPORTS) -w -local $(MODULE_PATH) $(GO_SOURCES)
	go run $(LICENSER) apply -r "Tetrate"

.PHONY: check
check:
	@$(MAKE) format
	@go mod tidy
	@if [ ! -z "`git status -s`" ]; then \
		echo "The following differences will fail CI until committed:"; \
		git diff; \
		exit 1; \
	fi
