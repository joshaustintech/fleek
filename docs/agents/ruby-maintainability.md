# Maintainable Ruby for the CLI

Guidance synthesized from DHH, Noel Rappin, Sam Ruby, and Dave Thomas. These are design defaults for this CLI, not universal style laws. Rails-specific practices are out of scope.

| Avoid | Prefer |
| --- | --- |
| Hidden behavior from `eval`, runtime metaprogramming, dynamic `send`, global mutation, or implicit dependencies. These also conflict with pinned Spinel. | Ordinary methods, explicit arguments, small collaborators, and a visible call graph. |
| One method or class that parses input, analyzes source, formats output, and exits. | Keep argv and process I/O at CLI edges; let analysis return values or errors that tests can call directly. Extract only when a name clarifies a real responsibility. |
| Abstraction made only to remove similar-looking lines; unrelated rules can change for different reasons. | Share stable knowledge and behavior. Keep coincidental duplication until a common rule is clear. |
| Repeating one policy in code, tests, docs, or defaults. | Keep each rule authoritative in one place; have tests and docs refer to it where practical. |
| Comments that paraphrase code, cryptic names, or clever compression that hides intent. | Name methods and values after their purpose; comment non-obvious constraints and reasons. Use concise Ruby syntax when it reads clearly. |
| Tests that assert private call sequences or require large setup. | Test observable CLI and analysis behavior in small examples. Treat hard-to-test code as a design signal; use mutation checks to show tests detect wrong behavior. |
| Broad rescue-and-continue behavior that hides bad input or analyzer bugs. | Handle expected user errors at the CLI boundary with useful diagnostics and status codes; let unexpected faults remain visible during development. |
| Adding layers, options, or extension points “for later.” | Ship the smallest coherent design that serves a demonstrated use case; revise when real pressure appears. |

Preserve supported upstream checks and let users choose which checks to enable, as decided in `../adr/0001-compatible-native-replacement.md`. For deliberately introduced checks, make each finding name a concrete risk and concise repair; enforce only explicit repo style choices and avoid forcing abstractions without evidence.

## Source basis

- [DHH, “A writer's Ruby”](https://world.hey.com/dhh/a-writer-s-ruby-2050b634): Ruby style is expressive and personal; a linter should help a team enforce its chosen style.
- [Noel Rappin, “Development-Driven Testing”](https://noelrappin.com/2016/06/development-driven-testing/): small tests clarify interfaces and reveal design friction; tests should fail when they are meant to prove behavior.
- [Sam Ruby, Spinel 2026.09.12 limitations](https://github.com/matz/spinel/blob/2026.09.12/docs/limitations.md): whole-program AOT constraints make runtime evaluation and open-ended metaprogramming poor fits.
- [Dave Thomas and Andrew Hunt, “The Evils of Duplication”](https://media.pragprog.com/titles/tpp20/dry.pdf): DRY means avoiding duplicated knowledge and intent, not mechanically eliminating repeated lines.
