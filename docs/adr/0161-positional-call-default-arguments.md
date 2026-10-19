# ADR 0161: Support literal arguments in positional call defaults

## Status

Accepted

## Context

Flay 2.14.4 accepts receiverless calls with one supported literal argument as optional positional defaults. Fleek previously accepted only calls without arguments, so identical source was reported incomplete. The literal argument also contributes one additional Flay mass point per method.

## Decision

Accept one integer argument on a receiverless optional positional call without a block. Compare the integer value and add one mass point for that argument. Keep optional keyword calls with arguments, calls with receivers or blocks, multiple arguments, and other argument syntax incomplete.

## Consequences

The compiled CLI matches Flay's similar group at mass/score 12 for differing integer arguments. Focused mutations protect acceptance, argument identity, and mass. This is a bounded optional-default form; other argument shapes remain unsupported.
