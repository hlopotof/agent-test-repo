#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <commit-sha> [<commit-sha> ...]" >&2
  exit 1
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
