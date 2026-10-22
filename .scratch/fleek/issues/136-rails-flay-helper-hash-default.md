# 136: Analyze the Rails helper hash default for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `UsersHelper#gravatar_for` optional parameter default `{ size: 80 }`.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept a nonempty hash literal with one symbol key `size` and one integer literal value as an optional positional method parameter default. Preserve existing Flay candidate mass, identity, and location behavior. Other keys, dynamic values, and unsupported hash forms remain incomplete. Do not broaden general hash-default support without separate reference-backed evidence.

## Starting evidence

Pinned Rails `app/helpers/users_helper.rb` contains `def gravatar_for(user, options = { size: 80 })`. Flay 2.14.4 reports score zero; Fleek currently marks the helper partial.

## Acceptance criteria

- [ ] A minimal public CLI fixture fails before implementation and matches Flay 2.14.4 afterward.
- [ ] The pinned `UsersHelper` analyzes completely with unchanged clean Flay output.
- [ ] Other keys and dynamic or unsupported values remain incomplete, protected by focused mutations.
- [ ] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [ ] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 135. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Keep the accepted parameter default to the exact `size: 80` hash shape.
