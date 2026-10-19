# ADR 0166: Route collection mutations to focused contracts

Collection-node mutation labels previously ran `test/duplication_contract.rb`, which took 51.54 seconds for its pinned differential suite. Keep that broad contract as the full regression gate, but route array and keyword-hash descriptor mutations through a focused compiled-CLI/Flay contract. Route descriptor support to the same contract and multiple-assignment mass/identity mutations to the existing multiple-assignment contract. Hash-rocket and splat mutations already have dedicated contracts.

On the pinned Spinel 2026.09.12 environment with `JOBS=8`, the one-label array mutation run fell from 29.57 seconds to 12.65 seconds with the same mutant caught. All eight focused collection and descriptor mutations passed together. This preserves full mutation coverage while avoiding unrelated analyzer fixtures per mutant.
