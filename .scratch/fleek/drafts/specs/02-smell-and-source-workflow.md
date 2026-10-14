# Smell analysis and source workflow

Publication: draft for review.

## Problem Statement

Ruby and Spinel developers need useful findings with trustworthy coverage. A text search for class variables, ignored input, unsupported defaults, or ambiguous status would create misleading results instead of a compatible Reek replacement.

## Solution

Deliver the real ClassVariable detector through the native CLI, then support explicit files, documented directory discovery, named stdin, supported Reek configuration and suppression, and clear deterministic text output.

## User Stories

1. As a developer, I want to select ClassVariable explicitly, so that the report tells me exactly which supported check ran.
2. As a developer, I want class-variable reads and assignments reported, so that findings match the reference detector rather than a text heuristic.
3. As a developer, I want repeated occurrences grouped by name and context, so that one variable produces the correct finding and lines.
4. As a developer, I want nested class and module scopes kept distinct, so that findings identify their actual owners.
5. As a developer, I want strings and comments distinguished from code, so that harmless text does not produce false findings.
6. As a developer, I want explicit file and directory arguments, so that the source selection is deliberate.
7. As a CI user, I want documented hidden-directory and symlink boundaries, so that I know what a recursive scan includes.
8. As an editor user, I want named stdin input, so that unsaved source retains meaningful locations and configuration scope.
9. As a developer, I want supported Reek YAML settings and discovery behavior preserved, so that existing check choices remain meaningful.
10. As a developer, I want scoped exclusions and suppression comments respected, so that intentional check policy survives migration.
11. As an agent, I want unsupported selections and settings rejected before analysis, so that I cannot mistake partial capability for full coverage.
12. As a developer, I want good files checked when another file fails, so that useful findings remain available with an explicit incomplete result.
13. As an agent, I want stable names, locations, completion, and coverage fields, so that I can interpret text output without guessing.
14. As a CI user, I want findings, diagnostics, and exit status to agree, so that automation can distinguish clean, findings, and incomplete analysis.

## Implementation Decisions

- ClassVariable follows the unchanged pinned Reek detector on shared syntax, including names, occurrence lines, context ownership, messages, configuration, and suppression.
- Select supported checks explicitly using the accepted named-check interface. Missing selection cannot silently replace unsupported upstream defaults with a smaller set.
- Recursively include Ruby source files, skip hidden directories, and do not follow directory symlinks. Explicit non-Ruby files fail. Document discovery exceptions to upstream behavior.
- Require explicit paths or stdin selection. Stdin needs a source filename and never causes accidental directory scanning.
- Import supported Reek YAML before designing a unified configuration format. Preserve upstream discovery, precedence, and scope where supported; reject unsupported settings explicitly.
- Invalid options/configuration fail before analysis. Per-file failures retain useful findings, identify failures, mark the report incomplete, and exit 1.
- Complete clean analysis exits 0; complete analysis with findings exits 2. Diagnostics remain separate from finding output.
- Stabilize text field names, location representation, escaping, and coverage/completion conventions in an observable contract before the combined report relies on them. No new machine format is introduced.

## Testing Decisions

- Test through the compiled CLI, using the parser and reference harness rather than private invocation sequences.
- Compare shared-syntax findings against unchanged Reek for reads/writes, multiple names, classes/modules, nested scopes, methods, top-level and singleton contexts, reopening, and text that resembles code.
- Test supported config discovery/precedence, enablement, scope overrides, exclusions, and suppression with real examples. Verify unsupported defaults do not return success.
- Compare file versus named-stdin locations and config scope. Exercise missing/invalid files mixed with good files and directory boundary cases.
- Use adversarial filenames/messages and repeated runs to prove unambiguous stable text. Avoid relying on terminal color for meaning.
- Mutate grouping, scope ownership, suppression, status precedence, and discovery boundaries to prove tests detect the corresponding faults.

## Out of Scope

Other smell detectors, structural duplication, machine formats, custom lint philosophy, and a unified Fleek configuration format.

## Further Notes

Some edge-case detector behavior is currently source-derived, not executed. Lock and run reference cases before asserting exact parity. Syntax accepted by the parser may still be unsupported by the detector adapter and must fail honestly.
