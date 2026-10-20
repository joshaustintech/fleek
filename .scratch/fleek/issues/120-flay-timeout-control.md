# 120: Support Flay timeout control

**What to build:** Match Flay 2.14.4 `--timeout TIME` analysis behavior through Fleek's native parser path.

**Part of:** Ticket 23 — Flay controls.

**Blocked by:** 58; 115.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [ ] Compare zero, positive, malformed, and negative timeout values against pinned Flay; record timeout units and failure behavior.
- [ ] Preserve selected-source coverage and report incomplete analysis when native parsing cannot finish within the requested budget.
- [ ] Add public contracts and non-equivalent mutations, then run full required gates and reviews.
