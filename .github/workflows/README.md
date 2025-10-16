# GitHub Actions Workflows

This directory contains the GitHub Actions workflows for the Nerves Burner project.

## Workflows

### CI Workflow (`ci.yml`)

Runs on every push to `main` and on pull requests:
- Checks code formatting
- Compiles with warnings as errors
- Runs test suite
- Builds escript to verify it can be created

### Release Workflow (`release.yml`)

Runs when a version tag is pushed (e.g., `v1.0.0`):
- Builds the escript
- Creates a GitHub Release (if it doesn't exist)
- Uploads the `nerves_burner` executable as a release asset

### Demo GIF Workflow (`demo.yml`)

Runs when demo-related files are changed or manually triggered:
- Generates a demo GIF using [VHS](https://github.com/charmbracelet/vhs)
- Uses `mock_nerves_burner.sh` to simulate the CLI interaction
- Uploads the GIF as an artifact for preview
- Commits the GIF back to the repository on the `main` branch

The demo GIF is displayed in the README to help users understand how nerves_burner works before installing it.

## Creating a Release

To create a new release:

```bash
# Tag the release
git tag v1.0.0
git push origin v1.0.0
```

The workflow will automatically:
1. Build the escript
2. Create a GitHub Release for the tag
3. Upload the `nerves_burner` executable

Users can then download the pre-built executable from the Releases page without needing to install Elixir or build from source.

## Testing the Release Workflow

To test without creating an actual release, you can:
1. Create a test tag locally: `git tag v0.0.0-test`
2. Push to your fork: `git push origin v0.0.0-test`
3. Check the Actions tab to see the workflow run
4. Delete the test release and tag afterward
