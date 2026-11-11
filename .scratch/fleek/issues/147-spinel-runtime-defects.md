# 147: Characterize Spinel spawn-redirect and regexp-split defects

**What to fix:** Two pinned Spinel 2026.09.12 runtime behaviors observed in long-running contract processes. Redirected `Process.spawn` output (`out:`/`err:`) can still be landing after `Process.waitpid2` returns. `String#split(/\s+/)` intermittently returns a wrong token count, while an immediate second split of the same string is correct.

**Blocked by:** 144

**Status:** open
**Type:** research
**Category:** bug
**Triage:** needs-triage

## Evidence

During ticket 144's 487-file sweep, a first `File.read` of a Fleek output returned 35 of 135 tokens while an immediate reread returned all 135, and the failing files varied between runs. Separately, raw texts read correctly while the first `split(/\s+/)` produced 0, 46 or 87 tokens where 179, 137 and 113 were expected. `bin/ticket_check.rb` still uses regexp `split` on small inputs.

## Acceptance criteria

- [ ] Minimal Spinel reproductions for both behaviors, or evidence that they come from Fleek's harness.
- [ ] A decision on whether Fleek's runtime and contracts must avoid redirected spawns and regexp splits, recorded in an ADR, with any affected code updated.

## Comments

- 2026-11-11: `bin/ticket_check.rb` began failing deterministically on `"23: Flay analysis-control parity.".split(/[^0-9]/, 2)[0]`. It reported ticket 24's blocker "23" as invalid while the input was unchanged. The checker now uses a plain `tr`/`split(";")` and a leading-digit scan instead of regexp splits, which removes the last known regexp `split` from `bin/ticket_check.rb`.
