# Fleek cold CLI runtime evidence

## Identity

- Host: Darwin arm64; macOS 27.0.1 (26A434).
- Source revision: 34e56f5e9a21a8a2d74a5a2013910770460c9bb6.
- Fleek executable SHA-256 (before and after): e920ca3ed8da115adde10bf5adc865d994ea5235ac37dd4b1ce14df3f3fadcff.
- Spinel measurement helper SHA-256 (before and after): 4b2709b32b05695d56cd0f14ab42a4f467412e79a940b179679d14590882c015.
- Compiler: Spinel 2026.09.12; reference analyzers: Flay 2.14.4 and Reek 6.6.0; reference Ruby: ruby 3.4.9 (2026-03-11 revision 76cca827ab) +PRISM [arm64-darwin23].
- Flay and combined input: `test/fixtures/duplication_class_methods_or.rb`; SHA-256 (before and after): afb763c97a9bec713ca1fc21de035220f813e0f5714491d9177dbb9f0c450570; immutable one-file fixture with one duplicated class-method group.
- Reek input: `$FLEEK_RAILS_CORPUS/app`; pinned commit and clean status (before and after): 92ce7c470bc31952d7dc51cac15e577a948e479e (clean); exact 25-file Ruby manifest from the Rails parity receipt.
- Configuration: Flay mass 16; Reek `--smell ClassVariable --no-progress`; matching explicitly selected Fleek checks; no config files or exclusions.

## Reproduce

Set `SPINEL` to the pinned 2026.09.12 executable, `BUNDLE_PATH` to the locked dependency bundle, and `FLEEK_RAILS_CORPUS` to the clean pinned checkout, then run `make runtime-evidence` (20 repetitions by default).

## Method

Each observation starts a fresh process and includes process startup, input reading, selected analysis, and process exit. Cold means fresh process only. OS filesystem caches stayed natural and were not evicted. Each reference command includes `bundle exec`. Combined reference work runs Flay then Reek sequentially on the duplicate fixture; Fleek runs both in one process on that same input. The six variants ran 20 times each, with pair order alternated on every repetition. Every output, stderr stream, and exit status passed the equivalence gate before its timing was retained.

## Equivalence

On identical Flay input, Flay 2.14.4 and Fleek both report one similar `:defn` group, mass/score 34, lines 2 and 12, complete 1/1 coverage, and no stderr. Flay exits 0 for findings; Fleek exits 2 by its declared CLI contract. Combined reference Flay plus Reek commands both exit 0; combined Fleek reports the identical Flay group, complete 1/1 coverage for both checks, and exits 2 for findings. On the identical pinned 25-file Rails `app/` input, Reek 6.6.0 reports 0 warnings; Fleek Reek reports 25/25 analyzed, complete, no findings, and exit 0. The Flay exit difference is intentional and documented in ADRs 0002 and 0018.

## Summary

Variant | n | median ms | p95 ms | min ms | max ms
---|---:|---:|---:|---:|---:
flay-reference | 20 | 166.515 | 171.175 | 158.132 | 172.282
flay-fleek | 20 | 3.512 | 3.824 | 3.417 | 3.843
reek-rails-reference | 20 | 356.578 | 377.459 | 339.61 | 484.765
reek-rails-fleek | 20 | 6.092 | 6.546 | 5.94 | 6.603
combined-reference | 20 | 481.653 | 510.622 | 469.272 | 523.015
combined-fleek | 20 | 3.572 | 3.975 | 2.955 | 4.476

Target: Fleek p95 must be no slower than the corresponding pinned reference p95 for the same complete work. This ties target to observed upstream CLI cost and keeps combined work comparable.

- Flay fixture: target <= 171.175 ms p95; observed 3.824 ms; met.
- Reek ClassVariable Rails corpus: target <= 377.459 ms p95; observed 6.546 ms; met.
- Combined fixture: target <= 510.622 ms p95; observed 3.975 ms; met.

## Raw observations

order | repetition | variant | ms
---:|---:|---|---:
1 | 1 | flay-reference | 167.528
2 | 1 | flay-fleek | 3.473
3 | 1 | reek-rails-reference | 484.765
4 | 1 | reek-rails-fleek | 6.28
5 | 1 | combined-reference | 481.653
6 | 1 | combined-fleek | 3.724
7 | 2 | combined-fleek | 3.07
8 | 2 | combined-reference | 493.854
9 | 2 | reek-rails-fleek | 6.164
10 | 2 | reek-rails-reference | 377.459
11 | 2 | flay-fleek | 3.493
12 | 2 | flay-reference | 166.467
13 | 3 | flay-reference | 165.088
14 | 3 | flay-fleek | 3.638
15 | 3 | reek-rails-reference | 367.735
16 | 3 | reek-rails-fleek | 6.005
17 | 3 | combined-reference | 471.188
18 | 3 | combined-fleek | 3.691
19 | 4 | combined-fleek | 3.036
20 | 4 | combined-reference | 478.67
21 | 4 | reek-rails-fleek | 5.991
22 | 4 | reek-rails-reference | 353.283
23 | 4 | flay-fleek | 3.616
24 | 4 | flay-reference | 158.132
25 | 5 | flay-reference | 164.595
26 | 5 | flay-fleek | 3.443
27 | 5 | reek-rails-reference | 360.417
28 | 5 | reek-rails-fleek | 6.233
29 | 5 | combined-reference | 469.394
30 | 5 | combined-fleek | 3.673
31 | 6 | combined-fleek | 2.955
32 | 6 | combined-reference | 500.537
33 | 6 | reek-rails-fleek | 6.419
34 | 6 | reek-rails-reference | 376.619
35 | 6 | flay-fleek | 3.539
36 | 6 | flay-reference | 165.611
37 | 7 | flay-reference | 168.557
38 | 7 | flay-fleek | 3.569
39 | 7 | reek-rails-reference | 369.41
40 | 7 | reek-rails-fleek | 6.185
41 | 7 | combined-reference | 469.272
42 | 7 | combined-fleek | 3.911
43 | 8 | combined-fleek | 3.183
44 | 8 | combined-reference | 492.002
45 | 8 | reek-rails-fleek | 6.138
46 | 8 | reek-rails-reference | 345.533
47 | 8 | flay-fleek | 3.589
48 | 8 | flay-reference | 168.322
49 | 9 | flay-reference | 159.272
50 | 9 | flay-fleek | 3.475
51 | 9 | reek-rails-reference | 364.174
52 | 9 | reek-rails-fleek | 6.192
53 | 9 | combined-reference | 478.449
54 | 9 | combined-fleek | 3.813
55 | 10 | combined-fleek | 2.965
56 | 10 | combined-reference | 523.015
57 | 10 | reek-rails-fleek | 6.603
58 | 10 | reek-rails-reference | 363.182
59 | 10 | flay-fleek | 3.482
60 | 10 | flay-reference | 165.32
61 | 11 | flay-reference | 168.813
62 | 11 | flay-fleek | 3.513
63 | 11 | reek-rails-reference | 356.578
64 | 11 | reek-rails-fleek | 5.94
65 | 11 | combined-reference | 485.473
66 | 11 | combined-fleek | 3.734
67 | 12 | combined-fleek | 3.209
68 | 12 | combined-reference | 486.309
69 | 12 | reek-rails-fleek | 5.976
70 | 12 | reek-rails-reference | 349.406
71 | 12 | flay-fleek | 3.548
72 | 12 | flay-reference | 160.985
73 | 13 | flay-reference | 168.612
74 | 13 | flay-fleek | 3.843
75 | 13 | reek-rails-reference | 361.275
76 | 13 | reek-rails-fleek | 6.076
77 | 13 | combined-reference | 478.781
78 | 13 | combined-fleek | 4.476
79 | 14 | combined-fleek | 3.572
80 | 14 | combined-reference | 509.52
81 | 14 | reek-rails-fleek | 6.467
82 | 14 | reek-rails-reference | 355.631
83 | 14 | flay-fleek | 3.73
84 | 14 | flay-reference | 168.322
85 | 15 | flay-reference | 170.277
86 | 15 | flay-fleek | 3.455
87 | 15 | reek-rails-reference | 357.462
88 | 15 | reek-rails-fleek | 5.998
89 | 15 | combined-reference | 471.665
90 | 15 | combined-fleek | 3.822
91 | 16 | combined-fleek | 3.201
92 | 16 | combined-reference | 483.698
93 | 16 | reek-rails-fleek | 6.092
94 | 16 | reek-rails-reference | 343.075
95 | 16 | flay-fleek | 3.417
96 | 16 | flay-reference | 160.717
97 | 17 | flay-reference | 171.175
98 | 17 | flay-fleek | 3.824
99 | 17 | reek-rails-reference | 347.969
100 | 17 | reek-rails-fleek | 6.026
101 | 17 | combined-reference | 476.123
102 | 17 | combined-fleek | 3.866
103 | 18 | combined-fleek | 3.166
104 | 18 | combined-reference | 510.622
105 | 18 | reek-rails-fleek | 6.077
106 | 18 | reek-rails-reference | 354.629
107 | 18 | flay-fleek | 3.47
108 | 18 | flay-reference | 167.964
109 | 19 | flay-reference | 172.282
110 | 19 | flay-fleek | 3.454
111 | 19 | reek-rails-reference | 345.789
112 | 19 | reek-rails-fleek | 6.041
113 | 19 | combined-reference | 473.424
114 | 19 | combined-fleek | 3.975
115 | 20 | combined-fleek | 3.105
116 | 20 | combined-reference | 482.966
117 | 20 | reek-rails-fleek | 6.546
118 | 20 | reek-rails-reference | 339.61
119 | 20 | flay-fleek | 3.512
120 | 20 | flay-reference | 166.515
