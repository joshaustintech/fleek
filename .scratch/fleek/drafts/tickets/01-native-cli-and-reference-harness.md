# 01: Native CLI and reference harness

**What to build:** A developer can build the pinned native executable, inspect help/version, and run reproducible reference and quality checks without inventing commands. Parent specification: Native foundation.

**Blocked by:** None (can start immediately).

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Build Spinel 2026.09.12 at the accepted commit; report version, actual vendored parser identity, and native executable identity. Prevent ambient parser drift.
- [ ] Lock accepted Flay/Reek versions and commits, reference Ruby, and exact dependencies; execute a real shared-syntax reference fixture reproducibly.
- [ ] Native explicit help exits 0; no arguments emits usage to stderr and exits 1. Unknown options and unimplemented analysis cannot report clean success.
- [ ] Establish documented commands for full native build/tests, reference execution, zero-finding Flay/Reek checks, and meaningful mutation checks. Every project helper is pinned Spinel Ruby.
- [ ] Demonstrate a failing usage test before implementation and a detected status mutation afterward. Required gates pass before each coherent commit and direct push to main.
