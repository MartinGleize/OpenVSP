# Releasing Python wheels

The `Python wheels` GitHub Actions workflow builds and tests the four CPython
3.12 Linux x86_64 wheels. Pushes and pull requests only produce an Actions
artifact; a GitHub release is created only by an explicit manual run.

## Before releasing

- Commit and push the release candidate to `dev`.
- Confirm its `Python wheels` build is green and contains four wheels.
- Keep `dev` as the repository's default branch. GitHub only displays the
  **Run workflow** button for workflows present on the default branch.

## Create a release

1. Open **Actions** and select **Python wheels**.
2. Click **Run workflow** and select the `dev` branch.
3. Enter a new release tag:
   - Prerelease: `vX.Y.Z-dev.N`, with **prerelease** checked.
   - Stable release: `vX.Y.Z`, with **prerelease** unchecked.
4. Click **Run workflow**.

The workflow rebuilds and tests the wheels before creating the tag and release
at that exact commit. It rejects duplicate tags, mismatched versions, non-`dev`
release runs, and incomplete wheel sets.

## Verify the release

The release should contain exactly these four wheels plus `SHA256SUMS`:

- `degen_geom-*.whl`
- `openvsp-*-cp312-cp312-*.whl`
- `openvsp_config-*.whl`
- `utilities-*.whl`
- `SHA256SUMS`

To verify downloaded assets, run `sha256sum -c SHA256SUMS` in their directory.

If publishing fails with `Resource not accessible by integration`, enable
**Settings → Actions → General → Workflow permissions → Read and write
permissions** and rerun with a new tag.
