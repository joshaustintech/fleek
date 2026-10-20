# ADR 0188: Match composed exception wrapper mass

## Status

Accepted

## Context

Ticket 50 compares methods with begin/rescue/ensure and interpolated regexp or string values. Existing node identity and interpolation rules produced the correct identical/similar classifications, but Flay 2.14.4 reported mass 36 for the regexp pair and 32 for the string pair; Fleek reported six less. Existing standalone rescue/retry and ensure contracts already matched and must retain their behavior. An unsupported default beside the supported pair must also preserve its finding and incomplete status.

## Decision

Keep matching on the existing native AST path. In method mass calculation, add the empirically verified composed wrapper adjustment whenever a begin node has both rescue and ensure clauses, with an additional binding adjustment when the rescue has a reference. Interpolated values are covered in the required pairs; a plain-body pair verifies that the correction follows the exception structure rather than interpolation. Do not change standalone rescue, ensure, or interpolation rules.

## Evidence

Pinned CLI comparisons showed identical and changed regexp pairs at Flay mass 36, and identical and changed interpolated-string pairs at mass 32. Before the adjustment Fleek reported each six points lower. A plain rescue/ensure pair also matches Flay at mass 28. The public contract checks kinds, locations, mass, score, coverage, and status, verifies empty streams for supported inputs, and verifies that Flay's similar mass-36 finding remains present with incomplete coverage when an unsupported default is selected. Focused mutations prove both mass adjustments are required.

## Consequences

The change covers the ticket's bounded begin/rescue/ensure compositions. It does not expand supported syntax or close parent Tickets 22/43; other exception forms remain subject to their own parity evidence.
