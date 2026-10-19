# Issue tracker: Local Markdown

Specs and issues live under `.scratch/`, one feature per directory.

| Artifact | Path and convention |
| --- | --- |
| Spec | `.scratch/<feature>/spec.md` |
| Issue | `.scratch/<feature>/issues/<NN>-<slug>.md`, one ticket per file; number in filename must match heading |
| State | `Status: open`, `claimed`, or `resolved`; `Type`, `Category`, and `Triage` use the values in this file and [triage labels](triage-labels.md). |
| Discussion | Append comments under `## Comments`. |

When asked to publish, create the spec or issue at its path. When asked to fetch a ticket, read the supplied file path or issue number.

## Wayfinding files

- Map: `.scratch/<effort>/map.md`, containing Notes / Decisions-so-far / Fog.
- Child: `.scratch/<effort>/issues/NN-<slug>.md`; use the required fields below and optional `Blocked by:` references.
- Frontier: first numbered open, unblocked, unclaimed issue.
- Claim: set `Status: claimed` and save before work.
- Resolve: add `## Answer`, set `Status: resolved`, then add a context pointer to map's Decisions-so-far.

## Required ticket fields

Use a numbered `# NN: Title` heading, one `What to build` or `What to fix` summary, `Status`, `Type`, `Category`, and `Triage`. Open and claimed tickets also need at least one acceptance checkbox. Omit `Blocked by` when no dependency exists; otherwise each reference must resolve inside the same feature, except explicit `Default-check issue NN` references, which resolve in `fleek-default-checks`.

```markdown
# NN: <Ticket title>

**What to build:** <end-to-end behavior>

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [ ] <Acceptance criterion>
```

Run `make ticket-check` to validate filenames, headings, fields, triage values, blocker references, and dependency cycles.
