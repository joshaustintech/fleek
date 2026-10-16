# ADR 0042: Resolve Reek defaults through effective configuration

## Status

Accepted.

## Context

Default invocation needs to distinguish Reek detectors disabled by configuration from enabled detectors Fleek cannot run. Reek 6.6.0 also has an opt-in `UnusedPrivateMethod` detector and directory directives whose most specific match overrides broader settings. Excluded paths must not make unsupported enabled coverage disappear.

## Decision

Build the default analysis profile from Reek's detector enablement settings for discovered source paths. Global settings apply unless a matching directory directive overrides them; the most specific matching directive wins. A detector appears in disabled coverage only when it is disabled for every discovered source. Configured opt-in detectors join the selected set. Exclusions do not remove enabled unsupported detectors from the coverage list. The supported ClassVariable runner is skipped when configuration disables it.

Only detector enablement is accepted for detectors Fleek does not implement. Their other settings remain rejected until their analysis is supported, so Fleek never suggests it honored policy it cannot apply.

## Evidence

The compiled CLI contract checks configured disabled and opt-in detectors, directory precedence, and path exclusions. A process contract compares opt-in enabled/disabled behavior with Reek 6.6.0 on real Ruby files. The profile retains unsupported configured detectors and forces incomplete status.
