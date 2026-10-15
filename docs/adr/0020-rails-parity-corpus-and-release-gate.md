# ADR 0020: Rails parity corpus and release gate

## Status

Accepted. Its full-parity prerequisite for the bounded first release is superseded by [ADR 0037](0037-bounded-rails-flay-release-acceptance.md); this ADR remains authoritative for the pinned corpus and exact inputs.

## Context

Ticket 14 needs evidence on an immutable real Rails application with identical sources and settings for Fleek and unchanged Flay/Reek. The pinned Rails Tutorial app has 25 tracked Ruby files under `app/`, Rails 8.0.0, Ruby 3.3.1, and an MIT/Beerware notice. Its ordinary class inheritance and namespaced Action Cable files expose limits hidden by toy fixtures. On the 25 Ruby files, Flay reports a similar method group with score 48; Reek ClassVariable reports no warnings.

Initial corpus runs also revealed that pointing Flay at the whole app directory includes ERB templates, while Fleek discovers only Ruby files. Comparing those runs would use different inputs and produce a false parity claim.

## Decision

Pin `JetBrains/sample_rails_app_8th_ed` at commit `92ce7c470bc31952d7dc51cac15e577a948e479e` and compare the sorted `app/**/*.rb` manifest only. Use Flay's default mass 16, Reek's `ClassVariable` detector with default settings, and Fleek's matching explicit check selection. Preserve source files and the upstream license notice by reference; do not vendor the corpus.

At the T14 baseline, ClassVariable support accepted one simple class declaration with a superclass, because the superclass does not change the detector's local class-variable traversal; namespaced scopes remained unsupported. Ticket 18 later added one direct namespace level (ADR 0021), while deeper or ambiguous namespace shapes remain unsupported. Flay remains incomplete for class-contained methods; the discovered score-48 group is evidence of useful upstream behavior that Fleek must implement before claiming project parity.

Keep incomplete status and exit 1 for the current full corpus. A clean reference result does not authorize Fleek success if any selected file/check did not run. At the time of this decision, release and cold-runtime acceptance were held for full selected-input parity on this corpus; do not hide the two ClassVariable failures or 25 Flay failures through path exclusions. ADR 0037 later accepts the documented bounded first-release scope while preserving the incomplete result and making no full-parity claim.

## Consequences

The real-project limitation and exact versions, manifest, commands, results, and next capability work are recorded in [the parity receipt](../research/rails-project-parity.md). Ticket 18 closes the namespace gap for ClassVariable; ticket 19 tracked ordinary class-method Flay coverage and is resolved for bounded first-release scope by ADR 0037. Tickets 15–17 were held at this decision point pending complete combined runs; their later bounded evidence and verified release are recorded separately.

## Evidence

`test/class_variable_contract.rb` compares an inherited-class finding to unchanged Reek. `test/mutation_contract.rb` proves that restoring the inheritance rejection breaks the public CLI contract.
