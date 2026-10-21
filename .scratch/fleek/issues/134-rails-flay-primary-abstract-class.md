# 134: Analyze Rails primary_abstract_class declarations for Flay

**What to build:** Flay structural duplication analysis accepts Rails' direct `primary_abstract_class` declaration in a simple class.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Treat only a receiver-free `primary_abstract_class` call with no block and no arguments as a non-candidate class declaration. Compare the public CLI result against Flay 2.14.4. Calls with a receiver, arguments, a block, or any other class-body method remain incomplete. Do not broaden to arbitrary Rails macros.

## Starting evidence

Pinned Rails `app/models/application_record.rb` contains `class ApplicationRecord < ActiveRecord::Base` with a direct `primary_abstract_class` call and no methods. Flay reports score zero; Fleek currently marks the file partial.

## Acceptance criteria

- [ ] A minimal public CLI fixture fails before implementation and matches Flay 2.14.4 afterward.
- [ ] The pinned `ApplicationRecord` analyzes completely with unchanged clean Flay output.
- [ ] Other class-body calls and unsupported call forms remain incomplete, protected by focused mutations.
- [ ] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record exact results in `## Answer`.
- [ ] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 133. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Reuse the existing class-body declaration path. Never treat arbitrary class-body calls as harmless.
