#!/bin/bash
# Point UPSTREAM_TAG at the newest Rocky tag; commit + push if it changed.
# The push triggers the Copr webhook, which rebuilds.
set -Eeuo pipefail
trap 'echo "ERROR: line ${LINENO}: \"${BASH_COMMAND}\" failed (exit $?)" >&2' ERR
cd "$(dirname "$0")/.."

UPSTREAM=${UPSTREAM:-https://git.rockylinux.org/staging/rpms/openldap.git}
BRANCH=${BRANCH:-r10s}  # r10s = Rocky 10 tags, r9 = stock EL9 line
PREFIX="imports/${BRANCH}/"

echo "Checking $UPSTREAM for tags starting with $PREFIX"
tags=$(git ls-remote --tags --refs "$UPSTREAM" | awk '{ sub("^refs/tags/", "", $2); print $2 }')
if [ -z "$tags" ]; then
  echo "ERROR: git ls-remote returned no tags at all" >&2
  exit 1
fi

# grep exits 1 on no match; '|| true' keeps set -e/pipefail from exiting silently
new=$(printf '%s\n' "$tags" | grep -F -- "$PREFIX" | grep "^${PREFIX}" | sort -V | tail -n1 || true)
if [ -z "$new" ]; then
  echo "ERROR: no tags match $PREFIX. Prefixes that exist:" >&2
  printf '%s\n' "$tags" | cut -d/ -f1-2 | sort | uniq -c >&2
  exit 1
fi

# strip whitespace/CRLF so an edited file still compares correctly
cur=$(head -n1 UPSTREAM_TAG 2>/dev/null | tr -d '[:space:]' || true)
echo "current: ${cur:-<none>}"
echo "latest:  $new"

if [ "$new" = "$cur" ]; then
  echo "Up to date, nothing to do."
  exit 0
fi

echo "Sanity check: generating spec for $new"
scripts/generate-spec.sh "$new" _work

echo "$new" > UPSTREAM_TAG
git add UPSTREAM_TAG
git commit -m "Rebase on $new"
git push
echo "Bumped $cur -> $new and pushed."
