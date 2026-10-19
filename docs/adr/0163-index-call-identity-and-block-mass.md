# ADR 0163: Index call identity and block mass

Flay call identity uses the call node's method-name constant as descriptor payload. The preorder candidate tree already preserves receiver, ordered argument children, splat nodes, and block structure; child identity continues through the same descriptor comparator. This keeps call names in the shared rule table and avoids a second call-name branch.

Pinned Flay 2.14.4 assigns block mass according to the block parameter shape. A block without a parameter list receives no adjustment; a block with parameters retains the two-point reduction. The compiled CLI contract covers both parameterless and parameterized blocks because a single unconditional block adjustment changes Flay scores.

Forwarded method arguments (`...`) remain unsupported by the candidate adapter. Fleek marks the source incomplete while Flay still reports it, rather than claiming partial parity.
