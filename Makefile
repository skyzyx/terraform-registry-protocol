#-------------------------------------------------------------------------------
# Global variables.

GO=go

#-------------------------------------------------------------------------------
# Running `make` will show the list of subcommands that will run.

all: help

.PHONY: help
## help: prints this help message
help:
	@echo "Usage: \n"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

#-------------------------------------------------------------------------------
# Dependencies

.PHONY: tools-go-get
## tools-go-get: [deps] installs the tools using `go get`
tools-go-get:
	go get github.com/go-delve/delve/cmd/dlv
	go get github.com/jgautheron/goconst/cmd/goconst
	go get github.com/omeid/go-resources/cmd/resources
	go get github.com/pavius/impi/cmd/impi
	go get github.com/psampaz/go-mod-outdated
	go get github.com/quasilyte/go-consistent

.PHONY: tools-linux
## tools-linux: [deps] installs the tools using Linux-friendly approaches (includes `go get` tools)
tools-linux: tools-go-get
	curl -sfSL https://install.goreleaser.com/github.com/goreleaser/goreleaser.sh | sh -s -- -b $$(go env GOPATH)/bin/goreleaser
	curl -sfSL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin # wokeignore:rule=master
	curl -sfSL https://github.com/ekalinin/github-markdown-toc.go/releases/download/1.0.0/gh-md-toc.linux.amd64.tgz

.PHONY: tools-mac
## tools-mac: [deps] installs the tools using Mac-friendly Homebrew (includes `go get` tools)
tools-mac: tools-go-get
	brew install goreleaser/tap/goreleaser
	brew install golangci/tap/golangci-lint
	brew install github-markdown-toc

#-------------------------------------------------------------------------------
# Compile

.PHONY: build-prep
## build-prep: [build] updates go.mod and downloads dependencies
build-prep:
	mkdir -p ./bin
	$(GO) mod tidy -v
	$(GO) mod download -x
	$(GO) get -v ./...

.PHONY: build-release-prep
## build-release-prep: [build] post-development, ready to release steps
build-release-prep:
	$(GO) mod download

.PHONY: build
## build: [build] compiles the source code into a native binary
build: build-prep
	$(GO) build -ldflags="-s -w  -X main.commit=$$(git rev-parse HEAD) -X main.date=$$(date -I) -X main.version=$$(cat ./VERSION | tr -d '\n')" -o bin/provider_registry_protocol *.go

.PHONY: new-golang
## new-golang: [build] installs a non-standard/future version of Golang
new-golang:
	go get golang.org/dl/$(GO)
	$(GO) download

.PHONY: graph
## graph: [build] generate a graph of the size of the binary
graph:
	@ echo "READ: https://www.cockroachlabs.com/blog/go-file-size/"
	rm -Rf graph
	git clone git@github.com:knz/go-binsize-viz.git graph
	$(GO) tool nm -size bin/mkit | c++filt > graph/symtab.txt
	cd graph && python3 tab2pydic.py symtab.txt > out.py
	cd graph && python3 simplify.py out.py > data.js
	- open http://localhost:8000/treemap_v3.html
	cd graph && python3 -m http.server

#-------------------------------------------------------------------------------
# Clean

.PHONY: clean-go
## clean-go: [clean] clean Go's module cache
clean-go:
	$(GO) clean -i -r -x -testcache -modcache -cache

.PHONY: clean
## clean: [clean] runs ALL non-Docker cleaning tasks
clean: clean-go

#-------------------------------------------------------------------------------
# Linting

.PHONY: golint
## golint: [lint] runs `golangci-lint` (static analysis, formatting) against all Golang (*.go) tests with a standardized set of rules
golint:
	@ echo " "
	@ echo "=====> Running gofmt and golangci-lint..."
	cd ./src && gofmt -s -w *.go
	cd ./src && golangci-lint run --fix *.go

.PHONY: goupdate
## goupdate: [lint] runs `go-mod-outdated` to check for out-of-date packages
goupdate:
	@ echo " "
	@ echo "=====> Running go-mod-outdated..."
	cd ./src && go list -u -m -json all | go-mod-outdated -update -direct -style markdown

.PHONY: goconsistent
## goconsistent: [lint] runs `go-consistent` to verify that implementation patterns are consistent throughout the project
goconsistent:
	@ echo " "
	@ echo "=====> Running go-consistent..."
	cd ./src && go-consistent -v ./...

.PHONY: goimportorder
## goimportorder: [lint] runs `go-consistent` to verify that implementation patterns are consistent throughout the project
goimportorder:
	@ echo " "
	@ echo "=====> Running impi..."
	cd ./src && impi --local github.mheducation.com/monitoring-as-code/monitorkit --ignore-generated=true --scheme=stdLocalThirdParty ./...

.PHONY: goconst
## goconst: [lint] runs `goconst` to identify values that are re-used and could be constants
goconst:
	@ echo " "
	@ echo "=====> Running goconst..."
	cd ./src && goconst -match-constant -numbers ./...

.PHONY: markdownlint
## markdownlint: [lint] runs `markdownlint` (formatting, spelling) against all Markdown (*.md) documents with a standardized set of rules
markdownlint:
	@ echo " "
	@ echo "=====> Running Markdownlint..."
	npx markdownlint-cli --fix '*.md' --ignore 'node_modules'

.PHONY: lint
## lint: [lint] runs ALL linting/validation tasks
lint: markdownlint golint goupdate goconsistent goconst

#-------------------------------------------------------------------------------
# Documentation and Schema

.PHONY: docs
## docs: [docs] generates the documentation for the JSON Schema
docs:
	mkdir -p docs/main/
	mkdocs build --clean --theme=material --site-dir docs/main/

.PHONY: deploy-docs
## deploy-docs: [deploy] Perform a production-mode build of the static artifacts, and push them up to GHE Pages.
deploy-docs:
	# rm -Rf /tmp/gh-pages
	# git clone git@github.mheducation.com:monitoring-as-code/monitorkit.git --branch gh-pages --single-branch /tmp/gh-pages
	# rm -Rf /tmp/gh-pages/*
	# cp -Rf ./docs/* /tmp/gh-pages/
	# touch /tmp/gh-pages/.nojekyll
	# find /tmp/gh-pages -type d | xargs chmod -f 0755
	# find /tmp/gh-pages -type f | xargs chmod -f 0644
	# cd /tmp/gh-pages/ && \
	# 	git add . && \
	# 	git commit -a -m "Automated commit on $$(date)" && \
	# 	git push origin gh-pages

.PHONY: flatten-docs
## flatten: [flatten-docs] (Optional) Flattens the git history so that git clones can be faster.
flatten-docs:
	# rm -Rf /tmp/gh-pages
	# git clone git@github.mheducation.com:monitoring-as-code/monitorkit.git --branch gh-pages --single-branch /tmp/gh-pages
	# cd /tmp/gh-pages && \
	# 	git checkout --orphan flatten && \
	# 	git add --all . && \
	# 	git commit -a -m "Flattening commit on $$(date)" && \
	# 	git branch -D gh-pages && \
	# 	git branch -m gh-pages && \
	# 	git push -f origin gh-pages

#-------------------------------------------------------------------------------
# Git Tasks

.PHONY: tag
## tag: [release] tags (and GPG-signs) the release
tag:
	@ if [ $$(git status -s -uall | wc -l) != 1 ]; then echo 'ERROR: Git workspace must be clean.'; exit 1; fi;

	@echo "This release will be tagged as: $$(cat ./VERSION)"
	@echo "This version should match your release. If it doesn't, re-run 'make version'."
	@echo "---------------------------------------------------------------------"
	@read -p "Press any key to continue, or press Control+C to cancel. " x;

	@echo " "
	@chag update $$(cat ./VERSION)
	@echo " "

	@echo "These are the contents of the CHANGELOG for this release. Are these correct?"
	@echo "---------------------------------------------------------------------"
	@chag contents
	@echo "---------------------------------------------------------------------"
	@echo "Are these release notes correct? If not, cancel and update CHANGELOG.md."
	@read -p "Press any key to continue, or press Control+C to cancel. " x;

	@echo " "

	git add .
	git commit -a -m "Preparing the $$(cat ./VERSION) release."
	chag tag --sign

.PHONY: version
## version: [release] sets the version for the next release; pre-req for a release tag
version:
	@echo "Current version: $$(cat ./VERSION)"
	@read -p "Enter new version number: " nv; \
	printf "$$nv" > ./VERSION

.PHONY: snapshot
## snapshot: [release] compiles the source code into binaries for all supported platforms
snapshot:
	goreleaser release --rm-dist --skip-publish --snapshot

.PHONY: release
## release: [release] compiles the source code into binaries for all supported platforms and prepares release artifacts
release:
	# goreleaser release --rm-dist --skip-publish
	# mv -vf dist/monitorkit.rb Formula/monitorkit.rb
	# sha256sum ./dist/monitorkit_darwin_amd64.zip
