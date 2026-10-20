# ADR 0187: Preserve composed collection and control-flow parity

## Status

Accepted

## Context

Ticket 49 asks whether arrays or hashes nested in case branches and loops retain Flay's wrappers and child topology. Existing descriptors already represent the required collection and control-flow nodes. Pinned CLI comparisons of bounded case and loop examples matched Flay 2.14.4 before any implementation change.

## Decision

Keep the existing native descriptor and mass rules. Add public differential contracts for a case with multiple `when` conditions and a collection call, a loop containing array and hash calls, an identical composed pair, and a pair with different child topology that Flay leaves clean. Do not refactor matching code when these bounded compositions already pass.

## Evidence

With Spinel 2026.09.12 and Flay 2.14.4, the case fixture matches a similar `:defn` group at mass and score 38, and the loop fixture matches at 30. An identical conditional collection pair matches at mass 26 and score 52. Flay and Fleek both leave the different-topology fixture clean at mass threshold 3. The public contract compares classifications, locations, mass, score, coverage, normalized statuses, and empty stderr.

## Consequences

The existing descriptor implementation is sufficient for these bounded compositions. This ticket adds reproducible regression evidence without changing analyzer behavior; broader translator closure remains tracked by Tickets 50–52 and parent Tickets 22/43.
