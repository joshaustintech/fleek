# Match qualified module names

Accepted for Ticket 87.

## Context

Reek 6.6.0 applies `UncommunicativeModuleName` patterns to the terminal constant in a qualified declaration and reports the complete constant path as context. Fleek only handled a simple constant read, so a qualified class or module name was incomplete.

## Decision

Support one-level qualified class and module declarations whose constant path has a simple parent and terminal constant. Match accept/reject patterns against the terminal constant, and preserve the complete qualified path in findings. Keep deeper paths and lexical nested declarations incomplete.

## Consequences

The public CLI contract covers a short terminal name, a descriptive control, configured accept/reject patterns, and a deeper unsupported path. It compares Reek's qualified context, terminal name, and source line.
