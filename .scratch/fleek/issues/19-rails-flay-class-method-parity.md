# 19: Rails Flay class-method parity

**What to build:** `flay:StructuralDuplication` preserves upstream Flay 2.14.4 findings for ordinary methods inside Rails classes, including nested method candidates, AST structure, source locations, mass, grouping, score, and order. Parent specification: Language support and real-project parity.

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [x] Add a public CLI contract for the pinned Rails Tutorial corpus's similar methods at `app/controllers/users_controller.rb:51` and `:58`.
- [x] Compare identical `.rb` inputs and default mass 16 against unchanged Flay 2.14.4; match the score-48 similar `:defn` group and ordered locations.
- [x] Keep unsupported class/method shapes explicit and incomplete; do not silently skip candidates or execute application code.
- [x] Mutation checks catch missing candidates, shape/equality drift, incorrect original locations, score, and ordering.
- [ ] The full 25-file Rails Ruby manifest has no unexplained difference across both selected checks; all project gates and both code-review axes pass.

**Release gate:** Ticket 14's pinned Rails 8 corpus currently has 25 Flay failures. Do not claim full parity until this exact input is complete.

## Comments

- 2026-10-15: Added bounded Prism tree fingerprints for direct parameterless methods in simple classes. Locked Flay fixtures prove a Rails-shaped similar group (mass/score 48 and ordered lines), an identical group (score 64), clean handling of same-preorder/different-tree call nesting, and fail-closed handling of qualifying partial subtrees. Mutations cover tree topology, partial groups, score, original lines, candidate collection, and method-count boundary. ADR 0022 records the AST and Flay keyword-hash mass mapping decision. The real 25-file corpus remains incomplete: actual `UsersController` includes class-level callbacks and additional method shapes not accepted by this slice. Ticket remains claimed; no release parity claim.
- 2026-10-15: Class scanning now retains verified supported method groups when callbacks or unsupported methods are present, but marks selected sources partial, warns that candidates may be omitted, reports zero fully analyzed sources, and exits 1. `make rails-controller-parity` requires `FLEEK_RAILS_CORPUS` at the pinned commit and compares the real controller with unchanged Flay. Both report mass/score 48 and ordered lines 51/58; Fleek remains incomplete. Synthetic and corpus CLI contracts plus mutations protect findings, source label, coverage, and status. ADR 0023 records the partial-results policy. Exact 25-file manifest gate remains open.
- 2026-10-15: Full pinned Spinel build/contracts, Flay, Reek, and all 65 mutation checks pass. Both review axes pass. The 25-file manifest and combined Reek/Flay parity gate remains the only unchecked acceptance item; ticket stays claimed.
- 2026-10-15: Added cross-class method candidate collection to handle multiple simple class declarations in one combined input. A pinned Flay 2.14.4 public CLI fixture verifies exact `:defn` kind, mass/score 48, ordered lines, and findings status. ADR 0024 records limits and fail-closed behavior. Full 25-file parity remains open.
- 2026-10-15: Added a second reference fixture for Flay's cross-class `:class` grouping. Fleek now fails incomplete for that unsupported group shape rather than presenting its child methods as a `:defn` group; a dedicated mutation protects the boundary.
- 2026-10-15: Added bounded traversal through one simple module namespace to reach direct classes, matching the Rails Action Cable source shape. ADR 0025 records that module-level methods and deeper nesting remain unsupported. The full 25-file run still reports incomplete.
- 2026-10-15: Re-ran identical pinned 25-file inputs after the cross-class/namespace work. References remain Flay score 48 at `UsersController:51,58` and Reek ClassVariable clean; Fleek Reek covers 25/25, while Fleek Flay reports 0 analyzed and 25 failed. Parameterized methods and common Rails body forms remain unsupported. Acceptance and release gate stay open.
- 2026-10-15: Narrowed cross-class `:class` rejection to fully modeled class bodies so unsupported callbacks no longer hide verified `:defn` groups; paired Flay/Fleek fixture retains score 48 and ordered locations while exiting incomplete. Empty classes and modules now match Flay's clean result; a null module body check fixes an empty-helper crash. On the exact 25-file manifest, Fleek now reports the reference score-48 group at `UsersController:51,58` but all files remain partial and exit 1 due unsupported forms. Ticket acceptance and release gate stay open.
