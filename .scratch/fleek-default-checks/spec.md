# Fleek runs upstream default checks

**Status:** open  
**Category:** enhancement  
**Triage:** ready-for-agent

## Problem Statement

Ruby developers must currently select Fleek checks explicitly, and Fleek implements only a subset of the checks ordinary Flay and Reek invocations run. Omitting selection can’t yet provide the expected default analyzer coverage, and omitting source paths only prints usage.

## Solution

When users omit `--checks`, run every check enabled by default in pinned Flay 2.14.4 and Reek 6.6.0. Existing analyzer configuration continues to control settings and exclusions, including explicit Reek detector disablement. Until Fleek implements every enabled default, run supported checks, retain their findings, list unsupported enabled defaults, and report the result incomplete. When users provide no paths and no `--stdin`, scan the current working directory under Fleek’s existing directory rules.

## User Stories

1. As a Ruby developer, I want Fleek to run ordinary Flay and Reek defaults when I omit `--checks`, so that I do not need to reconstruct both tools’ default selection.
2. As a Ruby developer, I want default selection tied to pinned analyzer versions, so that upgrades do not silently change which checks Fleek promises.
3. As a developer, I want explicit `--checks` to keep selecting only the named checks, so that targeted runs remain predictable.
4. As a developer, I want existing Reek configuration and `.flayignore` behavior retained, so that my settings and exclusions still apply to default runs.
5. As a developer, I want explicitly disabled Reek defaults identified as disabled by configuration, so that I can distinguish them from checks Fleek cannot run.
6. As a CI user, I want unsupported enabled defaults listed and the report marked incomplete, so that missing coverage never appears clean.
7. As a developer, I want supported checks to continue when another default is unsupported, so that I retain useful findings while seeing the coverage gap.
8. As a developer, I want findings from supported checks preserved in incomplete reports, so that an unsupported check does not erase proven results.
9. As a developer, I want Fleek to scan the current working directory when I provide no path or stdin, so that a plain invocation analyzes the current project.
10. As a developer, I want implicit directory scanning to follow documented Fleek rules, so that hidden directories and symlinks do not unexpectedly expand the scan.
11. As a user, I want empty scans and file failures to remain incomplete, so that an invocation without inputs cannot imply successful analysis.
12. As an agent, I want selected, disabled, unsupported, and run checks visible in stable report fields, so that I can interpret default coverage without guessing.

## Implementation Decisions

- Default check set is every check enabled by ordinary invocation in the pinned Flay 2.14.4 and Reek 6.6.0 references.
- Reek 6.6.0 exposes 29 detectors; 28 are enabled by default. Reek defaults include Attribute, BooleanParameter, ClassVariable, ControlParameter, DataClump, DuplicateMethodCall, FeatureEnvy, InstanceVariableAssumption, IrresponsibleModule, LongParameterList, LongYieldList, ManualDispatch, MissingSafeMethod, ModuleInitialize, NestedIterators, NilCheck, RepeatedConditional, SubclassedFromCoreClass, TooManyConstants, TooManyInstanceVariables, TooManyMethods, TooManyStatements, UncommunicativeMethodName, UncommunicativeModuleName, UncommunicativeParameterName, UncommunicativeVariableName, UnusedParameters, and UtilityFunction. `UnusedPrivateMethod` is opt-in because Reek disables it by default. Flay defaults to structural duplication with mass threshold 16.
- Keep explicit `--checks` behavior as named subset selection.
- Keep each analyzer’s existing config format and scope. Match pinned configuration behavior for settings, exclusions, detector disablement, and opt-in detector enablement.
- Run supported defaults even when other enabled defaults are unsupported. Preserve findings, name unsupported checks, and return incomplete status until all selected defaults finish.
- If neither source paths nor `--stdin` is provided, use the current working directory. Reuse existing recursive `.rb` discovery, hidden-directory skipping, directory-symlink rejection, and empty-scan behavior.
- Do not add a unified config format or change analyzer pins as part of this feature.
- Primary seam is the compiled CLI process; no new test seam is needed.

## Testing Decisions

- Test external CLI behavior through real process invocations with actual files, directories, and config files. Assert stdout, stderr, report fields, coverage, and exit status.
- Compare no-selection defaults with unchanged pinned Flay and Reek runs on shared supported syntax; verify every default check is either run, explicitly disabled by config, or listed unsupported.
- Verify explicit `--checks` selection and configuration precedence against pinned Reek, including enabled opt-in detectors; config discovery/settings/exclusions still apply, and disabled checks are distinguished from unsupported checks.
- Verify supported findings survive alongside unsupported-default coverage and incomplete status.
- Verify implicit CWD scans, hidden directories, directory symlinks, empty directories, explicit paths, and named stdin.
- Extend existing CLI, combined-analysis, input-discovery, configuration, and report contract patterns. Mutation checks must demonstrate that incorrect default selection, omission reporting, CWD handling, or status can fail the contract.

## Out of Scope

- Implementing opt-in Reek detector analysis itself; that work belongs to full analyzer parity in the existing project spec. This slice verifies how defaults and configuration select checks.
- Changing Flay/Reek or Spinel pins, adding a unified configuration format, machine-readable output, or changing explicit `--checks` semantics.
- Broadening source discovery beyond Fleek’s existing directory rules.

## Further Notes

ADR 0039 supersedes the omitted-check and explicit-source requirements in ADR 0002. `BUNDLE_PATH=<preinstalled-bundle> make flay reek` passed on the repository (Flay score 0; Reek 0 warnings). The direct command without that preinstalled bundle could not find locked gem `reek-6.6.0`.
