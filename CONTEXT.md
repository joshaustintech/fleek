# Fleek

Fleek helps Ruby developers identify duplicate code and code smells. Its goal is a useful replacement for Flay and Reek in everyday Ruby development.

## Language

**Analyzed source**: Ruby 4.0 or Spinel source code examined by Fleek, including Ruby code in Rails projects. The language of analyzed source is independent of the language used to implement Fleek.

**Finding**: A report of duplicate code or a code smell in analyzed source.

**Unsupported check**: A Flay or Reek check that Fleek does not yet implement. Its absence must be documented explicitly.

**Default check set**: The checks Flay and Reek enable during ordinary invocation at their pinned versions, unless the user explicitly selects checks or configuration disables a detector.

**Full analyzer parity**: Fleek matches every built-in check and detector, including opt-in detectors, and their analysis controls on shared syntax against the pinned Flay and Reek versions. Fleek-specific report formatting and documented exit-code normalization are allowed.

**Shared syntax**: Analyzed-source syntax accepted by both the selected reference analyzers and Fleek. It permits direct comparison of finding behavior.

**Extension behavior**: Finding behavior for supported analyzed-source syntax outside an unchanged reference analyzer's accepted language. It requires separately reviewed expectations rather than a claim of unchanged-reference parity.
