# 18: Namespaced ClassVariable contexts

**What to build:** `reek:ClassVariable` analyzes ordinary namespaced Rails classes and modules with the same finding contexts, grouping, source lines, and configuration scope as Reek 6.6.0. Parent specification: Language support and real-project parity.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [ ] Add failing CLI/reference cases for `module ApplicationCable; class Connection < Base; ... end; end`, including clean and class-variable finding cases.
- [ ] Preserve qualified context, occurrence grouping and lines, suppression/config semantics, and fail-closed behavior for unsupported deeper/reopened scope.
- [ ] Mutation checks prove namespace traversal/context changes are detected.
- [ ] Full project build, tests, Flay, Reek, mutation, and both code-review axes pass.

**Release gate:** Ticket 14's pinned Rails 8 corpus currently has two ClassVariable namespace failures. Do not claim full parity until this exact input is complete.
