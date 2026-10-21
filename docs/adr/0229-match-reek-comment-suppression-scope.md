# Match Reek comment suppression scope

Accepted for Ticket 92.

## Context

Reek 6.6.0 applies detector comments to the class or method they precede. Repeated directives for the same detector in one comment use the last directive's configuration. Fleek's existing ClassVariable coverage did not verify equivalent method-level behavior for a direct method detector.

## Decision

Verify LongParameterList comment suppression through the public CLI against Reek 6.6.0. Carry the parsed class or module node explicitly into method analysis, apply its directive as the inherited setting, and let a method directive override it. Within a comment, use the last matching detector directive, including its `enabled` setting. A top-level method has no class or module setting and is evaluated only against its own preceding comments.

Keep ClassVariable's existing public suppression contract as the class-wide detector case. Do not broaden this change into general comment configuration parsing.

## Consequences

The contracts cover class-wide and method-local suppression, an `enabled: false` directive, repeated directives in both orders, and an adjacent unsuppressed method. Fleek and pinned Reek reports match for these cases. Top-level methods remain safe when no enclosing scope exists. Other comment syntax and detector settings remain outside this ticket's verified boundary.
