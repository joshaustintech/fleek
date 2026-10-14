# Separate language support from reference equivalence

Target Ruby 4.0 explicitly rather than a moving latest grammar. Also support source accepted by pinned Spinel 2026.09.12, including documented syntax extensions. Analyze original source without executing it or loading its dependencies, and preserve original source locations. Ordinary Ruby input does not have to compile under Spinel.

Stock Reek's permitted parser does not establish Ruby 4 grammar support, while a native Prism grammar alone does not prove equivalent detector or duplication behavior. Retain unchanged pinned originals as references for shared syntax. For Ruby 4-only syntax, use separately reviewed expected findings and label extension tests explicitly; do not describe them as stock-Reek parity. Any modified reference must be independently validated before relying on it. See `../research/ruby4-spinel-input.md` for versioned evidence.

The native parser experiment must demonstrate explicit language selection, accepted and rejected examples, original locations, comments, ownership, deterministic parsing, AST fidelity, and standalone native execution. Select the parser and exact dependency locks from that evidence; these remain implementation prerequisites, not completed work. Unsupported syntax must fail explicitly rather than be silently skipped.
