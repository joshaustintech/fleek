# ADR 0020: Rails parity corpus and release gate

## Status

Accepted.

## Context

Ticket 14 needs evidence on an immutable real Rails application with identical sources and settings for Fleek and unchanged Flay/Reek. The pinned Rails Tutorial app has 25 tracked Ruby files under `app/`, Rails 8.0.0, Ruby 3.3.1, and an MIT/Beerware notice. Its ordinary class inheritance and namespaced Action Cable files expose limits hidden by toy fixtures. On the 25 Ruby files, Flay reports a similar method group with score 48; Reek ClassVariable reports no warnings.

Initial corpus runs also revealed that pointing Flay at the whole app directory includes ERB templates, while Fleek discovers only Ruby files. Comparing those runs would use different inputs and produce a false parity claim.

## Decision

Pin `JetBrains/sample_rails_app_8th_ed` at commit `92ce7c470bc31952d7dc51cac15e577a948e479e` and compare the sorted `app/**/*.rb` manifest only. Use Flay's default mass 16, Reek's `ClassVariable` detector with default settings, and Fleek's matching explicit check selection. Preserve source files and the upstream license notice by reference; do not vendor the corpus.

ClassVariable support accepts one simple class declaration with a superclass, because the superclass does not change the detector's local class-variable traversal. Nested namespace scopes remain unsupported until their context naming and traversal match Reek. Flay remains incomplete for class-contained methods; the discovered score-48 group is evidence of useful upstream behavior that Fleek must implement before claiming project parity.

Keep incomplete status and exit 1 for the current full corpus. A clean reference result does not authorize Fleek success if any selected file/check did not run. Release and cold-runtime acceptance depend on full selected-input parity on this corpus; do not hide the two ClassVariable failures or 25 Flay failures through path exclusions.

## Consequences

The real-project limitation and exact versions, manifest, commands, results, and next capability work are recorded in [the parity receipt](../research/rails-project-parity.md). Tickets 18 and 19 track namespace and ordinary class-method Flay coverage. Tickets 15–17 remain blocked until that work yields comparable complete runs.

## Evidence

`test/class_variable_contract.rb` compares an inherited-class finding to unchanged Reek. `test/mutation_contract.rb` proves that restoring the inheritance rejection breaks the public CLI contract.
