# 23: Flay analysis-control parity

**What to build:** Flay-specific settings and analysis-affecting controls produce the same structural duplication result and selected source set as pinned Flay 2.14.4.

**Blocked by:** None (can start immediately).

**Status:** claimed
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Inventory the pinned Flay 2.14.4 analysis-affecting options and path controls, then match their behavior in Fleek.
- [ ] Match mass thresholds, pruning modes, fuzzy detection, parser mode selection, `.flayignore`, and relevant path expansion behavior against the pinned reference; distinguish presentation-only options from analysis controls.
- [ ] Validate invalid, repeated, conflicting, and check-inapplicable controls before analysis with clear diagnostics.
- [ ] Keep Fleek report formatting and documented exit-code normalization while comparing semantic results.
- [ ] Compare public CLI behavior against unchanged Flay 2.14.4 and protect controls and precedence with mutation checks.

## Answer

Inventory confirms Flay 2.14.4 controls: analysis-affecting `--mass`, `--fuzzy [DIFF]`, `--liberal`, `--legacy`, and `--only NODE`; presentation/runtime controls include `--summary`, `--diff`, `-#`, `--verbose`, and `--timeout`. Fleek already supports bounded `--mass`, `.flayignore`, and recursive `**/*.rb` path expansion; other unsupported Flay controls fail closed. New slice rejects `--mass` on Reek-only selections and `--reek-config` on Flay-only selections before analysis. Public CLI contracts require empty stdout, and named mutations target each applicability rule. ADR 0106 records this validation rule. Remaining controls and path-option parity are still in progress.
