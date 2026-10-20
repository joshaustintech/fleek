# ADR 0196: Match Flay control precedence and routing

## Status

Accepted for Ticket 58.

## Context

Flay 2.14.4 accepts repeated `--mass` and `--only` controls, with the last value taking effect. Fleek already matched repeated `--only` but rejected repeated `--mass`. Fleek's optional `--fuzzy` distance was removed from source arguments before `--liberal`; when a source followed bare `--fuzzy`, source filtering consumed that path as if it were a distance. Flay treats fuzzy distance as an optional integer, so only a numeric following token belongs to that option.

Flay `--timeout TIME` changes parser runtime behavior. In bounded probes `--timeout 0` and `--timeout 1` were accepted; `--timeout -1` emitted a warning, skipped the file, and returned score zero. This is an analysis/runtime control and remains a separate gap. `--summary`, `--diff`, `-#`, and `--verbose` alter presentation; they do not change the observed score. Fleek intentionally retains its stable report v1 and does not currently implement those Flay output modes. Track timeout and presentation options separately from analysis parity.

## Decision

Allow repeated `--mass` only when every occurrence has a valid supported integer value, and select the last value for analysis. Reject a malformed earlier or final value before analysis output. Keep repeated `--only` last-value behavior.

When removing optional fuzzy arguments from the source list, consume the following token only when it is an unsigned integer. Bare `--fuzzy` followed by a source path keeps the path available for analysis while the existing fuzzy parser applies its default distance. Preserve explicit fuzzy-distance handling and existing source validation.

Keep summary, diff, numbering, and verbose output modes outside Fleek's report v1. Record their presentation-only classification and unresolved support in Ticket 121. Keep parser timeout as a separate analysis-control gap in Ticket 120. Neither gap may be described as completed parity.

## Consequences

Repeated valid mass controls now match Flay's last-value precedence; malformed repeats still fail before stdout findings. Bare fuzzy mode no longer drops a source when combined with liberal pruning, including combined Reek input filtering through the shared option-removal helper. Existing legacy parser plus `--only class` behavior remains unchanged.

Timeout and presentation controls remain visibly unresolved and linked from Ticket 58 and the Flay control inventory. Fleek report formatting remains stable.

## Evidence

The pinned Spinel contract `test/duplication_control_interactions_contract.rb` compares repeated and reversed `--mass` precedence, bare `--fuzzy` plus `--liberal` routing, and legacy parser plus `--only class` against Flay 2.14.4. Combined Flay+Reek cases verify both fuzzy/liberal and legacy/`--only defn` routing with complete Reek coverage. Existing contracts cover malformed mass, unknown options, check-inapplicable controls, repeated `--only`, and fuzzy distance validation; those errors are asserted before stdout analysis. Probes of Flay 2.14.4 classify `--summary`, `--diff`, `-#`, and `--verbose` as presentation-only by unchanged score. The `--diff` probe could not produce a diff because `ruby2ruby` is not installed. Timeout probes confirm runtime behavior and remain tracked separately.
