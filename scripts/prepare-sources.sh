#!/bin/bash
# Fetch the upstream Rocky dist-git at a tag and lay out everything
# rpmbuild needs: <workdir>/SOURCES/* (incl. openldap.upstream.spec)
# Usage: scripts/prepare-sources.sh <upstream-tag> <workdir>
set -Eeuo pipefail
trap 'echo "ERROR: line ${LINENO}: \"${BASH_COMMAND}\" failed" >&2' ERR

TAG=${1:?usage: $0 <tag> <workdir>}
OUT=${2:?usage: $0 <tag> <workdir>}
UPSTREAM=${UPSTREAM:-https://git.rockylinux.org/staging/rpms/openldap.git}
# Rocky staging lookaside cache -- verify this URL
LOOKASIDE=${LOOKASIDE:-https://rocky-linux-sources-staging.a1.rockylinux.org}
OL_RELEASES=https://www.openldap.org/software/download/OpenLDAP/openldap-release

rm -rf "$OUT"
mkdir -p "$OUT/SOURCES"
git init --quiet "$OUT/upstream"
git -C "$OUT/upstream" fetch --quiet --depth 1 "$UPSTREAM" "$TAG"
git -C "$OUT/upstream" checkout --quiet FETCH_HEAD
UPSPEC="$OUT/upstream/SPECS/openldap.spec"

# Files tracked in dist-git (patches, configs, ...)
cp -a "$OUT/upstream/SOURCES/." "$OUT/SOURCES/"
cp "$UPSPEC" "$OUT/SOURCES/openldap.upstream.spec"

# Tarballs listed in the metadata file: "<hash> SOURCES/<name>"
for meta in "$OUT"/upstream/.*.metadata; do
  [ -e "$meta" ] || continue
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

# Guards: things that would silently break our hooks or packaging
if grep -qE '__spec_(build|install)_post' "$UPSPEC"; then
  echo "ERROR: upstream spec redefines __spec_*_post; our hooks would be lost" >&2
  exit 1
fi
for w in enable-argon2 passwd/sha2 lastbind; do
  if grep -q -- "$w" "$UPSPEC"; then
    echo "WARNING: upstream spec now mentions '$w'; check for duplicate files/subpackages" >&2
  fi
done

echo "Prepared $OUT/SOURCES from $TAG"
