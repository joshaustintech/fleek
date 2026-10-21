# 23: Flay analysis-control parity

**What to build:** Flay-specific settings and analysis-affecting controls produce the same structural duplication result and selected source set as pinned Flay 2.14.4.

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

Inventory confirms Flay 2.14.4 controls: analysis-affecting `--mass`, `--fuzzy [DIFF]`, `--liberal`, `--legacy`, and `--only NODE`; presentation/runtime controls include `--summary`, `--diff`, `-#`, `--verbose`, and `--timeout`. Fleek supports bounded `--mass`, `.flayignore`, recursive `**/*.rb` path expansion, `--only NODE` filtering, and `--liberal` pruning, with full total score and last-value behavior preserved for repeated `--only`. Reek-only selections reject Flay-specific controls. ADRs 0106, 0107, and 0109 record these rules. Ticket 59 reconciles this inventory with evidence from tickets 10 and 53–58. Tickets 120 and 128 resolve timeout behavior (see [ADR 0233](../../../docs/adr/0233-isolate-flay-timeout-analysis.md) and [ADR 0236](../../../docs/adr/0236-continue-flay-analysis-after-per-file-timeout.md)). Ticket 121 accepts `-#` as an unnumbered-report no-op and leaves alternate summary/diff/verbose output unsupported (see [ADR 0237](../../../docs/adr/0237-keep-flay-presentation-options-out-of-report-v1.md)).
