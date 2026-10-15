# Fleek cold CLI runtime evidence

## Identity

- Host: Darwin arm64; macOS 27.0.1 (26A434).
- Source revision: 8c083dc4875a70ecb213f652e62c4e4b7597e787.
- Fleek executable SHA-256 (before and after): e920ca3ed8da115adde10bf5adc865d994ea5235ac37dd4b1ce14df3f3fadcff.
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
flay-reference | 20 | 170.672 | 178.776 | 157.662 | 181.855
flay-fleek | 20 | 3.584 | 3.897 | 3.323 | 3.986
reek-rails-reference | 20 | 360.236 | 376.211 | 339.934 | 380.032
reek-rails-fleek | 20 | 6.055 | 6.606 | 5.778 | 7.124
combined-reference | 20 | 489.727 | 693.7 | 467.998 | 704.781
combined-fleek | 20 | 3.75 | 4.323 | 2.941 | 4.357

Target: Fleek p95 must be no slower than the corresponding pinned reference p95 for the same complete work. This ties target to observed upstream CLI cost and keeps combined work comparable.

- Flay fixture: target <= 178.776 ms p95; observed 3.897 ms; met.
- Reek ClassVariable Rails corpus: target <= 376.211 ms p95; observed 6.606 ms; met.
- Combined fixture: target <= 693.7 ms p95; observed 4.323 ms; met.

## Raw observations

order | repetition | variant | ms
---:|---:|---|---:
1 | 1 | flay-reference | 168.55
2 | 1 | flay-fleek | 3.427
3 | 1 | reek-rails-reference | 344.953
4 | 1 | reek-rails-fleek | 5.935
5 | 1 | combined-reference | 500.678
6 | 1 | combined-fleek | 3.918
7 | 2 | combined-fleek | 3.432
8 | 2 | combined-reference | 503.961
9 | 2 | reek-rails-fleek | 6.606
10 | 2 | reek-rails-reference | 366.032
11 | 2 | flay-fleek | 3.762
12 | 2 | flay-reference | 175.042
13 | 3 | flay-reference | 174.43
14 | 3 | flay-fleek | 3.897
15 | 3 | reek-rails-reference | 364.994
16 | 3 | reek-rails-fleek | 6.275
17 | 3 | combined-reference | 520.005
18 | 3 | combined-fleek | 4.065
19 | 4 | combined-fleek | 3.798
20 | 4 | combined-reference | 489.727
21 | 4 | reek-rails-fleek | 6.51
22 | 4 | reek-rails-reference | 368.448
23 | 4 | flay-fleek | 3.529
24 | 4 | flay-reference | 165.46
25 | 5 | flay-reference | 162.571
26 | 5 | flay-fleek | 3.559
27 | 5 | reek-rails-reference | 351.14
28 | 5 | reek-rails-fleek | 5.935
29 | 5 | combined-reference | 693.7
30 | 5 | combined-fleek | 3.811
31 | 6 | combined-fleek | 2.944
32 | 6 | combined-reference | 704.781
33 | 6 | reek-rails-fleek | 6.006
34 | 6 | reek-rails-reference | 342.489
35 | 6 | flay-fleek | 3.613
36 | 6 | flay-reference | 157.662
37 | 7 | flay-reference | 172.156
38 | 7 | flay-fleek | 3.986
39 | 7 | reek-rails-reference | 376.088
40 | 7 | reek-rails-fleek | 5.997
41 | 7 | combined-reference | 497.526
42 | 7 | combined-fleek | 4.357
43 | 8 | combined-fleek | 3.196
44 | 8 | combined-reference | 490.925
45 | 8 | reek-rails-fleek | 5.942
46 | 8 | reek-rails-reference | 347.221
47 | 8 | flay-fleek | 3.323
48 | 8 | flay-reference | 162.917
49 | 9 | flay-reference | 160.165
50 | 9 | flay-fleek | 3.62
51 | 9 | reek-rails-reference | 365.846
52 | 9 | reek-rails-fleek | 6.495
53 | 9 | combined-reference | 467.998
54 | 9 | combined-fleek | 3.667
55 | 10 | combined-fleek | 2.941
56 | 10 | combined-reference | 486.535
57 | 10 | reek-rails-fleek | 5.778
58 | 10 | reek-rails-reference | 353.708
59 | 10 | flay-fleek | 3.545
60 | 10 | flay-reference | 167.372
61 | 11 | flay-reference | 172.766
62 | 11 | flay-fleek | 3.78
63 | 11 | reek-rails-reference | 380.032
64 | 11 | reek-rails-fleek | 7.124
65 | 11 | combined-reference | 480.36
66 | 11 | combined-fleek | 3.661
67 | 12 | combined-fleek | 2.947
68 | 12 | combined-reference | 484.47
69 | 12 | reek-rails-fleek | 5.912
70 | 12 | reek-rails-reference | 339.934
71 | 12 | flay-fleek | 3.476
72 | 12 | flay-reference | 161.203
73 | 13 | flay-reference | 178.776
74 | 13 | flay-fleek | 3.781
75 | 13 | reek-rails-reference | 376.211
76 | 13 | reek-rails-fleek | 6.204
77 | 13 | combined-reference | 492.014
78 | 13 | combined-fleek | 3.904
79 | 14 | combined-fleek | 3.75
80 | 14 | combined-reference | 498.312
81 | 14 | reek-rails-fleek | 6.537
82 | 14 | reek-rails-reference | 358.579
83 | 14 | flay-fleek | 3.595
84 | 14 | flay-reference | 176.012
85 | 15 | flay-reference | 174.857
86 | 15 | flay-fleek | 3.51
87 | 15 | reek-rails-reference | 369.739
88 | 15 | reek-rails-fleek | 6.027
89 | 15 | combined-reference | 482.074
90 | 15 | combined-fleek | 4.204
91 | 16 | combined-fleek | 4.323
92 | 16 | combined-reference | 481.865
93 | 16 | reek-rails-fleek | 6.055
94 | 16 | reek-rails-reference | 352.794
95 | 16 | flay-fleek | 3.484
96 | 16 | flay-reference | 170.672
97 | 17 | flay-reference | 172.187
98 | 17 | flay-fleek | 3.604
99 | 17 | reek-rails-reference | 348.747
100 | 17 | reek-rails-fleek | 6.3
101 | 17 | combined-reference | 473.61
102 | 17 | combined-fleek | 4.052
103 | 18 | combined-fleek | 3.478
104 | 18 | combined-reference | 476.526
105 | 18 | reek-rails-fleek | 6.265
106 | 18 | reek-rails-reference | 362.707
107 | 18 | flay-fleek | 3.584
108 | 18 | flay-reference | 181.855
109 | 19 | flay-reference | 173.88
110 | 19 | flay-fleek | 3.636
111 | 19 | reek-rails-reference | 366.084
112 | 19 | reek-rails-fleek | 6.173
113 | 19 | combined-reference | 507.047
114 | 19 | combined-fleek | 3.897
115 | 20 | combined-fleek | 3.376
116 | 20 | combined-reference | 482.712
117 | 20 | reek-rails-fleek | 5.982
118 | 20 | reek-rails-reference | 360.236
119 | 20 | flay-fleek | 3.359
120 | 20 | flay-reference | 168.626
