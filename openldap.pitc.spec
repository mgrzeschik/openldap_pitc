# pitc additions on top of the Rocky Linux openldap spec (EL9 + EL10).
#
# The upstream spec is shipped inside the SRPM as Source9999 and included at
# the end of this preamble. Our build/install steps run through rpm's
# __spec_build_post / __spec_install_post hooks, i.e. after upstream's whole
# %%build / %%install body -- no text patching of the upstream spec.
# Works with rpm 4.16 (EL9) and 4.19 (EL10).

# Our build sorts above the matching stock build: 1.el9 -> 1.el9.pitc
%global dist %{?dist}.pitc

# Deliberately not named *.spec: Copr imports the SRPM into dist-git, which
# requires exactly one .spec file in the package.
Source9999: openldap.upstream.inc

# argon2 via libargon2 (part of EL9/EL10, no EPEL needed at build or runtime)
BuildRequires: libargon2-devel
# Upstream's own %%configure arguments are appended after these.
%global _configure ./configure --enable-argon2 --with-argon2=libargon2

# Contrib modules built on top of the main tree (%%define = expanded lazily,
# after upstream has set %%{version})
%global pitc_modules passwd/sha2 lastbind
%define pitc_ltver\
pitc_ltver="$(. ./openldap-%{version}/build/version.var && echo "${ol_api_current}:${ol_api_revision}:${ol_api_age}")"\
case "$pitc_ltver" in [0-9]*:[0-9]*:[0-9]*) ;; *) echo "pitc: cannot read LTVER from build/version.var ('$pitc_ltver')" >&2; exit 1 ;; esac\
%{nil}

%define pitc_build_post\
echo "pitc: building contrib modules"\
cd "%{_builddir}/%{?buildsubdir}"\
%{pitc_ltver}\
for m in %{pitc_modules}; do\
  %{make_build} -C "openldap-%{version}/contrib/slapd-modules/$m" prefix=%{_prefix} libexecdir=%{_libdir} LTVER="$pitc_ltver" OPT="%{optflags}" LDFLAGS="%{?build_ldflags}"\
done\
%{nil}

%define pitc_install_post\
echo "pitc: installing contrib modules"\
cd "%{_builddir}/%{?buildsubdir}"\
%{pitc_ltver}\
for m in %{pitc_modules}; do\
  %{make_install} -C "openldap-%{version}/contrib/slapd-modules/$m" prefix=%{_prefix} libexecdir=%{_libdir} LTVER="$pitc_ltver"\
done\
find %{buildroot}%{_libdir}/openldap -name '*.la' -delete\
for f in argon2 pw-sha2 lastbind; do\
  if ! ls %{buildroot}%{_libdir}/openldap/$f.so* >/dev/null 2>&1; then\
    echo "pitc: $f.so missing in %{_libdir}/openldap; found instead:" >&2\
    find %{buildroot} -name "$f*" >&2 || true\
    exit 1\
  fi\
done\
%{nil}

# Hook in front of rpm's own post steps. macrobody captures the raw default
# body, which is expanded lazily later, so debuginfo, brp-* scripts etc.
# keep working exactly as on the running rpm version.
%global pitc_orig_build_post %{macrobody:__spec_build_post}
%global pitc_orig_install_post %{macrobody:__spec_install_post}

%define __spec_build_post\
%{pitc_build_post}\
%{pitc_orig_build_post}

%define __spec_install_post\
%{pitc_install_post}\
%{pitc_orig_install_post}

%include %{SOURCE9999}

%package argon2
Summary: Argon2 password hashing module for slapd
License: OLDAP-2.8
Requires: openldap-servers%{?_isa} = %{version}-%{release}

%description argon2
Argon2 password hashing module for the OpenLDAP server.

%package pw-sha2
Summary: SHA-2 password hashing module for slapd
License: OLDAP-2.8
Requires: openldap-servers%{?_isa} = %{version}-%{release}

%description pw-sha2
SHA-256/384/512 password hashing module (contrib) for the OpenLDAP server.

%package lastbind
Summary: lastbind overlay for slapd
License: OLDAP-2.8
Requires: openldap-servers%{?_isa} = %{version}-%{release}

%description lastbind
lastbind overlay (contrib) for the OpenLDAP server.

%files argon2
%{_libdir}/openldap/argon2.so*

%files pw-sha2
%{_libdir}/openldap/pw-sha2.so*

%files lastbind
%{_libdir}/openldap/lastbind.so*
