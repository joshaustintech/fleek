# Domain docs

Read relevant domain terms and decisions before exploring. Missing docs are normal; proceed without flagging their absence. Create them when `/domain-modeling` resolves a real term or decision.

| Repo layout | Read |
| --- | --- |
| Single context | Root `CONTEXT.md` and relevant `docs/adr/` decisions. |
| Multiple contexts (`CONTEXT-MAP.md` exists) | Map, relevant context `CONTEXT.md`, system ADRs in `docs/adr/`, and that context's `docs/adr/`. |

Use glossary terms in issues, hypotheses, and tests. If a needed term is missing, note the gap for `/domain-modeling`. If work conflicts with an ADR, identify it and explain why it may need reopening instead of silently overriding it.
