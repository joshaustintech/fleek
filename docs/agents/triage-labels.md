# Triage Labels

Each triaged issue has one category role and one triage-state role. `Status` (`open`, `claimed`, `resolved`) is the separate local workflow lifecycle.

| Role | Tracker string | Meaning |
| --- | --- | --- |
| `bug` category | `bug` | Something is broken |
| `enhancement` category | `enhancement` | New feature or improvement |
| `needs-triage` state | `needs-triage` | Maintainer needs to evaluate |
| `needs-info` state | `needs-info` | Waiting for reporter information |
| `ready-for-agent` state | `ready-for-agent` | Fully specified, agent can work |
| `ready-for-human` state | `ready-for-human` | Needs human judgment or work |
| `wontfix` state | `wontfix` | Will not be actioned |

Each triaged issue has exactly one category and one state role. Write the corresponding string when a skill assigns a role.
