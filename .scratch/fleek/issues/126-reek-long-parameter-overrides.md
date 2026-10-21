# 126: Support LongParameterList context overrides

**What to build:** `LongParameterList.overrides` applies Reek 6.6.0 context-specific thresholds to the same methods and preserves finding and report status.

**Part of:** Ticket 24.

**Blocked by:** 90 (resolved); 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
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

- [x] Parse only the bounded `LongParameterList.overrides` mapping needed for method-name threshold overrides; malformed or unsupported shapes remain configuration errors.
- [x] Match pinned findings, context, line, count, coverage, output streams and normalized outcome for the explicit initializer threshold and the existing default initializer threshold.
- [x] Keep global `max_params` precedence and unrelated detector settings unchanged; add a focused regression and relevant non-equivalent mutation.
- [x] Run required build/tests, Flay, Reek, mutation, tracker/link, standards and spec gates before committing. Record commands and exact residual limits in `## Answer`.

## Answer

Implemented only the pinned Reek 6.6.0 `LongParameterList.overrides.initialize.max_params` mapping, using the existing global/directory setting precedence. The initializer override wins over global `max_params`; other methods retain the global threshold, and the default initializer limit stays five. Unsupported override contexts and noninteger thresholds are rejected before analysis. No general YAML dependency or override framework was added. Other detector override shapes remain unsupported.

The public CLI contract compares the default clean five-parameter initializer and the explicit override finding at line 2, context `Parcel#initialize`, count 5, exit 2, one analyzed source, `Status: findings`, and empty stderr against Reek. With global `max_params: 6` and initializer override 4, the pinned finding is preserved. Configuration contracts verify unsupported contexts and invalid threshold types are rejected by Fleek and Reek. Mutation `LongParameterList initializer override threshold` was caught.

Pinned identities: Spinel 2026.09.12 (tag object `00ce35bb96e489620358ffbc48791001a73778a5`, source `112bae85c1a25fc5399009a849f805bfe691426b`), Flay 2.14.4, Reek 6.6.0.

Verification: `make check JOBS=8` passed 78 workers with 8 mutation workers; all mutations were caught, Flay score was 1008, and Reek reported 0 warnings. `gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` passed 3,596 tests, allocation and inference checks, and `spin-e2e`. `make ticket-check` validated 138 documents; `git diff --check` passed. ADR 0242 records the decision. No child tickets remain for this slice; parent Ticket 24 remains open for other detector parity work.

## Execution and stop condition

Claim this child before implementation. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Add no new YAML framework and stop after this override shape matches its reference behavior.
