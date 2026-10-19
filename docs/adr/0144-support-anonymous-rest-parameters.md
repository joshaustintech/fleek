# ADR 0144: Support anonymous rest and keyword-rest parameters

## Status

Accepted; extends ADRs 0128 and 0132, and reuses ADR 0143's optional-name rule.

## Context

Pinned Flay 2.14.4 includes methods with anonymous rest (`*`) and keyword-rest (`**`) parameters in identical candidates. Prism represents each absent name with constant ID `0`. Rejecting those forms loses candidate coverage, while comparing that sentinel through the constant pool asserts.

## Decision

Accept anonymous rest and keyword-rest parameters when their Prism node types are valid. Compare parameter presence, then treat two absent names as equal, one absent and one present name as different, and compare two present names through Prism's constant pool. These parameters add no candidate mass.

## Consequences

Dedicated Flay comparisons cover anonymous `*` and `**` methods (mass 6, score 12), plus anonymous-versus-named forms (similar, mass/score 6). Focused mutations protect candidate acceptance and absent-name identity. Anonymous block parameters use the same helper under ADR 0143.
