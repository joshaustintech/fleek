# ADR 0173: Reap any completed check worker

## Status

Accepted

## Context

The check runner waited for `@workers.first` whenever it reached its concurrency cap. If that worker was slow while a later worker had already finished, the runner left a slot unused until the first worker completed. Check tasks are independent; each worker already has its own task, output files, source copy, and temporary root.

## Decision

Wait for any child process with `Process.waitpid2(-1)`, find the worker record by returned PID, then report and clean up that record. Preserve the task list, worker cap, mutation shard assignment, and precompile batching.

## Evidence

The new gated-child contract starts a slow first task and fast second task, and requires a third task to start before the first is released. A second run makes the fast task fail and verifies its status remains attached to that task, the other tasks finish, the slow worker's source remains available until exit, and each worker's source and temp roots are cleaned after completion.

Before the change, the contract failed with `third task started after slow task release` after its 10-second guard released the slow child. After the change, both success and out-of-order failure cases pass in 8.47 seconds. The full `make check JOBS=4` passed 57 workers in 389.48 seconds, including all 48 mutation contracts and zero Flay/Reek findings.

## Consequences

Worker output is reported in completion order. Task identity remains stable because each child PID maps to its own worker record. The runner still waits for every started child before reporting accumulated failures.
