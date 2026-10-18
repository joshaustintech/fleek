# ADR 0109: Match Flay liberal pruning

Flay 2.14.4 `--liberal` can retain a method group whose members overlap with a duplicated class group; conservative pruning removes that group. Fleek accepts `--liberal` as a Flay-only idempotent control and keeps each matched method candidate in the liberal report, while preserving conservative pruning by default. For a class containing direct methods beside multiple sibling classes, Fleek collects supported direct methods alongside nested class candidates so the reference can form the three-copy `:defn` group; unsupported method shapes still produce incomplete coverage.

The public CLI contract compares both modes against unchanged Flay on `duplication_class_direct_and_sibling_methods.rb`: conservative score 50, liberal score 266 with `:defn` mass 72/score 216 and `:class` mass/score 50. Focused mutations cover candidate discovery, liberal pruning, option recognition, combined routing, and Reek-only rejection.
