Fleek 0.1.0 for macOS Apple silicon (arm64)

Install

1. Extract this archive.
2. Put the extracted `fleek` executable in a directory on PATH, or invoke it by path.
3. Select every check you want to run explicitly. Example:

   ./fleek --checks flay:StructuralDuplication,reek:ClassVariable examples/clean.rb

The executable is a native arm64 Mach-O binary linked only to macOS
libSystem. It needs no Ruby, Flay, Reek, Spinel, project checkout, or network
connection at runtime. The binary has an ad hoc linker signature, with no
Developer ID, and is not notarized. The archive has not been published or
retrieved from a release service.

Identity

Version: Fleek 0.1.0
Implementation compiler: Spinel 2026.09.12
Parser: Prism 1.9.0, statically linked
Reference behavior: Flay 2.14.4 and Reek 6.6.0
Platform: macOS arm64

Supported checks and language

Select `flay:StructuralDuplication`, `reek:ClassVariable`, or both with
`--checks`. Omitting check selection does not run analysis. Input is Ruby
source parsed with Ruby 4 grammar; this does not require analyzed source to
compile as Spinel.

The checks cover bounded syntax only. Flay supports selected top-level
parameterless methods and simple class methods with required positional
parameters, bounded if/else/unless branches, boolean OR expressions, return
statements with supported values, and local-variable assignments. Other
class or method forms can leave sources partial. Fleek prints partial
coverage, exits 1, and never presents that result as complete success.
Reek support is limited to ClassVariable and its documented configuration
subset. Other upstream checks, configuration, and output formats are
unsupported and fail explicitly.

Coverage proof

The pinned 25-file Rails sample corpus produces the Flay score-48 group at
`users_controller.rb:51,58` in both Flay and Fleek, and Reek ClassVariable
is clean in both. Fleek currently marks all 25 Flay sources partial because
class-level Rails declarations and other forms are unsupported; it reports
0/25 fully analyzed and exits 1. This archive therefore demonstrates the
supported native CLI behavior, not complete Rails Flay parity.

Examples

`examples/clean.rb` is a clean complete input for both selected checks.
`examples/finding.rb` demonstrates a Reek ClassVariable finding.
`examples/incomplete.rb` demonstrates preserved Flay findings with explicit
incomplete status.

Notices

`LICENSE-Fleek.txt` contains the Fleek Apache License 2.0 terms.
`LICENSE-Prism.txt` contains the notice and MIT terms for the statically
linked Prism parser.
