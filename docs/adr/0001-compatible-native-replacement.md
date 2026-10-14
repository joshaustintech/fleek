# Build a compatible native replacement for Flay and Reek

Fleek will provide one fast native CLI for ordinary Ruby projects, including Rails projects. Combine duplication and code-smell analysis in a single mode, rather than separate Flay and Reek subcommands. Preserve existing Flay and Reek finding behavior and configuration wherever supported, document unsupported checks explicitly, and record deliberate behavior changes as decisions. A useful replacement takes priority over introducing a new lint philosophy; conflicting upstream CLI behavior requires research and explicit resolution.

Pin Flay 2.14.4 (`1ec4d87f2209a3ae216aece69a4ecc8b688cd459`) and Reek 6.6.0 (`e0048db109ea13630630bf130492025cd1c786a5`) as reference behavior. The reference environment must also pin their dependencies and Ruby interpreter; those exact pins remain to be established. Verify identical inputs and configuration against findings, locations, scores, and exit status; document differences. Preserve supported upstream checks and let users choose which checks to enable rather than omitting checks based on Fleek's own lint philosophy.

Early releases may support a documented subset. If any enabled check is unsupported, including a check enabled by default, fail and identify it. Users must explicitly select supported checks; successful exit must never imply that omitted checks ran.

Use the pinned Spinel release specified in `docs/agents/spinel.md` as the implementation compiler; analyzed source does not need to compile under Spinel. Seek workarounds for compiler blockers and narrow the first release when necessary. Compiler limitations do not by themselves authorize changing the pin.

The installed Fleek executable must run without CRuby, Flay, or Reek installed. Original tools may be used during development to verify reference behavior. Workarounds must preserve this runtime independence.

The initial release targets macOS on Apple Silicon. Prove native installation and useful checks on that platform before adding other targets. Correctness is mandatory; record cold CLI runtime against pinned originals on identical source and set a performance target from that evidence.

The first release analyzes `.rb` source files only. ERB and upstream plugins are deferred, and explicit requests for unsupported formats fail. Directory-scan boundaries are specified in `0002-single-mode-cli-contract.md`.

Analyzed source targets Ruby 4.0 and source accepted by pinned Spinel 2026.09.12, including its documented syntax extensions. This replaces the proposed Ruby 3.3 syntax target; it does not change the pinned Spinel implementation compiler. Later Ruby language versions require separate proof. Reference behavior for syntax the original analyzers cannot parse is specified in `0004-language-targets-and-reference-boundaries.md`.

Distribute the first release as a downloadable macOS arm64 executable archive with version information, reference pins, and required license notices. Verify that the installed executable runs without Ruby, Flay, or Reek installed.
