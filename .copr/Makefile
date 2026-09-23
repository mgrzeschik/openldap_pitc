# Copr "make_srpm" entry point: make -f .copr/Makefile srpm outdir=<dir>
TOP    := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
outdir ?= $(TOP)/srpm
WORK   := $(TOP)/_work
TAG    := $(shell cat $(TOP)/UPSTREAM_TAG)

srpm:
	rpm -q git-core curl gawk rpm-build >/dev/null || dnf -y install git-core curl gawk rpm-build
	$(TOP)/scripts/generate-spec.sh "$(TAG)" "$(WORK)"
	rpmbuild -bs "$(WORK)/openldap.spec" \
	  --define "_sourcedir $(WORK)/SOURCES" \
	  --define "_srcrpmdir $(outdir)"

.PHONY: srpm
