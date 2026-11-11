# 143: Analyze remaining Flay sources when one source fails to parse

**What to build:** When one selected source fails to parse, Flay structural duplication still analyzes the other sources and reports their groups. That source alone is marked failed, matching Flay 2.14.4, which warns `skipping <file>` and continues.

**Part of:** Ticket 24.

**Blocked by:** 142

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

`flay test/fixtures/duplication_file_a.rb test/fixtures/bad_syntax.rb test/fixtures/duplication_file_b.rb` reports the identical `defn` group (score 64) and skips `bad_syntax.rb`. Fleek currently reports `3 selected; 0 analyzed; 3 failed`. The generic engine already parses each file separately, so it can exclude only the failing file's sexps.

## Acceptance criteria

- [x] The three-file case reports the score-64 group, `2 analyzed; 1 failed`, and an incomplete status, with the parse error attributed to `bad_syntax.rb` only.
- [x] A mutation that fails every source on one parse error is caught.
- [x] Full gate, Flay/Reek self-checks and the Rails manifest pass; record results in `## Answer`.

## Answer

The generic engine records a parse failure per file (index, file-relative line and column, byte offset, Prism message), skips that file's sexps and keeps analyzing the rest, matching Flay's `skipping <file>`. The Ruby report moves each failed path into the failed source list and prints `"<path>":<line>:<column>: <message> (byte <offset>)`. The three-file case now reports the score-64 group with `3 selected; 2 analyzed; 1 failed` and exit 1. This also fixes a crash in single-file Flay runs on a syntax error, where the reporter received offset `-1`. Two mutations are caught: aborting the whole run on one parse error, and dropping the failure attribution.
