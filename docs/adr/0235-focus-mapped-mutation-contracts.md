# Focus mapped mutation runs on the protected behavior

Accepted for issue 129.

When several mutations map to one broad contract, pass the mutation label to that contract and run only the public assertion that protects the mutated behavior. Keep the ordinary contract entry point unchanged: it still runs every assertion. Require each label to have an explicit focused route, and keep `MutationCase`'s expected-failure check so a mutant must fail for its declared reason.

The default-argument/Reek contract contained 59 labels and took 49.49 seconds per full invocation. Those mutations were repeating unrelated detector and configuration checks. Focused routes retain reference-backed public CLI assertions for each label and the unfiltered test worker still runs the complete contract once. Full mutation accounting remains enabled.

The full pinned gate passed 77 workers with eight mutation workers in 351.44 seconds; all 335 mutation labels were caught. Ticket 115's cache-disabled comparison was 402.49 seconds with four mutation workers, and the earlier ticket 120 run took 784.83 seconds. The final run is below the recorded comparison without dropping test or mutation coverage. This builds on [ADR 0180](0180-focus-generated-descriptor-support-contract.md), which applies the same focused-contract boundary to generated-descriptor mutations.
