# ---- pitc: prepended to the upstream spec by scripts/generate-spec.sh ----
# Our build sorts above the matching stock build: 3.el9 -> 3.el9.pitc
%global dist %{?dist}.pitc

BuildRequires: libsodium-devel

# Upstream's own %%configure arguments are appended after these.
# (Upstream already passes --libexecdir=%%{_libdir}; no need to repeat it.)
%global _configure ./configure --enable-argon2 --with-argon2=libsodium
