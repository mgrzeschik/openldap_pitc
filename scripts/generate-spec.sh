#!/bin/bash
# Build a single, flat openldap.spec + SOURCES from an upstream Rocky tag.
# Usage: scripts/generate-spec.sh <upstream-tag> <workdir>
set -euo pipefail

TAG=${1:?usage: $0 <tag> <workdir>}
OUT=${2:?usage: $0 <tag> <workdir>}
TOP=$(cd "$(dirname "$0")/.." && pwd)
UPSTREAM=${UPSTREAM:-https://git.rockylinux.org/staging/rpms/openldap.git}
# Rocky staging lookaside cache -- verify this URL, see notes.
LOOKASIDE=${LOOKASIDE:-https://rocky-linux-sources-staging.a1.rockylinux.org}
OL_RELEASES=https://www.openldap.org/software/download/OpenLDAP/openldap-release

rm -rf "$OUT"
mkdir -p "$OUT/SOURCES"
git clone --quiet --depth 1 --branch "$TAG" "$UPSTREAM" "$OUT/upstream"
UPSPEC="$OUT/upstream/SPECS/openldap.spec"

# Files tracked in dist-git (patches, configs, ...)
cp -a "$OUT/upstream/SOURCES/." "$OUT/SOURCES/"

# Tarballs listed in the metadata file: "<hash> SOURCES/<name>"
for meta in "$OUT"/upstream/.*.metadata; do
  while read -r hash path; do
    [ -n "${hash:-}" ] || continue
    name=$(basename "$path")
    dest="$OUT/SOURCES/$name"
    curl -fsSL -o "$dest" "$LOOKASIDE/$hash" \
      || curl -fsSL -o "$dest" "$OL_RELEASES/$name" \
      || { echo "ERROR: cannot fetch $name" >&2; exit 1; }
    case ${#hash} in
      64) echo "$hash  $dest" | sha256sum -c --quiet - ;;
      40) echo "$hash  $dest" | sha1sum  -c --quiet - ;;
      *)  echo "ERROR: unknown hash format for $name" >&2; exit 1 ;;
    esac
  done < "$meta"
done

if grep -q -- '--enable-argon2' "$UPSPEC"; then
  echo "WARNING: upstream now enables argon2 itself; drop the argon2 subpackage" >&2
fi

# Prepend preamble, append snippets to %build/%install, add subpackages
# before %changelog. Fails if an injection point is missing.
awk -v pre="$TOP/pitc/preamble.inc" -v bld="$TOP/pitc/build-append.inc" \
    -v ins="$TOP/pitc/install-append.inc" -v subp="$TOP/pitc/subpackages.inc" \
    -v tag="$TAG" '
function dump(f,   l) { while ((getline l < f) > 0) print l; close(f) }
function leave() {
  if (sec == "build")   { dump(bld); nb++ }
  if (sec == "install") { dump(ins); ni++ }
}
BEGIN { print "# GENERATED from " tag " -- do not edit"; dump(pre); sec = "preamble" }
/^%(package|description|prep|build|install|check|clean|files|changelog|pre|post|preun|postun|pretrans|posttrans|trigger[a-z]*|filetrigger[a-z]*|transfiletrigger[a-z]*|verifyscript|generate_buildrequires)([[:space:]]|$)/ {
  leave()
  if ($1 == "%changelog" && !ns) { dump(subp); ns++ }
  sec = substr($1, 2)
}
{ print }
END {
  leave()
  if (!ns) { dump(subp); ns++ }
  if (nb != 1 || ni != 1) {
    print "ERROR: injection failed (build=" nb+0 ", install=" ni+0 ")" > "/dev/stderr"
    exit 1
  }
}' "$UPSPEC" > "$OUT/openldap.spec"

echo "Generated $OUT/openldap.spec from $TAG"
