.PHONY: build build-debug

all: build

build:
	haxe build.hxml

build-debug:
	haxe build.hxml -debug

