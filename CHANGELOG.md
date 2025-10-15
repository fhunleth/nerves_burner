# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
- Automatic version checking at startup
  - Checks GitHub releases for newer versions of nerves_burner
  - Displays current version below banner at startup
  - Prompts user to download new version if available
  - Automatically attempts to replace existing version after download
  - Falls back to manual instructions if auto-replacement fails
  - Gracefully handles errors with warnings
  - Silently skips check if network issues or rate limiting occurs
  - `NERVES_BURNER_FORCE_UPDATE` environment variable to force update check for testing

## v0.1.0 - 2025-10-10

Initial release
