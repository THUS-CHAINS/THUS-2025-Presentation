SLIDE_DIR  := src/slides/asciidoc
SITE_DIR := build/site
BOOK_DIR := build/book
RESOURCE_SOURCE_DIR := static
RESOURCE_TARGET_DIR := $(SITE_DIR)/

# Reveal.js
REVEALJS_CACHE_DIR := build/.cache/reveal.js
REVEALJS_DIR := $(SITE_DIR)/reveal.js

SLIDE_SOURCES := $(wildcard $(SLIDE_DIR)/*.adoc)
SLIDE_TARGETS := $(patsubst $(SLIDE_DIR)/%.adoc, $(SITE_DIR)/%.html, $(SLIDE_SOURCES))

.PHONY: clean slides book serve install update

# -r asciidoctor-kroki \

$(SITE_DIR)/%.html: $(SLIDE_DIR)/%.adoc 
	@echo '[Generating Reveal.js website]'
	bundle exec asciidoctor-revealjs \
		-r asciidoctor-diagram \
		--attribute slides \
		--attribute kroki-fetch-diagram=true \
		--attribute kroki-server-url=http://kroki:8000 \
		--attribute kroki-plantuml-include=../../../resources/defaults/plantuml/puml-theme-sober.puml \
		--attribute kroki-plantuml-include-paths=../../../resources/defaults/plantuml/ \
		--attribute kroki-default-format=svg \
		--attribute plantuml-includedir=../../../resources/defaults/plantuml/ \
		--attribute plantuml-preprocess=true \
		--attribute plantuml-config=../../../resources/defaults/plantuml/puml-theme-sober.puml \
		--attribute diagram-format=svg \
		-v \
		-o $@ $<

$(BOOK_DIR)/book.pdf: src/book/asciidoc/book.adoc
	@echo '[Generating PDF files]'
	bundle exec asciidoctor-pdf \
		-r asciidoctor-diagram \
		--attribute javasources=../../../main/java \
		--attribute book \
		--attribute font-size=10 \
		--attribute allow-uri-read=true \
		--attribute plantuml-preprocess=true \
		--attribute imagesdir=../../../static/images \
		--attribute plantuml-config=../../../resources/defaults/plantuml/puml-theme-sober.puml \
		--attribute pdf-theme=./resources/antora-workbook-theme/pdf-theme.yml \
		--attribute pdf-fontsdir=./resources/antora-workbook-theme/pdffonts \
		-o $@ $<

slides: resources $(SLIDE_TARGETS)
	bundle exec asciidoctor-revealjs --version

book: $(BOOK_DIR)/book.pdf

resources: prepare 
	@echo '[Preparing resources]'
	rsync -r $(RESOURCE_SOURCE_DIR)/  $(RESOURCE_TARGET_DIR)

prepare: $(REVEALJS_DIR)

$(REVEALJS_CACHE_DIR):
	git clone -b 4.5.0 --depth 1 https://github.com/hakimel/reveal.js.git $(REVEALJS_CACHE_DIR) 2> /dev/null || (cd $(REVEALJS_CACHE_DIR) ; git pull)
	mkdir -p $(SITE_DIR)/reveal.js

$(REVEALJS_DIR): $(REVEALJS_CACHE_DIR)
	rsync -r -r $(REVEALJS_CACHE_DIR)/dist $(REVEALJS_DIR)
	rsync -r -r $(REVEALJS_CACHE_DIR)/plugin $(REVEALJS_DIR)

clean:
	rm -rf build

serve:
	live-server --browser=librewolf ./build/site	&

install:
	bundle install

update:
	git submodule update --remote --merge