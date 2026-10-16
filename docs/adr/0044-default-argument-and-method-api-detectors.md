# ADR 0044: Add bounded Reek argument and method API detectors

## Status

Accepted.

## Context

Ticket 04 adds the pinned Reek 6.6.0 defaults BooleanParameter, ControlParameter, LongParameterList, LongYieldList, UnusedParameters, and UtilityFunction. Fleek compiles through Spinel and cannot load Reek at runtime. Native detectors must therefore match the reference on supported syntax and expose gaps as incomplete coverage.

## Decision

Implement the six detectors with Prism-backed native analysis and use Fleek's existing configuration, exclusion, report, and coverage paths. LongParameterList and LongYieldList honor `max_params`; LongParameterList uses Reek's `initialize` limit of five and marks block parameter analysis unsupported. LongYieldList follows method yields through nested blocks. UtilityFunction scans direct instance methods with sends and no instance-state references. Shared argument/method checks currently support simple direct method bodies and supported parameter forms. Unsupported source shapes fail detector coverage instead of reporting clean.

Keep `UnusedPrivateMethod` out of defaults. When selected explicitly or enabled by configuration, preserve it in the selected profile and report it as unsupported; implementing its analysis belongs to the full analyzer parity work tracked by the parent spec. `UtilityFunction.public_methods_only: true` is also reported unsupported until method visibility is tracked by the native scanner.

## Consequences

Supported fixture findings match pinned Reek messages, lines, and contexts. Configuration for parameter thresholds and path/context exclusions uses the shared configuration path. Remaining syntax and visibility gaps keep reports incomplete. Configured-disabled opt-in checks are reported disabled. Default invocations now run all six ticket detectors, alongside prior supported defaults.

## Evidence

`test/default_argument_api_contract.rb` compares default and configured detector behavior with Reek 6.6.0, checks the `initialize` override, singleton parameter/yield contexts, ControlParameter logical conditions and suppression, UtilityFunction self calls, yields in blocks, unsupported long-parameter blocks and opt-in selection, discovered/configured-disabled opt-in behavior, and UtilityFunction visibility-config limits. Mutation contracts kill missing-finding mutants for all six detectors and yields in blocks.
