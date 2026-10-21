# 126: Support LongParameterList context overrides

**What to build:** `LongParameterList.overrides` applies Reek 6.6.0 context-specific thresholds to the same methods and preserves finding and report status.

**Part of:** Ticket 24.

**Blocked by:** 90 (resolved); 115 — Verify harness savings before resuming feature work (resolved).

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use `test/fixtures/initialize_parameter_list.rb` with `test/fixtures/config_long_parameter_list_initializer_override.yml`. The five-parameter initializer is below Reek's built-in `initialize` limit of five, but the explicit override sets its limit to four.

Pinned Reek 6.6.0 command:

```sh
bundle exec reek --smell LongParameterList --config test/fixtures/config_long_parameter_list_initializer_override.yml test/fixtures/initialize_parameter_list.rb
```

Expected: one `LongParameterList` finding at line 2, `Parcel#initialize has 5 parameters`, exit 2. Current Fleek reports a configuration error at line 3 (`unsupported detector setting overrides`) for the equivalent `--checks reek:LongParameterList --reek-config ...` invocation.

## Acceptance criteria

- [ ] Parse only the bounded `LongParameterList.overrides` mapping needed for method-name threshold overrides; malformed or unsupported shapes remain configuration errors.
- [ ] Match pinned findings, context, line, count, coverage, output streams and normalized outcome for the explicit initializer threshold and the existing default initializer threshold.
- [ ] Keep global `max_params` precedence and unrelated detector settings unchanged; add a focused regression and relevant non-equivalent mutation.
- [ ] Run required build/tests, Flay, Reek, mutation, tracker/link, standards and spec gates before committing. Record commands and exact residual limits in `## Answer`.

## Execution and stop condition

Claim this child before implementation. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Add no new YAML framework and stop after this override shape matches its reference behavior.
