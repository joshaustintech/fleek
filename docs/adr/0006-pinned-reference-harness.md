# Pin reference analyzers as locked gem artifacts

Flay 2.14.4 and Reek 6.6.0 are the reference tools for comparisons. Run them under Ruby 3.4.9 with the complete Bundler lock and checksums in `Gemfile.lock`; resolve source tags to commits and record the published gem identities rather than relying on moving branches. The fixture is run by both tools from `make reference`; project code has separate zero-finding gates.

The first fixture currently produces Flay score 0 and no Reek warnings. That verifies repeatable execution on shared Ruby syntax only; it makes no claim about behavior parity. Future parity tickets must record matching inputs, options, findings, locations, scores, and exit status and explain any differences.

## Evidence

- Ruby 3.4.9, arm64-darwin23.
- Flay v2.14.4 resolves to `1ec4d87f2209a3ae216aece69a4ecc8b688cd459`.
- Reek v6.6.0 is an annotated tag resolving to `e0048db109ea13630630bf130492025cd1c786a5` (tag object `4eb1990eab1cc88cf7f778460fa7ef7622ea01f1`).
- Gem artifact checksums and transitive dependency versions are in `Gemfile.lock`.
