# 19: Rails Flay class-method parity

**What to build:** `flay:StructuralDuplication` preserves upstream Flay 2.14.4 findings for ordinary methods inside Rails classes, including nested method candidates, AST structure, source locations, mass, grouping, score, and order. Parent specification: Language support and real-project parity.

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [ ] Add a failing public CLI case for the pinned Rails Tutorial corpus's similar methods at `app/controllers/users_controller.rb:51` and `:58`.
- [ ] Compare identical `.rb` inputs and default mass 16 against unchanged Flay 2.14.4; match the score-48 similar `:defn` group and ordered locations.
- [ ] Keep unsupported class/method shapes explicit and incomplete; do not silently skip candidates or execute application code.
- [ ] Mutation checks catch missing candidates, shape/equality drift, incorrect original locations, score, and ordering.
- [ ] The full 25-file Rails Ruby manifest has no unexplained difference across both selected checks; all project gates and both code-review axes pass.

**Release gate:** Ticket 14's pinned Rails 8 corpus currently has 25 Flay failures. Do not claim full parity until this exact input is complete.

## Comments

- 2026-10-15: Added bounded Prism tree fingerprints for direct parameterless methods in simple classes. Locked Flay fixtures prove a Rails-shaped similar group (mass/score 48 and ordered lines), an identical group (score 64), clean handling of same-preorder/different-tree call nesting, and fail-closed handling of qualifying partial subtrees. Mutations cover tree topology, partial groups, score, original lines, candidate collection, and method-count boundary. ADR 0022 records the AST and Flay keyword-hash mass mapping decision. The real 25-file corpus remains incomplete: actual `UsersController` includes class-level callbacks and additional method shapes not accepted by this slice. Ticket remains claimed; no release parity claim.
