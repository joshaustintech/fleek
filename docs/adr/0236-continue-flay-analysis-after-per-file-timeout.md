# Continue Flay analysis after per-file timeout

Accepted for Ticket 128.

For an explicit positive `--timeout` with multiple Flay sources, Fleek runs each selected source in an isolated timeout worker first. Expired workers are killed independently. Fleek then analyzes all sources that completed together, preserving cross-file duplication groups, and records each timed-out path as a failed source. The combined Flay/Reek command keeps Reek's original full input set; Flay timeout does not cancel the Reek section.

The probe uses the same process boundary as normal positive-timeout analysis because native Prism parsing is synchronous and cannot be safely interrupted in-process. Successful sources are parsed again during the final grouped analysis. This extra work is limited to explicit multi-source timeout requests; untimed and zero-timeout runs keep the direct path from [ADR 0234](0234-keep-untimed-flay-runs-on-direct-path.md). Single-source positive timeouts retain the existing whole-worker behavior.

The public contract compares pinned Flay 2.14.4's skipped-source diagnostic and retained fast-source finding with Fleek's finding, per-source scopes, coverage, status, and diagnostic. A focused mutation removes timed-out paths from the analyzable set and must make that contract fail.

Verification on Spinel `2026.09.12` (`112bae85c1a2`):

- `gmake -C "$SPINEL_ROOT" check` with GNU Make 4.4.1 first in `PATH`: 3,596 tests passed, allocation and inference checks passed, `spin-e2e: ALL GREEN`.
- `make check JOBS=8`: 77 workers passed; 8 mutation workers; Flay score 1008; Reek 0 warnings; all mutations caught.
- `make ticket-check`: passed.
- `git diff --check`: passed.
