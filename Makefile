.PHONY: build

all: build

build:
	haxe -cp src/ -main visualizer.Main -js script.js
