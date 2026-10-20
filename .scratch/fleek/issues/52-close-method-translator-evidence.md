# 52: Finish descriptor and composed-method evidence

**What to build:** Tickets 43 and 22 can be judged against a complete descriptor/adapter evidence matrix instead of more isolated syntax additions.

**Part of:** Ticket 43 / 22.

**Blocked by:** 48; 49; 50; 51; 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Inventory accepted body/parameter descriptors against support, child traversal, equality and mass dispatch. For each remaining adapter cite its Prism/RubyParser representation difference and public contract. Record each duplicate rule or uncovered accepted shape as a separate minimal follow-up; this ticket audits and verifies, it does not perform a broad rewrite. Attach full-gate and both review-axis receipts only after residual children resolve.

## Starting evidence

ADR 0160 translator completion boundary; descriptor inventory and generated contract from ticket 42; existing standards/spec review workflow.

## Acceptance criteria

- [x] Listed behavior cases have reproducible inputs, pinned expected results and matching public behavior. Inventory-only work records evidence and concrete child links; completion gates remain open until every required residual gap resolves.
- [x] Semantic findings, coverage, streams and normalized outcome are asserted where applicable; evidence-only inventories distinguish verified rows from unresolved work.
- [x] Relevant regression/mutation or evidence checks pass; Answer records exact commands and remaining issue links.
- [x] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

## Answer

The descriptor audit found complete generated support and public Flay parity for accepted body and parameter descriptors, with one remaining node-identity rule gap. The Prism-indexed node table at `bin/fleek.rb` (`fleek_duplication_node_rules`) is the accepted body support and unconditional mass inventory; `fleek_duplication_collect_class_node` visits children through Prism's generic child visitor, records node topology, and dispatches parameter mass through the parameter descriptor table. `fleek_duplication_class_node_values_equal` uses the node descriptor for variable names/operators and scalar identity, but still has separate type branches for Range end-exclusion and static/interpolated regexp identity. These are tracked in [ticket 119](119-describe-range-and-regexp-identity.md).

| Adapter | Prism/RubyParser difference or context | Existing public evidence |
| --- | --- | --- |
| Transparent argument, statements, and parentheses nodes | Prism exposes wrapper nodes that RubyParser's candidate tree omits; the collector traverses their children without emitting wrapper tags. | Generated call, block, composed, and control-flow descriptor cases in ticket 42; top-level and class method cases in tickets 22/43. |
| `when` condition list | Prism stores conditions as a list; Flay's RubyParser tree includes a synthetic array wrapper. | ADR 0111 and generated `case` descriptor contract in ticket 42; composed collection contract in ticket 49. |
| Parent-dependent body mass | Prism's `AssocNode` and `BlockNode` mass depends on parent/context; optional block parameters add a wrapper adjustment, further normalized with optional method parameters. | ADRs 0105, 0146, 0184; generated descriptor cases and composed parameter/block contracts in tickets 42/48. |
| Composed begin/rescue/ensure mass and selection | RubyParser counts wrapper nodes absent from Prism's selected subtree; source-file boundaries also affect Flay's pruning choice. | ADRs 0188 and 0189; composed exception and cross-file contracts in tickets 50/51. |
| Parameter default and group selection | Flay treats positional one-integer calls differently from keyword defaults and selects nested iterator groups when supported method values differ. | ADRs 0169 and 0186; generated parameter cases and tickets 42/43/48. |

These adapter rows have pinned public contracts and no uncovered accepted syntax was found in the audit. Ticket 119 was a descriptor-ownership gap, not an observed report mismatch; it is now resolved with the full gate and both review axes recorded in [ticket 119](119-describe-range-and-regexp-identity.md). ADR 0190 records this boundary and resolution. Inventory evidence is the generated case catalog plus table-to-catalog check in `test/duplication_generated_descriptor_contract.rb`. No code changed in ticket 52.

Checks for this evidence-only ticket: pinned `make ticket-check` passed (128 valid documents); `git diff --check` passed. Final descriptor and composed-method gate receipts are in ticket 119, after the residual child resolved.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.
