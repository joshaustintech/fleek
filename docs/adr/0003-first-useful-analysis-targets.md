# Prove upstream checks before broadening coverage

The first smell target is Reek's ClassVariable detector, including reads, assignments, nested scopes, suppression, and configuration. The first duplication target is Flay's default structural matching, mass threshold, pruning, and scores. Neither searching for `@@` nor matching identical source text is a compatible substitute. Initially narrow supported syntax when necessary, but fail explicitly outside that boundary. See `../research/first-slice-feasibility.md` for source evidence and required reference cases.

Prefer reuse of a native Ruby parser over writing a new parser if a bounded Spinel integration experiment proves feasibility. Keep the CLI and analysis in Spinel Ruby and consider a minimal native adapter. The parser library and linkage are not selected; compilation, ownership, source-location fidelity, and runtime independence must be demonstrated before choosing them.

A useful first release requires parity on a small real Rails project as well as targeted fixtures. A passing toy example establishes integration only. Compare the supported selected checks over identical source and configuration; do not present partial check coverage as full replacement coverage.

Deliver in order: reproducible harness, native parser experiment, ClassVariable, default structural duplication, Rails parity, then native release. Split milestones into small test-first slices and preserve required mutation, quality, and sequential commit gates. Choose parser architecture from experiment results.
