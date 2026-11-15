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

# RME cards are told apart by card_match, a substring of the
# /proc/asound/cards long name. If one card's fragment also appears in another
# card's name, Mixbay would open the wrong hardware's mixer: refuse that.
rme_lines=$(jq -r '.cards[] | select(.path|startswith("cards/rme/")) | .path' index.json)
while read -r a; do
  [[ -n $a ]] || continue
  aname=$(jq -r '.spec.display' "$a" | tr '[:lower:]' '[:upper:]')
  while read -r b; do
    [[ -n $b && $b != "$a" ]] || continue
    bname=$(jq -r '.spec.display' "$b" | tr '[:lower:]' '[:upper:]')
    while read -r m; do
      [[ -n $m ]] || continue
      up=$(printf '%s' "$m" | tr '[:lower:]' '[:upper:]')
      [[ $bname == *"$up"* ]] && err "card_match '$m' in $a also matches $b"
    done < <(jq -r '.spec.card_match[]?' "$a")
  done <<< "$rme_lines"
done <<< "$rme_lines"

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

# Profile-owned integrations (oscmix, evo-raw) are code, so they live outside
# cards/, stay pinned file by file in index.json, and must be exactly listed.
while IFS=$'\t' read -r name path version; do
  [[ -n $name ]] || continue
  [[ $name =~ ^[a-z0-9][a-z0-9-]*$ ]] || { err "unsafe integration name: $name"; continue; }
  [[ $path == "integrations/$name" && $path != *..* ]] \
    || { err "unsafe integration path: $path"; continue; }
  [[ -d $path ]] || { err "missing $path"; continue; }
  while IFS=$'\t' read -r file sha; do
    [[ -n $file ]] || continue
    [[ $file != */* && $file != *..* ]] || { err "unsafe file $file in $name"; continue; }
    [[ -f "$path/$file" ]] || { err "missing $path/$file"; continue; }
    got=$(sha256sum "$path/$file" | cut -d' ' -f1)
    [[ $got == "$sha" ]] || err "sha256 mismatch for $name/$file"
  done < <(jq -r --arg n "$name" '.integrations[$n].files | to_entries[] | [.key,.value] | @tsv' index.json)
  while IFS= read -r f; do
    rel=${f#"$path/"}
    jq -e --arg n "$name" --arg f "$rel" '.integrations[$n].files | has($f)' index.json >/dev/null \
      || err "unlisted file $f in $name"
  done < <(find "$path" -type f)
done < <(jq -r '.integrations // {} | to_entries[] | [.key,.value.path,.value.version] | @tsv' index.json)

[[ $fail -eq 0 ]] && echo "profiles: ok"
exit "$fail"
