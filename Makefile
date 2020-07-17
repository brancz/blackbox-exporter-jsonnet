all: test

include .bingo/Variables.mk

test: $(JSONNET) $(KUBEVAL)
	$(JSONNET) -y test.jsonnet | $(KUBEVAL)
