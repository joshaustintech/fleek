# 90: Inventory all Reek settings and remaining gaps

**What to build:** All 29 built-in detectors and their pinned settings have explicit evidence rows; bounded support is never mistaken for full parity.

**Part of:** Ticket 24.

**Blocked by:** 61 (resolved); 115 — Verify harness savings before resuming feature work (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Read pinned detector defaults/source and existing contracts. Record enabled-by-default flag, each setting, supported scopes, clean/finding/control proof and exact residual mismatch. Reuse existing evidence. Publish one additional ticket per missing setting/scope behavior, with a concrete input and expected pinned result; no bulk implementation in this ticket.

## Starting evidence

Pinned Reek 6.6.0 built-in inventory, resolved default-check tickets 02-08 and existing detector contracts.

## Acceptance criteria

- [x] Listed behavior cases have reproducible inputs, pinned expected results and matching public behavior. Inventory-only work records evidence and concrete child links; completion gates remain open until every required residual gap resolves.
- [x] Semantic findings, coverage, streams and normalized outcome are asserted where applicable; evidence-only inventories distinguish verified rows from unresolved work.
- [x] Relevant regression/mutation or evidence checks pass; Answer records exact commands and remaining issue links.
- [x] Stop after this behavior is proven; parent acceptance is not reduced by this child.

## Execution and stop condition

Claim this child before implementation; parent claims remain unchanged. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Start with the listed public CLI cases and existing helpers. Record expected versus actual behavior before editing. Implement only this behavior through the existing native path; no new framework, reference-tool fallback or unrelated syntax expansion.

Keep one focused regression and relevant non-equivalent mutations for changed behavior. Use `FLEEK_MUTATIONS` with exact registered labels for focused runs; full mutation coverage remains mandatory before a code commit. Run repository-required build/tests, Flay, Reek, mutation and standards/spec review gates before landing code. Docs/evidence-only work gets tracker/link/diff checks; do not invent implementation proof. Record commands, tool identities, RED/GREEN evidence where code changed, gate results and limitations in `## Answer`.

If cases already pass, add only missing meaningful evidence and finish; do not refactor for activity. If a second independent defect appears, publish a separate minimal child with expected pinned behavior and blockers. This child may finish its stated behavior while those gaps remain open, but the parent completion gate must wait for every residual child. Never turn incomplete coverage into clean output, skip a selected source or weaken a reference expectation to pass.

## Answer

Pinned tools: Spinel 2026.09.12, Flay 2.14.4, Reek 6.6.0. Reek source is `/private/tmp/fleek-bundle/ruby/3.4.0/gems/reek-6.6.0`; the detector registry is `lib/reek/smell_detectors.rb`, generic defaults are in `BaseDetector.default_config` (`enabled: true`, `exclude: []`), and the setting schema is `lib/reek/configuration/schema.rb`. `UnusedPrivateMethod` overrides the default to `enabled: false`. Every detector also inherits per-detector `exclude: []`. Fleek parses bounded global and directory detector settings, while directory discovery and precedence remain open in issue 91. Issue 92 covers inline suppression and issue 93 covers malformed/unsupported configuration validation. Generic configuration evidence is in `test/configuration_contract.rb` and `test/default_configuration_contract.rb`.

| Reek 6.6.0 detector | Default-specific settings | Bounded public evidence |
| --- | --- | --- |
| Attribute | none | issue 63 |
| BooleanParameter | none | issue 69 |
| ClassVariable | none | issue 62 |
| ControlParameter | none | issue 71 |
| DataClump | `max_copies: 2`, `min_clump_size: 2` | issue 81 |
| DuplicateMethodCall | `max_calls: 1`, `allow_calls: []` | issue 74 |
| FeatureEnvy | none | issue 80 |
| InstanceVariableAssumption | none | issue 64 |
| IrresponsibleModule | none | issue 67 |
| LongParameterList | `max_params: 3`; built-in `initialize` override `max_params: 5` | issue 68; custom overrides gap: issue 126 |
| LongYieldList | `max_params: 3` | issue 70 |
| ManualDispatch | none | issue 75 |
| MissingSafeMethod | none | issue 77 |
| ModuleInitialize | none | issue 66 |
| NestedIterators | `max_allowed_nesting: 1`, `ignore_iterators: [tap, Tempfile.create]` | issue 79 |
| NilCheck | none | issue 76 |
| RepeatedConditional | `max_ifs: 2` | issue 78 |
| SubclassedFromCoreClass | none | issue 65 |
| TooManyConstants | `max_constants: 5` | issue 82 |
| TooManyInstanceVariables | `max_instance_variables: 4` | issue 83 |
| TooManyMethods | `max_methods: 15` | issue 84 |
| TooManyStatements | `max_statements: 5` | issue 85 |
| UncommunicativeMethodName | reject `^[a-z]$`, `[0-9]$`, `[A-Z]`; accept `[]` | issue 86 |
| UncommunicativeModuleName | reject `^.$`, `[0-9]$`; accept `[]` | issue 87 |
| UncommunicativeParameterName | reject `^.$`, `[0-9]$`, `[A-Z]`, `^_`; accept `[]` | issue 88 |
| UncommunicativeVariableName | reject `^.$`, `[0-9]$`, `[A-Z]`; accept `^_$` | issue 89 |
| UnusedParameters | none | issue 72 |
| UnusedPrivateMethod | `enabled: false` | issues 60–61 |
| UtilityFunction | `public_methods_only: false` | issue 73 |

Evidence run: `bundle exec reek --smell LongParameterList --config test/fixtures/config_long_parameter_list_initializer_override.yml test/fixtures/initialize_parameter_list.rb` reports exactly `Parcel#initialize has 5 parameters` at line 2 (status 2). The equivalent compiled Fleek selection rejects `overrides` at config line 3 (status 1). The reproducible config fixture and bounded gap are in issue 126. Other detector rows reuse the unchanged pinned comparisons and public CLI contracts recorded in their linked resolved issues; this inventory adds no analyzer behavior or mutation claim.

Checks: pinned Reek command above; compiled Fleek mismatch command `./build/fleek --checks reek:LongParameterList --reek-config test/fixtures/config_long_parameter_list_initializer_override.yml test/fixtures/initialize_parameter_list.rb`; `make ticket-check`; `git diff --check`. Remaining configuration work: issues 91–93 and 126. Parent issue 24 remains open until all required residual gaps close. Decision: [ADR 0227](../../../docs/adr/0227-inventory-pinned-reek-settings.md).
