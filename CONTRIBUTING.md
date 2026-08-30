# Contributing

Keep game files, SDK artifacts, reference binaries, logs, saves, and build output
under the ignored `local/` directory. Do not commit original Unreal Gold assets.
Use the disposable runtime for deployment and manual testing; leave the original
Steam installation untouched.

Before submitting changes:

1. Run `powershell -NoProfile -File scripts/check-repository.ps1`.
2. Build the touched component and run the focused checks in
	[`docs/testing.md`](docs/testing.md).
3. Update provenance and notices for imported or generated source.
4. Describe the tested OldUnreal host version and relevant renderer settings.
5. Update the relevant current-state document when setup, behavior, settings,
	or validation changes.
6. Add meaningful completed work and its validation to
	[`docs/progress.md`](docs/progress.md).

Third-party imports require an immutable revision in both `THIRD_PARTY.md` and
`provenance/components.yml`, plus the applicable notice under `LICENSES/`.
CMake is the canonical renderer build path.