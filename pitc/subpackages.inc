# ---- pitc: inserted before upstream's %%changelog ----
%package argon2
Summary: Argon2 password hashing module for slapd
License: OLDAP-2.8
Requires: openldap-servers%{?_isa} = %{version}-%{release}

%description argon2
Argon2 password hashing module (libsodium backend) for the OpenLDAP server.

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

