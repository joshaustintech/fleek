# ADR 0050: Preserve multiple Flay class and module groups

## Status

Accepted.

## Context

The bounded class-group detector initially had a single-result native boundary. That lost Flay 2.14.4 parity when one source contained both a scope group and an independent method group, and did not represent direct module groups. Sorting or scoring only one result could not preserve independent verified findings.

## Decision

Have the native analyzer serialize every verified group as a deterministic record containing node kind, similar/identical classification, mass, weighted score, and source lines. Keep per-file score allocation in the Ruby report layer. Emit complete outer class/module groups only when the supported direct scope candidates completely cover that scope; suppress only method candidates already represented by a verified outer-scope group. Keep unsupported forms incomplete while retaining independent verified groups. Sort findings by descending score, then source location and node; sort locations by path and line.

Support bounded direct class methods at file scope and in one-level module namespaces, plus direct module methods in a simple module or a sole nested-module chain up to eight modules. The fixed depth keeps native candidate storage bounded; deeper chains are marked partial. Class/module grouping accepts multiple methods only when every direct body entry is a supported method and each candidate shape matches in source order. Broader class bodies and general Flay grammar remain outside the implemented bound; do not claim those shapes complete.

## Consequences

Fleek preserves independent `:defn` and outer-scope findings, reports similar and identical class/module groups with multiple methods, and deterministically orders multiple groups. The root-class to one-level-namespace-class fixture proves cross-scope class grouping. Unsupported class or method syntax continues to produce incomplete coverage.

## Evidence

`test/duplication_contract.rb` compares clean nested scopes, module, identical-module, cross-class, nested-module chains through the eight-module limit, the nine-module incomplete boundary, nested cross-scope, multi-method class/module, mixed multi-group, and three-candidate method outputs against pinned Flay 2.14.4. `test/mutation_contract.rb` kills mutations for candidate collection, the exact depth boundary, completeness, independent groups, identity, group kind, mass/score, locations, file-score allocation, and ordering. Full acceptance remains tracked in Ticket 21.
