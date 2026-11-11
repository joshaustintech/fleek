# 143: Analyze remaining Flay sources when one source fails to parse

**What to build:** When one selected source fails to parse, Flay structural duplication still analyzes the other sources and reports their groups. That source alone is marked failed, matching Flay 2.14.4, which warns `skipping <file>` and continues.

**Part of:** Ticket 24.

**Blocked by:** 142

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

`flay test/fixtures/duplication_file_a.rb test/fixtures/bad_syntax.rb test/fixtures/duplication_file_b.rb` reports the identical `defn` group (score 64) and skips `bad_syntax.rb`. Fleek currently reports `3 selected; 0 analyzed; 3 failed`. The generic engine already parses each file separately, so it can exclude only the failing file's sexps.

## Acceptance criteria

- [ ] The three-file case reports the score-64 group, `2 analyzed; 1 failed`, and an incomplete status, with the parse error attributed to `bad_syntax.rb` only.
- [ ] A mutation that fails every source on one parse error is caught.
- [ ] Full gate, Flay/Reek self-checks and the Rails manifest pass; record results in `## Answer`.
