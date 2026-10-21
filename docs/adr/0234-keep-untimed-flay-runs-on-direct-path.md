# Keep untimed Flay runs on the direct path

Accepted for Ticket 120 and issue 129.

Fleek applies timeout supervision only when the user supplies a positive `--timeout`. An omitted timeout and `--timeout 0` keep the existing in-process analysis path. Flay 2.14.4 defaults to ten seconds per file; Fleek does not apply that implicit default because safely interrupting the synchronous native Prism parser requires an isolated worker and timer, adding process startup cost to every normal Flay invocation.

A seven-run median probe on the same small public Flay input measured the untimed invocation at 8.052 ms before this change and 3.701 ms after; the explicit zero-timeout path measured 3.689 ms before and 3.486 ms after. Positive explicit timeouts still use worker isolation. The tradeoff is that Fleek does not impose Flay's implicit ten-second timeout when `--timeout` is omitted. This choice keeps the safe cancellation boundary available without charging its measured overhead to all ordinary scans.

The final timed `/usr/bin/time -p env ... make check JOBS=4` passed 73 workers and four mutation workers in 784.83 seconds. Ticket 115's cache-disabled comparison was 402.49 seconds with 61 workers, so the full-gate regression remains open in issue 129. The focused direct-path probe shows untimed Flay runs no longer start a worker or timer; full-suite compile cost and the additional worker count remain separate measured work.
