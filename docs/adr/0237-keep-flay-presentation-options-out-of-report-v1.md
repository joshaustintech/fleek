# Keep Flay presentation options out of report v1

Accepted for Ticket 121.

Flay 2.14.4's `--summary`, `--diff`, `-#`, and `--verbose` change only presentation and output streams on the pinned fixture; each retains total score 48. Fleek accepts `-#` as a no-op because report v1 group rows are already unnumbered. It rejects `--summary`, `--diff`, and `--verbose` before writing report output because their alternate layout, optional diff dependency, and progress stream do not fit the stable report contract.

The pinned Flay probe used `test/fixtures/duplication_class_methods_rails_pair.rb`. `--summary` prints per-file score in place of groups, `-#` omits group numbering, and `--verbose` writes file progress to stderr. `--diff` writes a fallback notice, `ruby2ruby is required for diff`, because `ruby2ruby` is not installed; the requested diff itself is not rendered. The stable report boundary avoids adding four presentation modes and an optional runtime dependency.

The public contract verifies unchanged Flay score, each option's observable stream/presentation effect, Fleek's no-op numbering behavior including combined Reek coverage, and explicit rejection of the remaining options with empty stdout. A focused mutation proves rejecting `-#` breaks the contract. Analysis controls and timeout behavior remain covered separately.

Verification on pinned Flay 2.14.4 and Spinel `2026.09.12` (`112bae85c1a2`):

- `spinel -E test/duplication_presentation_contract.rb`: passed.
- `make check JOBS=8`: passed; 78 workers, eight mutation workers, all mutants caught, Flay score 1008, Reek 0 warnings.
- `make ticket-check`: 138 documents valid.
- `git diff --check`: passed.
