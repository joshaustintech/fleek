# 140: Analyze the Rails Micropost attachment declaration for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `Micropost` Active Storage attachment declaration and its one `display` variant.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved), 139 (resolved).

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept only the direct `has_one_attached :image do |attachable| ... end` declaration with exactly one block parameter and exactly one body statement: `attachable.variant :display, resize_to_limit: [500, 500]`. Require the variant receiver to be that block parameter, one symbol argument, and exactly one keyword pair with the exact symbol key and two integer array elements. Treat the declaration as non-candidate. Keep all other attachment, block, and variant forms incomplete.

## Starting evidence

Pinned Rails `app/models/micropost.rb` contains this attachment block. Flay 2.14.4 reports score zero; Fleek currently marks the whole file partial for this and validation forms.

## Acceptance criteria

- [ ] A minimal public CLI fixture matches Flay 2.14.4 after implementation.
- [ ] Unsupported attachment names, receivers, block parameters, body statements, variants, keys, and values remain incomplete with focused mutation coverage.
- [ ] The pinned `Micropost` remains incomplete until its validations are supported.
- [ ] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [ ] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97 after issue 139. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Support this one Active Storage declaration only; do not generalize block DSL handling.
