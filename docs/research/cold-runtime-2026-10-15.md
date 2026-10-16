# Fleek cold CLI runtime evidence

## Identity

- Host: Darwin arm64; macOS 27.0.1 (26A434).
- Source revision: `45b60d25bfa28c4ef5735c62fbc317644faa47b5` (`v0.2.0`).
- Release measured: Fleek 0.2.0 working-tree build, with versioned package and module-method archive example.
- Source `bin/fleek.rb` SHA-256: `89dc20e961c2fd9c024a51921f9e65cc7f555f8f51b48909d3f8d86d3d016aaf`; it matches the committed file at the source revision. The measurements ran from the release worktree before commit, with this exact source file and executable hash.
- Fleek executable SHA-256 (before and after): b4da0770300edc4d5f79bd902c7b5d57cdbe01f30661321021582dfd4c6bde0b.
- Spinel measurement helper SHA-256 (before and after): c4dc03c3bb47eaa51c79898f124e8fd350715c8b9b8bd748008d3d878de46877.
- Compiler: Spinel 2026.09.12; reference analyzers: Flay 2.14.4 and Reek 6.6.0; reference Ruby: ruby 3.4.9 (2026-03-11 revision 76cca827ab) +PRISM [arm64-darwin23].
- Flay and combined input: `test/fixtures/duplication_class_methods_or.rb`; SHA-256 (before and after): afb763c97a9bec713ca1fc21de035220f813e0f5714491d9177dbb9f0c450570; immutable one-file fixture with one duplicated class-method group.
- Reek input: `$FLEEK_RAILS_CORPUS/app`; pinned commit and clean status (before and after): 92ce7c470bc31952d7dc51cac15e577a948e479e (clean); exact 25-file Ruby manifest from the Rails parity receipt.
- Configuration: Flay mass 16; Reek `--smell ClassVariable --no-progress`; matching explicitly selected Fleek checks; no config files or exclusions.

## Reproduce

Set `SPINEL` to the pinned 2026.09.12 executable, `BUNDLE_PATH` to the locked dependency bundle, and `FLEEK_RAILS_CORPUS` to the clean pinned checkout, then run `make runtime-evidence` (20 repetitions by default).

## Method

Each observation starts a fresh process and includes process startup, input reading, selected analysis, and process exit. Cold means fresh process only. OS filesystem caches stayed natural and were not evicted. Each reference command includes `bundle exec`. Combined reference work runs Flay then Reek sequentially on the duplicate fixture; Fleek runs both in one process on that same input. The six variants ran 20 times each, with pair order alternated on every repetition. Every output, stderr stream, and exit status passed the equivalence gate before its timing was retained.

## Equivalence

Equivalence is semantic; reference and Fleek stdout formats are intentionally different and were not compared byte-for-byte. Flay prints its prose report while Fleek uses its structured `Group` and coverage report. On identical Flay input, Flay 2.14.4 and Fleek both report one similar `:defn` group, mass/score 34, lines 2 and 12, complete 1/1 coverage, and no stderr. Flay exits 0 for findings; Fleek exits 2 by its declared CLI contract. Combined reference Flay plus Reek commands both exit 0; combined Fleek reports the identical Flay group, complete 1/1 coverage for both checks, and exits 2 for findings. On the identical pinned 25-file Rails `app/` input, Reek 6.6.0 reports 0 warnings; Fleek Reek reports 25/25 analyzed, complete, no findings, and exit 0. The Flay exit difference is intentional and documented in ADRs 0002 and 0018.

## Summary

Variant | n | median ms | p95 ms | min ms | max ms
---|---:|---:|---:|---:|---:
flay-reference | 20 | 157.233 | 165.433 | 156.373 | 169.982
flay-fleek | 20 | 3.478 | 3.854 | 3.318 | 3.935
reek-rails-reference | 20 | 342.344 | 358.99 | 334.593 | 360.033
reek-rails-fleek | 20 | 5.969 | 6.432 | 5.829 | 9.652
combined-reference | 20 | 465.396 | 476.859 | 457.077 | 490.496
combined-fleek | 20 | 3.604 | 4.01 | 2.989 | 4.074

Target: Fleek p95 must be no slower than the corresponding pinned reference p95 for the same complete work. This ties target to observed upstream CLI cost and keeps combined work comparable.

- Flay fixture: target <= 165.433 ms p95; observed 3.854 ms; met.
- Reek ClassVariable Rails corpus: target <= 358.99 ms p95; observed 6.432 ms; met.
- Combined fixture: target <= 476.859 ms p95; observed 4.01 ms; met.

## Raw observations

order | repetition | variant | ms
---:|---:|---|---:
1 | 1 | flay-reference | 164.524
2 | 1 | flay-fleek | 3.367
3 | 1 | reek-rails-reference | 341.36
4 | 1 | reek-rails-fleek | 5.889
5 | 1 | combined-reference | 464.999
6 | 1 | combined-fleek | 3.671
7 | 2 | combined-fleek | 2.989
8 | 2 | combined-reference | 460.349
9 | 2 | reek-rails-fleek | 5.999
10 | 2 | reek-rails-reference | 352.259
11 | 2 | flay-fleek | 3.499
12 | 2 | flay-reference | 157.188
13 | 3 | flay-reference | 156.935
14 | 3 | flay-fleek | 3.373
15 | 3 | reek-rails-reference | 346.891
16 | 3 | reek-rails-fleek | 5.921
17 | 3 | combined-reference | 460.978
18 | 3 | combined-fleek | 3.958
19 | 4 | combined-fleek | 3.106
20 | 4 | combined-reference | 457.077
21 | 4 | reek-rails-fleek | 5.838
22 | 4 | reek-rails-reference | 339.089
23 | 4 | flay-fleek | 3.489
24 | 4 | flay-reference | 157.233
25 | 5 | flay-reference | 161.809
26 | 5 | flay-fleek | 3.524
27 | 5 | reek-rails-reference | 349.355
28 | 5 | reek-rails-fleek | 6.218
29 | 5 | combined-reference | 470.448
30 | 5 | combined-fleek | 3.651
31 | 6 | combined-fleek | 3.254
32 | 6 | combined-reference | 462.227
33 | 6 | reek-rails-fleek | 5.99
34 | 6 | reek-rails-reference | 339.757
35 | 6 | flay-fleek | 3.478
36 | 6 | flay-reference | 156.555
37 | 7 | flay-reference | 158.952
38 | 7 | flay-fleek | 3.377
39 | 7 | reek-rails-reference | 344.05
40 | 7 | reek-rails-fleek | 5.969
41 | 7 | combined-reference | 470.523
42 | 7 | combined-fleek | 3.646
43 | 8 | combined-fleek | 3.064
44 | 8 | combined-reference | 461.488
45 | 8 | reek-rails-fleek | 6.346
46 | 8 | reek-rails-reference | 347.295
47 | 8 | flay-fleek | 3.503
48 | 8 | flay-reference | 156.52
49 | 9 | flay-reference | 157.661
50 | 9 | flay-fleek | 3.47
51 | 9 | reek-rails-reference | 345.744
52 | 9 | reek-rails-fleek | 5.851
53 | 9 | combined-reference | 466.048
54 | 9 | combined-fleek | 4.074
55 | 10 | combined-fleek | 3.604
56 | 10 | combined-reference | 490.496
57 | 10 | reek-rails-fleek | 6.42
58 | 10 | reek-rails-reference | 339.745
59 | 10 | flay-fleek | 3.521
60 | 10 | flay-reference | 156.876
61 | 11 | flay-reference | 157.147
62 | 11 | flay-fleek | 3.389
63 | 11 | reek-rails-reference | 336.307
64 | 11 | reek-rails-fleek | 6.432
65 | 11 | combined-reference | 469.145
66 | 11 | combined-fleek | 3.668
67 | 12 | combined-fleek | 3.24
68 | 12 | combined-reference | 464.521
69 | 12 | reek-rails-fleek | 5.939
70 | 12 | reek-rails-reference | 340.662
71 | 12 | flay-fleek | 3.935
72 | 12 | flay-reference | 157.101
73 | 13 | flay-reference | 156.815
74 | 13 | flay-fleek | 3.495
75 | 13 | reek-rails-reference | 338.891
76 | 13 | reek-rails-fleek | 5.989
77 | 13 | combined-reference | 476.859
78 | 13 | combined-fleek | 4.01
79 | 14 | combined-fleek | 3.059
80 | 14 | combined-reference | 457.684
81 | 14 | reek-rails-fleek | 5.841
82 | 14 | reek-rails-reference | 358.99
83 | 14 | flay-fleek | 3.699
84 | 14 | flay-reference | 158.128
85 | 15 | flay-reference | 156.373
86 | 15 | flay-fleek | 3.387
87 | 15 | reek-rails-reference | 345.028
88 | 15 | reek-rails-fleek | 5.907
89 | 15 | combined-reference | 462.938
90 | 15 | combined-fleek | 3.717
91 | 16 | combined-fleek | 3.007
92 | 16 | combined-reference | 468.626
93 | 16 | reek-rails-fleek | 5.984
94 | 16 | reek-rails-reference | 342.344
95 | 16 | flay-fleek | 3.54
96 | 16 | flay-reference | 165.433
97 | 17 | flay-reference | 158.235
98 | 17 | flay-fleek | 3.367
99 | 17 | reek-rails-reference | 334.593
100 | 17 | reek-rails-fleek | 5.872
101 | 17 | combined-reference | 466.074
102 | 17 | combined-fleek | 3.637
103 | 18 | combined-fleek | 3.051
104 | 18 | combined-reference | 474.764
105 | 18 | reek-rails-fleek | 9.652
106 | 18 | reek-rails-reference | 349.577
107 | 18 | flay-fleek | 3.854
108 | 18 | flay-reference | 169.982
109 | 19 | flay-reference | 159.991
110 | 19 | flay-fleek | 3.318
111 | 19 | reek-rails-reference | 335.156
112 | 19 | reek-rails-fleek | 5.829
113 | 19 | combined-reference | 465.396
114 | 19 | combined-fleek | 3.903
115 | 20 | combined-fleek | 3.155
116 | 20 | combined-reference | 466.736
117 | 20 | reek-rails-fleek | 6.108
118 | 20 | reek-rails-reference | 360.033
119 | 20 | flay-fleek | 3.327
120 | 20 | flay-reference | 158.638
