# Copr "make_srpm" entry point: make -f .copr/Makefile srpm outdir=<dir>
# One SRPM, built in both the EL9 and EL10 chroots.
TOP    := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
outdir ?= $(TOP)/srpm
WORK   := $(TOP)/_work
TAG    := $(shell head -n1 $(TOP)/UPSTREAM_TAG | tr -d '[:space:]')

srpm:
	rpm -q git-core curl rpm-build >/dev/null || dnf -y install git-core curl rpm-build
	$(TOP)/scripts/prepare-sources.sh "$(TAG)" "$(WORK)"
	cp $(TOP)/openldap.pitc.spec $(WORK)/openldap.spec
	rpmbuild -bs "$(WORK)/openldap.spec" \
	  --define "_sourcedir $(WORK)/SOURCES" \
	  --define "_srcrpmdir $(outdir)"

.PHONY: srpm
