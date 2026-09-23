# ---- pitc: appended to the end of %%build ----
cd "%{_builddir}/%{?buildsubdir}"
pitc_ltver="$(. ./openldap-%{version}/build/version.var && echo "${ol_api_current}:${ol_api_revision}:${ol_api_age}")"
for m in passwd/sha2 lastbind; do
  %make_build -C "openldap-%{version}/contrib/slapd-modules/$m" \
    prefix=%{_prefix} libexecdir=%{_libdir} LTVER="$pitc_ltver" \
    OPT="%{optflags}" LDFLAGS="%{build_ldflags}"
done
