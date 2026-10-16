# ADR 0043: Add bounded native Reek object and scope detectors

## Status

Accepted.

## Context

Ticket 03 requires Reek's Attribute, InstanceVariableAssumption, IrresponsibleModule, ModuleInitialize, and SubclassedFromCoreClass defaults to run beside the existing ClassVariable detector. Fleek compiles to a standalone Spinel executable and cannot load Reek's Ruby runtime. Each native detector therefore needs an explicit supported syntax boundary and must not report unsupported input as clean.

## Decision

Implement each detector with the pinned Prism parser in C, retain per-detector configuration and exclusions, and share the CLI reporting path for configuration loading, source coverage, findings, and unsupported input. Compare findings and messages with Reek 6.6.0 on supported fixtures.

The initial syntax subset supports literal public `attr_accessor`, `attr_writer`, and writable `attr` declarations in one simple class or module; one simple class for InstanceVariableAssumption; direct inheritance from Array, Hash, or String; direct instance methods in one simple module for ModuleInitialize; and one simply named class or module with descriptive leading comments for IrresponsibleModule. For comment descriptions, Fleek removes Reek directive tokens and their option hashes before counting prose. Existing ClassVariable behavior remains unchanged.

Forms the native scanners cannot model must be reported as unsupported and make coverage incomplete. This includes dynamic or otherwise unsupported `attr` declarations, `Class.new(...)` constant-assignment contexts for SubclassedFromCoreClass and IrresponsibleModule, malformed syntax, unsupported scopes, and comment-list overflow. A read-only `attr :name` and unrelated `Class.new` calls remain clean when Reek does. Do not omit unsupported forms and report a clean result.

## Consequences

Supported source shapes retain matching Reek findings and messages. Unsupported shapes may have findings in Reek, but Fleek reports its coverage gap explicitly and returns an incomplete result. The source scope limits are included in reports so users can see which syntax is covered.

## Evidence

`test/default_object_scope_contract.rb` compares supported default findings, explicit Attribute selection, configuration exclusions and directory precedence against locked Reek 6.6.0. It also checks that unsupported `attr`, `Class.new`, and oversized comment inputs do not appear clean, and that Reek directives and option hashes do not count as prose. `make check` passed with pinned Spinel identity, 17 process contracts, all 107 mutation cases caught, reference checks, Flay score 0, and Reek 0 warnings. Specification and standards reviews found no remaining actionable issues.
