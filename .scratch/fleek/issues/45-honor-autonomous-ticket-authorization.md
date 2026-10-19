# 45: Honor prior authorization in ticket breakdowns

**What to build:** Ticket breakdowns proceed without repeated approval when the user has already authorized autonomous work, while unapproved proposals remain reviewable before publication.

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Update the ticket-breakdown workflow to recognize explicit current or standing authorization to create and publish tickets.
- [x] When authorization exists, publish the proposed local tickets without asking the user to repeat approval; otherwise present the draft and wait for approval.
- [x] Preserve the requirement to keep parent issues unchanged.
- [x] Verify the workflow instructions are concise, unambiguous, and consistent with local and external tracker publishing steps.

The workflow now publishes when explicit authorization covers the set and tracker, while draft-only requests still wait for review. Local ticket metadata matches the canonical tracker contract. ADR 0165 records the policy.
