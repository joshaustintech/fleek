# ADR 0195: Deduplicate Flay source paths

## Status

Accepted for Ticket 57.

## Context

Flay 2.14.4 expands existing directory arguments through PathExpander 2.0.1, lexically cleans paths with `Pathname#cleanpath`, and removes duplicate expanded file paths before analysis. Ruby's directory glob skips hidden subdirectories. Fleek recursively discovers visible Ruby files but previously retained overlaps when a directory and one of its files were both requested, and when equivalent relative paths were supplied. The pinned tool preserves absolute and relative spellings as distinct source identities, even when they resolve to the same file. It keeps `.` and parent-relative `../` paths relative in reports.

PathExpander also has surprising unmatched-argument behavior: a nonexistent, empty, or literal-glob argument is treated like an unrecognized option. If no real path was selected, it scans the current directory. Flay does not expand a literal glob passed directly in argv. Flay follows an explicitly supplied symlink to a directory. Fleek's existing input policy instead fails unresolved paths and refuses explicit directory symlinks.

## Decision

Normalize existing Flay path arguments lexically with the same cleanpath behavior, deduplicate the arguments, then normalize and deduplicate discovered Flay source paths after directory traversal. This preserves Flay's source identity for overlapping directories, explicit files, `./`, `.`, and parent-relative forms.

Keep Fleek's fail-closed behavior for missing, empty, and literal glob inputs rather than silently ignoring them or scanning the current directory. This explicitly accepts an input-safety exception to the path-parity requirement: Flay treats empty and unmatched-pattern arguments like unknown arguments and may scan the current directory, while Fleek reports incomplete input. Spec 04 records this as an accepted terminal exception, not an unresolved child or completed parity claim. Keep rejecting explicit directory symlinks rather than following them; ADR 0011 already defines that safety policy. Do not change Reek source discovery through the Flay-specific normalization path.

## Consequences

Valid directory and file arguments select the same source identities as Flay: repeated lexical spellings collapse, while absolute and relative spellings remain distinct and `.`/`../` stay relative. Hidden directory contents are skipped. Findings and scores no longer count repeated relative source paths multiple times. Missing, empty, and literal-glob inputs plus explicit directory symlinks retain Fleek's existing fail-closed behavior even where Flay ignores, falls back, or follows.

## Evidence

The compiled public contract compares overlapping directory/file inputs and Flay's verbose selected-file list, checks `.`, parent-relative, absolute/relative, and empty path arguments, and records Flay/Fleek outcomes for hidden contents, mixed valid/missing paths, literal glob argv, and explicit directory symlinks. Its overlap case confirms pinned Flay keeps absolute and relative identities distinct while collapsing repeated relative spellings. `Flay path deduplication`, `Flay lexical path normalization`, and `Flay empty path safety` mutations are caught by the contract.
