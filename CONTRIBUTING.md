# Contributing

Keep game files, SDK artifacts, reference binaries, logs, saves, and build output
under the ignored `local/` directory. Do not commit original Unreal Gold assets.

Before submitting changes:

1. Run `scripts/check-repository.ps1`.
2. Build and run tests for the touched component.
3. Update provenance and notices for imported or generated source.
4. Describe the tested OldUnreal host version and relevant renderer settings.