#!/usr/bin/env bash
# CI-side validator for the profile repo. Mirrors the Go rules that matter for
# a PR: valid JSON, safe ids/paths, index digests, no executable payload.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
err(){ printf 'error: %s\n' "$*" >&2; fail=1; }

[[ -f index.json ]] || { echo "error: index.json missing" >&2; exit 1; }
jq -e '.schema_version == 1 and (.cards|type=="array")' index.json >/dev/null \
  || err "index.json shape"

while IFS=$'\t' read -r id path sha; do
  [[ -n $id ]] || continue
  carddir=$(dirname "$path")
  [[ $id =~ ^[a-z0-9][a-z0-9-]*$ ]] || { err "unsafe id: $id"; continue; }
  [[ $path == cards/*/card.json && $path != *..* ]] || { err "unsafe path for $id: $path"; continue; }
  [[ -f $path ]] || { err "missing $path"; continue; }
  got=$(sha256sum "$path" | cut -d' ' -f1)
  [[ $got == "$sha" ]] || err "sha256 mismatch for $id"
  jq -e --arg id "$id" '.schema_version==1 and .spec.id==$id and (.ui.preset|type=="string")' "$path" >/dev/null \
    || err "card shape for $id"
  while IFS= read -r cap; do
    [[ -n $cap ]] || continue
    [[ -f "$carddir/$cap" ]] || err "missing capture $carddir/$cap"
  done < <(jq -r '.captures[]?.file // empty' "$path")
done < <(jq -r '.cards[] | [.id,.path,.sha256] | @tsv' index.json)

if find cards -type f -perm /111 | grep -q .; then
  err "executable file inside cards/"
fi
if find cards -type f ! -name '*.json' ! -name '*.jsonl' ! -name 'NOTES.md' | grep -q .; then
  err "unexpected file type inside cards/ (expected json/jsonl/NOTES.md)"
fi

[[ $fail -eq 0 ]] && echo "profiles: ok"
exit "$fail"
