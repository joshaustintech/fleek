# ADR 0194: Match Flay ignore path expansion

## Status

Accepted for Ticket 56.

## Context

Flay 2.14.4 delegates `.flayignore` filtering to PathExpander 2.0.1. It partitions patterns by whether they contain `/`: slashless entries expand at the working directory and match files with no flags, so a wildcard can cross directory boundaries; slash-containing patterns use `FNM_PATHNAME`. A trailing slash matches an exact parent directory; comments have no special syntax. A missing ignore file means no exclusions, while an existing unreadable path fails before analysis.

## Decision

Keep Fleek's native `File.fnmatch?` implementation aligned with PathExpander's two pattern classes: use no flags for slashless patterns and `FNM_PATHNAME` for slash-containing patterns. Spinel's matcher treats path separators as boundaries even with no flags, so replace separators with a control-character sentinel before matching slashless patterns; this lets wildcards span directories as in CRuby. Use `File.exist?` to distinguish a missing `.flayignore` from an existing path that `File.read` cannot read; preserve the error instead of silently disabling ignore filtering. Do not merge `.flayignore` with Reek exclusions.

## Consequences

Slash-containing literal paths, slashless literals, directory suffixes, root and nested basename globs, nested slash-containing globs, blank lines, hash-prefixed literal patterns, and no-match patterns select the same files in Flay and Fleek. Slashless globs can match nested basenames, while a slashless literal matches only its root-level path. The tested directory suffix matches immediate children only; a nested directory is not excluded. A missing `.flayignore` remains clean. An existing directory named `.flayignore` is rejected by both tools, with Fleek reporting incomplete input and no duplication findings.

## Evidence

The compiled public contract compares Flay and Fleek score, source inclusion/exclusion, coverage, status, and streams on a temporary source tree. It covers an absent ignore file and a directory at `.flayignore` as the unreadable-path case. The `Flay unreadable ignore file` mutation restores the old `File.file?` check and is caught by that public contract.
