# ADR 0013: Reek ClassVariable configuration and suppression

## Status

Accepted.

## Context

Ticket 07 requires existing Reek 6.6.0 configuration discovery, precedence, ClassVariable settings, path and context exclusions, directory scopes, and source comments. The pinned Spinel 2026.09.12 compiler warns that require "yaml" is unavailable and rejects YAML calls at compile time. Fleek must stay a standalone executable and must reject unsupported policy instead of skipping it.

## Decision

Fleek accepts --reek-config FILE. Without it, configuration discovery checks .reek.yml from the current working directory upward, then the home directory. An explicit path overrides discovery. No --config alias is provided.

The native reader accepts a bounded, single-document block YAML subset: root mappings detectors, directories, and exclude_paths; only the selected ClassVariable detector; enabled booleans; block-list exclude and exclude_paths strings; exclude: []; simple quoted or plain scalars; and Reek-style directory globs. Unsupported detectors, keys, malformed mappings or values, flow collections, anchors, aliases, tags, and unsupported comment settings fail before source analysis. Workaround: express settings with the accepted block mappings and lists; remove unrelated detector settings until their checks are implemented.

The Reek quality gate found parser-state and recursive traversal smells in the implementation. Use Reek's own comment suppression only on the ReekConfiguration parser class and affected CLI traversal/report methods; all other project code remains under the default gate. This is a narrow implementation exception, not a new finding policy for analyzed Ruby.

The most specific matching directory directive replaces the global ClassVariable directive. Its path is matched against the source's directory; named stdin uses its supplied origin. ClassVariable exclude values match substrings of the reported context. `exclude_paths` applies to explicit, discovered, and named-stdin inputs. An executed reference check showed Reek 6.6.0 skips excluded stdin with exit 0; Fleek reports it as excluded and returns 1 with “no analysis ran” so success never implies the selected check executed. These exclusions remain limited to smell analysis.

Comments attached before a class support :reek:ClassVariable (disabled by default) and { enabled: false }; { enabled: true } leaves the finding active. An inline comment on the class declaration itself does not suppress the class, matching Reek 6.6.0. Other ClassVariable comment settings fail explicitly.

Reek returns exit 0 when enabled: false skips the explicitly selected ClassVariable check. Fleek instead returns 1 with a configuration diagnostic, because a successful exit must not imply that a selected check ran. Reek also returns 0 when exclusions remove every requested file. Fleek reports excluded coverage and returns 1 with “no analysis ran” when zero sources remain. This is a deliberate status difference; when at least one source is analyzed, findings and status match the reference in the tested cases.

## Evidence

test/configuration_contract.rb compares explicit configuration, discovery/precedence, enabled and disabled detectors, directory overrides and globs, context and path exclusions, comments, and stdin origin against locked Reek 6.6.0. It also confirms malformed mapping lines and list mappings are rejected before source analysis. The pinned compiler probe established the YAML-library limitation; the configuration contract compiles and runs the native reader. All 27 project mutants were caught; fixture/project Flay score and Reek warning count were zero. The pinned Spinel check passed 3,596 tests, alloc report, inference, and spin-e2e.
