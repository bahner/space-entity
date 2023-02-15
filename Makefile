#!/usr/bin/make -ef

VERSION ?= $(shell cat mix.exs | grep version | sed -e 's/.*version: "\(.*\)",/\1/')

all: deps format compile

commited: templates
	./.check.uncommited

compile: deps
	mix compile

deps:
	mix deps.get

dialyzer:
	mix dialyzer

docs:
	mix docs
	xdg-open doc/index.html

cover:
	mix coveralls.html
	xdg-open cover/excoveralls.html

format:
	mix format

mix: all
	iex -S mix

proper: distclean compile test

push: all commited test
	git pull
	git push

release: tag
	mix hex.publish
	git push --tags

tag:
	git tag $(VERSION)

test: dialyzer
	mix test

distclean: clean
	rm -rf _build deps mix.lock

clean:
	rm -f Qm*
	rm -rf cover

.PHONY: compile docs docker test templates cover
