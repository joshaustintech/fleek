# Resolve upstream conflicts in one analysis mode

Fleek combines duplication and code-smell analysis in one mode. Flay and Reek assign different meanings to several short options and have different reporting and exit behavior, so unchanged compatibility with both CLI contracts is impossible. Use distinct long options and omit conflicting short aliases; preserve supported finding and configuration semantics and document CLI differences. See `../research/combined-cli-conflicts.md` for versioned upstream evidence.

Produce one text report with separate duplication and smell sections. Preserve locations, grouping, scores, and ordering within each section; do not invent a combined score. Machine formats are deferred; explicit requests for unsupported formats fail.

Exit status is 0 for complete analysis with no findings, 2 for complete analysis with findings, and 1 for an error or incomplete analysis. Errors take precedence over findings. This deliberately changes Flay's findings status and prevents skipped or unsupported analysis from reporting success.

Require explicit source paths or `--stdin`. No arguments prints usage to stderr and exits 1; explicit `--help` prints help and exits 0. Stdin requires a source filename so configuration scope and finding locations remain meaningful.

Import existing Reek YAML and `.flayignore` before introducing a unified Fleek configuration file. Preserve supported configuration behavior and reject unsupported settings explicitly. `.flayignore` exclusions apply only to duplication analysis; Reek exclusions apply only to smell analysis. Do not merge these into exclusions shared by both analyzers.

Use `--checks flay:default,reek:ClassVariable` to select supported analysis. Unknown or unsupported selections fail; omitting selection must not silently narrow upstream defaults.

Directory scans recursively include `.rb` files, skip hidden directories, and do not follow directory symlinks. Explicit non-Ruby files fail. These discovery boundaries are documented CLI behavior rather than a promise of identical upstream path expansion; detailed file-symlink, repeated-path, empty-scan, and partial-failure rules live in ADR 0011.

Invalid options or configuration fail before analysis. If a requested file cannot be analyzed, continue checking other files, retain useful findings, identify failed files, mark the report incomplete, and exit 1.

CLI output must be clear to both humans and agents. Use a stable text layout with check names, source locations, separate diagnostics, and explicit complete/incomplete status. Show checks run and coverage limits; machine formats remain deferred. Exact field syntax and escaping remain to be specified and tested.
