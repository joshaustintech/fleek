# 97: Require complete Flay analysis of pinned Rails sources

**What to build:** Every reference-accepted source in the pinned Rails manifest has complete Flay analysis and matching semantic findings.

**Part of:** Ticket 24.

**Blocked by:** 96; 22; 23; 115 — Verify harness savings before resuming feature work.

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

After all Flay gaps from census 96 and descendants resolve, replace only obsolete partial expectations with complete coverage requirements. Compare every group, kind, mass, score and ordered original locations. Require the corpus in the explicit Rails gate; missing checkout must fail there. This ticket integrates evidence, not an unlimited syntax rewrite.

## Starting evidence

Existing exact-manifest Rails Flay contract and make rails-manifest-parity.

## Acceptance criteria

- [ ] Listed behavior cases have reproducible inputs, pinned expected results and matching public behavior. Inventory-only work records evidence and concrete child links; completion gates remain open until every required residual gap resolves.
- [ ] Semantic findings, coverage, streams and normalized outcome are asserted where applicable; evidence-only inventories distinguish verified rows from unresolved work.
- [ ] Relevant regression/mutation or evidence checks pass; Answer records exact commands and remaining issue links.
- [ ] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.

## Answer

Reproduced the baseline with pinned Spinel `2026.09.12`, Flay `2.14.4`, and Reek `6.6.0`: `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce make rails-manifest-parity` preserves the score-48 group at `UsersController:51,58`, while the manifest remains explicitly incomplete due to other residual shapes. The direct `before_action` case is implemented and verified in [resolved issue 130](130-rails-flay-class-callback-declarations.md). [ADR 0244](../../../docs/adr/0244-bound-rails-flay-callback-declarations.md) records its bounded AST support and fail-closed block behavior. This completion gate remains open until every remaining manifest gap is resolved.

The next identified class-body gap is bare visibility declarations. [Issue 131](131-rails-flay-visibility-declarations.md) tracks the reference-backed `private`/`protected`/`public` case; [ADR 0245](../../../docs/adr/0245-bound-rails-flay-visibility-declarations.md) records its intended boundary. The Rails manifest completion gate remains open.

Issue 131 is resolved. `UsersController` now has complete Flay coverage when selected alone and retains its exact score-48 group; the combined 25-file manifest remains incomplete because of other residual source shapes.

The next residual is `ApplicationController`'s direct `include SessionsHelper` declaration. [Issue 132](132-rails-flay-include-declarations.md) tracks the reference-backed include case; [ADR 0246](../../../docs/adr/0246-bound-rails-flay-include-declarations.md) records its narrow boundary. Issue 97 remains open.

Issue 132 is resolved: direct constant and constant-path `include` declarations are accepted, and the pinned `ApplicationController` analyzes completely by itself. The 25-file manifest gate still reports Flay incomplete at 0/25 fully analyzed; further class-body and method shapes remain.

Issue 133 resolves the empty class method gap: the pinned `static_pages_controller.rb` is now complete alone, and cross-class class-group mass matches Flay. [ADR 0247](../../../docs/adr/0247-bound-rails-flay-empty-method-bodies.md) records the empty-tree and mass rules. The combined 25-file manifest remains incomplete at 0/25 analyzed; further source shapes remain.

The next residual is the direct `primary_abstract_class` call in pinned `ApplicationRecord`. [Issue 134](134-rails-flay-primary-abstract-class.md) bounds that one no-argument Rails declaration; [ADR 0248](../../../docs/adr/0248-bound-rails-flay-primary-abstract-class.md) records its fail-closed boundary.

Issue 134 resolves the pinned `ApplicationRecord` gap. Calls with arguments, receivers, blocks, and unrecognized names remain incomplete. The combined Rails manifest still fails its full Flay completeness gate; remaining gaps are in `UsersHelper`, `ApplicationMailer`, and models `Micropost`, `Relationship`, and `User`.

The next gap is pinned `ApplicationMailer`'s `default from: <string>` and `layout <string>` declarations. [Issue 135](135-rails-flay-mailer-declarations.md) bounds those two call forms; [ADR 0249](../../../docs/adr/0249-bound-rails-flay-mailer-declarations.md) records the fail-closed shapes.

Issue 135 resolves the pinned `ApplicationMailer` gap. Only literal `default from:` and `layout` declarations are accepted; the other call shapes remain incomplete. The 25-file manifest is still explicitly incomplete because of residual model and helper shapes.

The next residual is `UsersHelper#gravatar_for`'s optional `{ size: 80 }` default. [Issue 136](136-rails-flay-helper-hash-default.md) bounds that parameter shape; [ADR 0250](../../../docs/adr/0250-bound-rails-helper-hash-default.md) records the fail-closed boundary.

Issue 136 resolves the pinned `UsersHelper` gap. Only the single-entry `{ size: 80 }` default is supported; other hash shapes remain incomplete. The remaining manifest gaps are in `Micropost`, `Relationship`, and `User` model files.
