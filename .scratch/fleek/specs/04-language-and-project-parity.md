# Full analyzer parity and language support

Publication: active specification.

## Problem Statement

Fleek currently implements only Flay's `StructuralDuplication` check and Reek's `ClassVariable` detector, with bounded syntax and configuration support. That leaves Ruby developers without the rest of the pinned analyzers' built-in checks and detectors, including detectors that are opt-in upstream. Existing Rails evidence also records incomplete Flay coverage as an accepted first-release boundary. A useful native replacement needs complete behavioral parity on source both unchanged pinned analyzers can parse, with Ruby 4 and Spinel-only syntax behavior described separately.

## Solution

Extend Fleek's native CLI until every built-in check and detector in Flay 2.14.4 and Reek 6.6.0 is supported. With no explicit selection, run the same checks and detectors the pinned tools enable by default; `--checks` remains an explicit subset selector, and existing analyzer configuration can change settings, exclusions, and detector enablement. Match analysis behavior and controls on identical shared-parseable Ruby inputs. Keep Fleek's report format and documented exit-code normalization. Continue to distinguish incomplete analysis from complete results. Document reviewed Ruby 4.0 or Spinel extension behavior separately where a pinned reference rejects the syntax. Full parity is a native CLI goal; publishing a release that claims parity is a separate effort.

## User Stories

1. As a Ruby developer, I want every built-in Flay check and Reek detector implemented, so that Fleek can replace the pinned analyzers' analysis capabilities.
2. As a Ruby developer, I want opt-in detectors available when explicitly selected or enabled in configuration, so that Fleek does not omit built-in capabilities merely because upstream disables them by default.
3. As a Ruby developer, I want an unqualified default run to match the pinned analyzers' built-in default selection, so that ordinary use requires no manual reconstruction of their defaults.
4. As a developer, I want `--checks` to select an explicit subset, so that focused runs remain predictable.
5. As a developer, I want Flay and Reek settings, exclusions, and suppressions to retain their analyzer-specific scope and effects, so that configuration does not silently change findings.
6. As a developer, I want every supported check to match upstream findings on identical shared-parseable inputs, so that Fleek reports the same analysis results.
7. As a developer, I want finding identity, source locations, grouping, ordering, scores, and detector details to match upstream, so that equivalent analyses are comparable.
8. As a developer, I want check-specific thresholds and behavior controls to match upstream, so that changing options changes results in the same way.
9. As a developer, I want path discovery, exclusions, and repeated or failed input handling to preserve analysis semantics, so that the same selected source set is analyzed.
10. As a developer, I want configuration discovery, precedence, validation, and detector enablement to match upstream, so that existing project settings keep working.
11. As a CI user, I want unsupported selected analysis to produce an explicit incomplete result, so that missing coverage never appears clean.
12. As a user, I want supported findings retained alongside incomplete results, so that a gap in one check does not erase useful evidence from another.
13. As a user, I want Fleek's report format and documented status normalization to remain stable, so that parity does not require byte-identical upstream output.
14. As a Ruby developer, I want shared syntax comparisons against unchanged pinned references, so that compatibility claims have a clear evidence boundary.
15. As a Ruby 4 or Spinel developer, I want newer reference-rejected syntax covered by separately reviewed expectations, so that extension behavior is useful without being mislabeled as upstream parity.
16. As a developer, I want original source locations preserved for native analysis, so that findings point to my code.
17. As a maintainer, I want source analysis not to execute requires, FFI declarations, or application code, so that analysis remains safe and independent of project runtime behavior.
18. As a maintainer, I want immutable source, settings, and reference environments, so that parity evidence is reproducible.
19. As a Rails developer, I want the pinned real-project corpus fully analyzed by every applicable built-in check, so that fixture-only parity is not mistaken for project parity.
20. As an agent, I want capability and deliberate difference reporting to distinguish unsupported analysis from clean results, so that automated consumers can interpret results accurately.
21. As a maintainer, I want each discovered mismatch captured as a minimal public-behavior regression case, so that fixes remain narrow and durable.

## Implementation Decisions

- Ruby syntax target is explicitly 4.0, not an unspecified latest grammar. Spinel input targets source accepted by compiler 2026.09.12 including documented syntax extensions; implementation compiler remains pinned. Reference parity applies to identical source accepted by both pinned reference analyzers and Fleek. Newer or reference-rejected source is extension behavior with separate reviewed expectations.
- Analyze original source without executing it or loading its dependencies. Treat native source strings as source content according to the Ruby check semantics, not as a promise to analyze another embedded language.
- Implement every built-in Flay 2.14.4 check and Reek 6.6.0 detector, whether upstream enables it by default or not. With no explicit selection, use the pinned upstream default set. Explicit `--checks` selects a subset; analyzer configuration retains control over settings, exclusions, suppressions, and detector enablement.
- Match analysis behavior and controls for identical inputs and settings, including findings, locations, ordering, metrics, grouping, configuration, exclusions, and check-specific thresholds. Fleek may retain its report format and documented exit-code normalization.
- Until all selected checks complete analysis, report unsupported coverage explicitly as incomplete and preserve findings from checks that did complete. A clean result must not imply omitted checks ran.
- Unchanged pinned originals define shared-syntax comparisons. Review extension expectations separately and label them as extension behavior.
- Any secondary modified reference must first demonstrate agreement with its unchanged counterpart on common grammar and have its own locked identity.
- Use the existing compiled CLI process as the primary test seam. Compare identical source and settings against unchanged pinned references, and exercise real path/config inputs through the public CLI.
- Complete the pinned Rails corpus comparison for every applicable built-in check; preserve the established source manifest and reference environment when extending evidence.
- Treat existing default-check work as the default-invocation portion of this goal; extend its current spec/ticket work rather than duplicating it.
- Full native CLI parity is the completion target. Release packaging and publication that claim full parity are separate work.
- Maintain an explicit capability statement for syntax, checks, settings, path discovery, and CLI differences. Do not infer full replacement coverage from selected-check parity.

## Testing Decisions

- Use the compiled CLI process seam, actual parser, actual checks, and unchanged pinned references. Parsing-only success is insufficient.
- For every built-in check and detector, include clean and finding cases plus boundary/control cases that distinguish its behavior. Include opt-in detectors and prove default versus explicit selection.
- Compare findings, locations, grouping, ordering, scores/metrics, configuration, exclusions, suppressions, and analysis controls against the pinned references on identical shared-parseable inputs.
- Include Ruby 4.0 and documented Spinel extension examples with expected findings, negative cases, source locations, scope, comments, suppression, and duplication shape where applicable; label these separately from unchanged-reference parity.
- Verify non-execution by analyzing source whose execution/loading would produce an observable effect and proving the effect does not occur.
- Compare shared-syntax examples against originals; keep extension fixtures and their provenance distinguishable in evidence.
- Record corpus revision, input manifest, exact settings, tool versions, outputs, statuses, and every deliberate comparison exception. Complete the real Rails corpus gate for all applicable checks.
- Mutate extension location handling and check traversal where relevant. Regressions found in the real corpus receive minimal behavior tests and the ordinary gates.

## Out of Scope

Upstream plugins and third-party checks, Ruby language versions beyond 4.0, arbitrary Spinel releases, execution of analyzed code, syntax silently ignored, byte-for-byte upstream report formatting, exact upstream exit codes where normalization is documented, and release publication.

## Further Notes

Existing bounded first-release decisions, including ADR 0037, describe the historical release boundary and do not satisfy this full-parity goal. Reopen or supersede affected decisions as implementation slices establish complete behavior. Keep reference parity and extension behavior distinct in test evidence and user-facing capability claims.
