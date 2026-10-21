# ADR 0242: Support the LongParameterList initializer threshold override

## Status

Accepted for Ticket 126.

## Context

Reek 6.6.0 accepts `LongParameterList.overrides.initialize.max_params`. This method-specific threshold takes precedence over the detector-wide `max_params`, and the built-in initializer threshold is five when no override is configured. Fleek's bounded configuration parser currently handles scalar detector settings and rejects the nested override mapping.

## Decision

Support only the `initialize` context with an integer `max_params` under `LongParameterList.overrides`, matching the pinned Reek schema. Pass its effective threshold separately to the native method walker. Keep the detector-wide threshold for other methods and keep the default initializer threshold at five. Reject unsupported contexts, settings, values, and malformed mapping shapes through the existing configuration error path.

Do not add a general YAML parser or general context override framework for this slice.

## Consequences

A configured initializer override wins over global `max_params`; other methods continue to use the global value. Configurations without an initializer override retain Reek's built-in threshold of five. The public contract checks a five-parameter initializer with global `max_params: 6` and initializer override `max_params: 4`, as well as the clean default initializer case. Invalid context and threshold fixtures verify early rejection against pinned Reek.

Other detector override schemas and arbitrary contexts remain unsupported.

## Evidence

Ticket 126 records focused public and configuration contracts and the caught `LongParameterList initializer override threshold` mutation. On pinned Spinel 2026.09.12 (tag object `00ce35bb96e489620358ffbc48791001a73778a5`, source `112bae85c1a25fc5399009a849f805bfe691426b`), `make check JOBS=8` passed with 78 workers, 8 mutation workers, all mutations caught, Flay score 1008, and Reek 0 warnings. `gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` passed 3,596 tests, allocation and inference checks, and `spin-e2e`. The tracker validator accepted 138 documents.
