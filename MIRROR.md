# About this mirror

The repository content is a mirror of the [`pstack`](https://github.com/cursor/plugins/tree/main/pstack)
subtree of [cursor/plugins](https://github.com/cursor/plugins), with `pstack/` lifted to the root.
Upstream is the only source of truth — send changes there, not here.

The upstream commits that touched `pstack/` are kept, so `git log` and `git blame` work as they
do upstream. Only the mirror's own `.github/` and this file are local additions; they sit on
`main` alongside the mirrored history.

## How it works

[`.github/workflows/sync-upstream.yml`](.github/workflows/sync-upstream.yml) runs
[`.github/scripts/sync-upstream.sh`](.github/scripts/sync-upstream.sh) nightly, which:

1. clones upstream,
2. `git subtree split --prefix=pstack` to rewrite that directory's history with files at the root,
3. merges the result into `main` and pushes.

The split is deterministic, so step 3 only ever brings in commits that are genuinely new upstream —
no force-pushes, no rewritten hashes.

## Running it by hand

Any clone with the full history works; `git-subtree` must be installed:

```sh
.github/scripts/sync-upstream.sh && git push origin main
```

`UPSTREAM_REMOTE`, `UPSTREAM_BRANCH`, and `UPSTREAM_PREFIX` override the defaults.

## Things that will break it

- **Upstream rewrites history** (force-push, rebase) or **moves `pstack/`**: the split produces
  different hashes and the merge will conflict or fork the history. Fix by hand, deliberately.
- **GitHub disables the schedule**: scheduled workflows are turned off after 60 days without
  repository activity. A quiet upstream means no pushes here, so re-enable it in the Actions tab
  (or dispatch the workflow) if the mirror goes stale.
