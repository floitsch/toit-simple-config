FILES = config-js.toit index-html.toit styles-css.toit
OUT_FILES = $(FILES:%=src/html/%)

.PHONY: all
all: $(OUT_FILES)

# A function to convert a file to a toit file.
define convert
$(1): $(2) src/html
	@echo "Converting $$< to $$@"
	@toit in/convert.toit $$< > $$@
endef

src/html:
	@mkdir -p src/html

$(eval $(call convert,src/html/config-js.toit,in/config.js))
$(eval $(call convert,src/html/index-html.toit,in/index.html))
$(eval $(call convert,src/html/styles-css.toit,in/styles.css))

.PHONY: rebuild-cmake
rebuild-cmake:
	@cmake -B build -S .

.PHONY: test
test: rebuild-cmake $(OUT_FILES)
	@cmake --build build --target check
