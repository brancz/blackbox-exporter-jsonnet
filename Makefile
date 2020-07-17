all: test

include .bingo/Variables.mk

test:
	$(JSONNET) -y test.jsonnet | $(KUBEVAL)
