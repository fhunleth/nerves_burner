# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
- Automatic version checking at startup
  - Checks GitHub releases for newer versions of nerves_burner
  - Prompts user to download new version if available
  - Shows download location and instructions to run manually
  - Gracefully handles errors with warnings
  - Silently skips check if network issues or rate limiting occurs

## v0.1.0 - 2025-10-10

Initial release
