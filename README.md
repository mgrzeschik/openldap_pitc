# openldap-pitc

Rocky Linux openldap + argon2 / pw-sha2 / lastbind modules, built in Copr
for EL9 and EL10 from one SRPM.

```
.copr/Makefile              Copr make_srpm entry point
.github/workflows/bump.yml  daily check for new upstream tags (optional)
scripts/prepare-sources.sh  fetch upstream tag + sources into _work/SOURCES
scripts/bump-upstream.sh    set UPSTREAM_TAG to newest tag, commit, push
openldap.pitc.spec          our additions; %include's the upstream spec
UPSTREAM_TAG                pinned upstream tag (one line)
```

## First setup
    PUSH=0 scripts/bump-upstream.sh        # fills UPSTREAM_TAG
    make -f .copr/Makefile srpm outdir=$PWD/srpm
    mock -r rocky-9-x86_64  srpm/openldap-*.src.rpm
    mock -r rocky-10-x86_64 srpm/openldap-*.src.rpm

## Copr
SCM package, build method make_srpm, subdirectory and spec empty,
auto-rebuild on, chroots for EL9 and EL10 enabled, webhook added to the repo.

## Build hooks: native vs. legacy
`openldap.pitc.spec` runs the contrib build/install after upstream's
`%build`/`%install` via native `%build -a`/`%install -a` on rpm >= 4.20, and
via `__spec_build_post`/`__spec_install_post` hooks on older rpm. EL9
(rpm 4.16) and EL10 (rpm 4.19) both use the legacy path. Once every target
has rpm >= 4.20, delete the block marked LEGACY and the `%if`/`%endif` around
the `-a` sections at the end of the spec.
