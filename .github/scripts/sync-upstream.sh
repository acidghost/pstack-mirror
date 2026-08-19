#!/usr/bin/env bash
# Mirror the `pstack` subtree of cursor/plugins into the root of this repo,
# preserving the upstream commits that touched it.
#
# `git subtree split` rewrites those commits with the prefix stripped. It reuses
# the original author/committer metadata, so the rewrite is deterministic: every
# run reproduces the same hashes for history we already merged, and only genuinely
# new upstream commits show up. Overridable via env for testing.
set -euo pipefail

UPSTREAM_REMOTE=${UPSTREAM_REMOTE:-https://github.com/cursor/plugins.git}
UPSTREAM_BRANCH=${UPSTREAM_BRANCH:-main}
UPSTREAM_PREFIX=${UPSTREAM_PREFIX:-pstack}

die() { echo "sync-upstream: $*" >&2; exit 1; }

[ -x "$(git --exec-path)/git-subtree" ] || command -v git-subtree >/dev/null \
  || die "git-subtree is not installed"

mirror=$(git rev-parse --show-toplevel)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

git clone --quiet --single-branch --branch "$UPSTREAM_BRANCH" "$UPSTREAM_REMOTE" "$work/upstream"
upstream_head=$(git -C "$work/upstream" rev-parse HEAD)

git -C "$work/upstream" cat-file -e "HEAD:$UPSTREAM_PREFIX" 2>/dev/null \
  || die "'$UPSTREAM_PREFIX' does not exist in $UPSTREAM_REMOTE@$UPSTREAM_BRANCH"

git -C "$work/upstream" subtree split -q --prefix="$UPSTREAM_PREFIX" --branch=split >/dev/null
git -C "$mirror" fetch --quiet "$work/upstream" split
split_head=$(git -C "$mirror" rev-parse FETCH_HEAD)

if git -C "$mirror" merge-base --is-ancestor "$split_head" HEAD; then
  echo "already in sync with upstream $upstream_head"
  exit 0
fi

# Unrelated on the first run only: this repo starts with just its own CI commit.
git -C "$mirror" merge --no-edit --allow-unrelated-histories "$split_head" \
  -m "sync $UPSTREAM_PREFIX from upstream $upstream_head"

echo "merged upstream $upstream_head (split $split_head)"
