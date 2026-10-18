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

Inventory confirms Flay 2.14.4 controls: analysis-affecting `--mass`, `--fuzzy [DIFF]`, `--liberal`, `--legacy`, and `--only NODE`; presentation/runtime controls include `--summary`, `--diff`, `-#`, `--verbose`, and `--timeout`. Fleek already supports bounded `--mass`, `.flayignore`, recursive `**/*.rb` path expansion, and `--only NODE` report filtering with total score preserved and last repeated value taking effect. Reek-only selections reject `--mass` and `--only`, and Flay-only selections reject `--reek-config` before analysis. ADRs 0106 and 0107 record these rules. Remaining controls and path-option parity are still in progress.
