---
name: performance-bugs
description: Diagnose and fix slow checks, builds, scans, and runtime paths with measured deterministic evidence. Use whenever a user reports slowness or an agent encounters a costly path.
---

# Performance bugs

Treat unexpected slowness as a bug. Track each confirmed bottleneck as a `Category: bug` issue under `.scratch/<feature>/issues/` and fix it before continuing feature work.

1. Read the relevant `CONTEXT.md`, ADRs, and issue. Record the exact command, environment, input, and baseline time.
2. Build a small deterministic loop that exercises the slow path. Run it before editing. Rank at least three falsifiable causes; change one variable per probe.
3. Profile or time the phases separately. Optimize the measured dominant cost. Prefer reuse of unchanged work, narrow test selection, and bounded parallel work. Keep behavior checks and isolation intact.
4. Add the smallest stable regression guard. Do not assert wall-clock thresholds in ordinary contracts; record reproducible before/after timings instead.
5. Run the focused loop, then relevant full gates. Compare outputs and statuses as well as time. Record the chosen trade-off and evidence in an ADR when it changes a harness or runtime policy.
6. Resolve the bug issue only after the fix and required gates pass. Commit the coherent fix and continue with the original feature task.
