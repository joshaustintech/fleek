# ADR 0164: Validate local ticket graphs with Spinel

Use a dependency-free Spinel Ruby command to validate local issue Markdown before commit. It checks the filename and heading number, required fields and allowed values, blocker references, and dependency cycles. `make ticket-check` is available directly; the same public contract runs in `make test` and `make check`.

Blockers remain optional because existing standalone tickets omit them. Comma- and semicolon-separated numeric references resolve within their feature; explicit `Default-check issue NN` references resolve in `fleek-default-checks`. The existing “every other unfinished ticket” wording remains a dynamic dependency. Resolved historical tickets need not contain unchecked acceptance boxes.

The check also normalizes local Markdown to the same heading and metadata fields. This lets old tickets remain useful while catching new malformed references without adding a runtime dependency or imposing timing-sensitive assertions.
