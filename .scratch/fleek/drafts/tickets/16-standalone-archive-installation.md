# 16: Standalone archive installation

**What to build:** A user extracts a versioned macOS arm64 archive and runs the real supported checks without Ruby, Flay, or Reek installed. Parent specification: Standalone native release and performance evidence.

**Blocked by:** 14 Real Rails project parity.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Produce a versioned arm64 executable archive with executable identity, reference/compiler pins, required notices, supported scope, and verified installation instructions.
- [ ] Inspect architecture/linkage and actually run extracted help/version and clean/finding/incomplete examples where Ruby/original tools are unavailable; hiding their names alone is insufficient runtime-independence proof.
- [ ] Findings and exit statuses from the installed artifact match the proven CLI contract, including original locations and incomplete coverage.
- [ ] Archive integrity evidence identifies the exact artifact; no unbundled native dependency or source-tree-only resource is required.
- [ ] Record actual signing/distribution behavior and any missing clean-environment evidence without claiming success prematurely.
- [ ] Required build/test/quality/mutation gates pass before coherent release-related commits.
