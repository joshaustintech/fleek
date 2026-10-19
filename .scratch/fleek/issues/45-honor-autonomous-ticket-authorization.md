# 45: Honor prior authorization in ticket breakdowns

**What to build:** Ticket breakdowns proceed without repeated approval when the user has already authorized autonomous work, while unapproved proposals remain reviewable before publication.

**Blocked by:** None (can start immediately).

**Status:** open  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Update the ticket-breakdown workflow to recognize explicit current or standing authorization to create and publish tickets.
- [ ] When authorization exists, publish the proposed local tickets without asking the user to repeat approval; otherwise present the draft and wait for approval.
- [ ] Preserve the requirement to keep parent issues unchanged.
- [ ] Verify the workflow instructions are concise, unambiguous, and consistent with local and external tracker publishing steps.
