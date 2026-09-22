---
name: release
description: |
  Covers: Version bump workflow, GitHub tagging, GitHub releases, and Hex publishing.
  Consult when: Cutting a new kagi_ex release, bumping @version, or recovering a failed release.
  Not covered: Day-to-day development (see README.md), CI implementation details (see .github/workflows/*.yml).
---

# Release

`kagi_ex` releases have two parts:

1. GitHub tag and release
2. Hex publication, with docs published automatically

## Quick Reference

| Step                         | Trigger           | Output                          |
| ---------------------------- | ----------------- | ------------------------------- |
| Bump `@version` in `mix.exs` | PR to `main`      | Release candidate commit        |
| Merge version bump to `main` | `release.yml`     | `vX.Y.Z` tag and GitHub release |
| Publish package              | `mix hex.publish` | Hex package and HexDocs docs    |

## Version Bump Rules

- Bump [mix.exs](mix.exs) `@version` only when that merge should create a release.
- Update [CHANGELOG.md](CHANGELOG.md) in the same PR.
- No new version means no tag and no GitHub release.

## Automated GitHub Release

After the version-bump PR is merged to `main`:

1. `.github/workflows/release.yml` reads the `mix.exs` version on every push to `main`.
2. If the tag `vX.Y.Z` does not exist, the workflow creates and pushes it.
3. The same workflow publishes a GitHub release for `vX.Y.Z`.

The decision uses the tag, not the parent commit. Runs go one at a time, so a run sees the tag that the run before it pushed. If a run stops before it pushes the tag, the next push to `main` creates the tag and the release. That tag points at the commit of the repairing push, not at the version-bump commit. If the tag exists but the release does not, run the workflow by hand with that tag. A tag that you delete by hand comes back on the next push.

Use the workflow's manual dispatch only to re-run a release for the current version tag after fixing workflow issues.

## Exact Hex Release Steps

Run these steps only after the GitHub release for the same version exists.

### 1. Refresh local checkout after the GitHub release workflow finishes

```bash
git fetch origin
git switch --detach origin/main
```

### 2. Verify the package from the exact publishing tree

```bash
mix hex.build
mix docs
```

### 3. Publish the package

```bash
mix hex.publish
```

## Gotchas

- Do not publish to Hex before the matching GitHub release exists.
- Do not reuse versions. Hex versions are immutable.
- `mix hex.publish` publishes documentation automatically.
