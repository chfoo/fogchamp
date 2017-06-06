.PHONY: build build-debug

all: build

build:
	haxe -cp src/ -main visualizer.Main -js script.js -minify

build-debug:
	haxe -cp src/ -main visualizer.Main -js script.js -debug

