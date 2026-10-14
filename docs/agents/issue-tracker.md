# Issue tracker: Local Markdown

Specs and issues live under `.scratch/`, one feature per directory.

| Artifact | Path and convention |
| --- | --- |
| Spec | `.scratch/<feature>/spec.md` |
| Issue | `.scratch/<feature>/issues/<NN>-<slug>.md`, numbered from `01`, one ticket per file |
| State | `Status: open`, `claimed`, or `resolved`; see [triage labels](triage-labels.md) for roles. |
| Discussion | Append comments under `## Comments`. |

When asked to publish, create the spec or issue at its path. When asked to fetch a ticket, read the supplied file path or issue number.

## Wayfinding files

- Map: `.scratch/<effort>/map.md`, containing Notes / Decisions-so-far / Fog.
- Child: `.scratch/<effort>/issues/NN-<slug>.md`; include `Type:` (`research`, `prototype`, `grilling`, `task`), `Status:`, and optional `Blocked by: NN, NN`.
- Frontier: first numbered open, unblocked, unclaimed issue.
- Claim: set `Status: claimed` and save before work.
- Resolve: add `## Answer`, set `Status: resolved`, then add a context pointer to map's Decisions-so-far.
