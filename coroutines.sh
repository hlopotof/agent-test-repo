#!/usr/bin/env bash

set -euo pipefail

default_commits=(
  82613aebb7d5c953c326afdece0ff8c6e9311ca9
)

if [[ $# -eq 0 ]]; then
  if [[ ${#default_commits[@]} -eq 0 ]]; then
    echo "No commits specified and default list empty; aborting." >&2
    exit 1
  fi
  set -- "${default_commits[@]}"
fi

while [[ $# -gt 0 ]]; do
  commit="$1"
  shift

  echo "Applying commit ${commit}"
  if git cherry-pick -X theirs "${commit}"; then
    continue
  fi

  status=$?
  echo "Cherry-pick ${commit} exited with ${status}. Resolving by forcing commit content."
  git status --short

  conflict_files=$(git diff --name-only --diff-filter=U)
  if [[ -z "${conflict_files}" ]]; then
    echo "No conflict files detected, aborting cherry-pick." >&2
    git cherry-pick --abort
    exit "${status}"
  fi

  while IFS= read -r path; do
    [[ -z "${path}" ]] && continue
    echo "Forcing ${path} from commit ${commit}"
    git checkout --theirs "${path}"
    git add "${path}"
  done <<<"${conflict_files}"

  git cherry-pick --continue
done
