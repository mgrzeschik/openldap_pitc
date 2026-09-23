# ---- pitc: appended to the end of %%install ----
echo "pitc: installing contrib modules"
cd "%{_builddir}/%{?buildsubdir}"
pitc_ltver="$(. ./openldap-%{version}/build/version.var && echo "${ol_api_current}:${ol_api_revision}:${ol_api_age}")"
for m in passwd/sha2 lastbind; do
  %make_install -C "openldap-%{version}/contrib/slapd-modules/$m" \
    prefix=%{_prefix} libexecdir=%{_libdir} LTVER="$pitc_ltver"
done
find %{buildroot}%{_libdir}/openldap -name '*.la' -delete
# Fail here with a useful message instead of at %%files time
for f in argon2 pw-sha2 lastbind; do
  if ! ls %{buildroot}%{_libdir}/openldap/$f.so* >/dev/null 2>&1; then
    echo "pitc: $f.so not in %{_libdir}/openldap; found instead:" >&2
    find %{buildroot} -name "$f*" >&2 || true
    exit 1
  fi
done
