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
2. Hex publication with its docs, which waits for an owner's approval on hex.pm

## Quick Reference

| Step                         | Trigger          | Output                                 |
| ---------------------------- | ---------------- | -------------------------------------- |
| Bump `@version` in `mix.exs` | PR to `main`     | Release candidate commit               |
| Merge version bump to `main` | `release.yml`    | `vX.Y.Z` tag and GitHub release        |
| GitHub release succeeds      | `release.yml`    | Hex package and docs, staged           |
| Approve the staged release   | hex.pm, with 2FA | Hex package and HexDocs docs published |

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

Use the workflow's manual dispatch only to re-run a release for the current version tag after fixing workflow issues. The dispatch fails when the tag does not exist or its `mix.exs` has another `@version`.

## Hex Release

When the GitHub release job succeeds, the `Publish to Hex` job of `.github/workflows/release.yml` checks out the tag `vX.Y.Z` and runs `mix hex.publish --yes`, which uploads the package and its docs. It publishes the tag, not `main`: a PR that merges after the version bump would otherwise ship untagged code as `vX.Y.Z`, while the HexDocs source links point at the tag.

The job stores no Hex key. It runs in the GitHub environment `hex`, which only `main` can use, and Hex exchanges the job's OIDC token for a token that can only publish `kagi_ex`. For that, the package has a workload identity on hex.pm, in its tab "Workload identities": repository owner `rubas`, repository `kagi_ex`, workflow `release.yml`, environment `hex`. Only a full owner of the package can add or change it.

The package has staged publishing on. Hex holds each release from the job, and the job ends with `Package staged for approval at <url>`. A package owner approves it on hex.pm with their 2FA, within 7 days. The job does not wait for that approval: a GitHub job stops after 6 hours.

When the job fails for a cause outside the repo, such as hex.pm or the workload identity, fix it and re-run the job. It publishes the same tag. A cause in the tag needs a new patch version. After a fix of the job itself, dispatch the workflow with the tag. The job fails when the log says `Publishing failed` or `Publishing docs failed`, because `mix hex.publish` exits 0 when only the docs upload fails.

## Gotchas

- Do not reuse versions. Hex versions are immutable.
- A manual dispatch publishes too, after its GitHub release. For a version that Hex already holds, the publish job fails and changes nothing.
