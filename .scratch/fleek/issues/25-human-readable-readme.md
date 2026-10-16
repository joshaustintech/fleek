# 25: Rewrite the README for human readers

**What to build:** Rewrite the root README as clear, human-readable documentation for people who want to understand, install, and use Fleek. Follow STE100 English and Strunk & White. Explain Fleek-specific behavior and limits. Link to existing Flay and Reek documentation for their general analyzer concepts. Add 💅 next to the README title.

**Blocked by:** Every other unfinished ticket in this repository, including any tickets added later. This ticket must be completed last, after all other unfinished tickets are resolved, because upcoming changes will significantly alter the app.

**Status:** open  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

## Plan

- Recheck the shipped app, command-line options, release and installation steps, and documented support boundaries after all other tickets are complete.
- Explain what Fleek does, who it is for, how its Flay and Reek checks work, what it does not analyze, and how to read findings, coverage, diagnostics, and exit codes.
- Keep Fleek-specific behavior and limits in the README. Link to the upstream Flay and Reek documentation for general tool details, and link to relevant project docs for deeper Fleek details.
- Give short, copyable installation and first-run instructions that match the current release. Include checksum verification where available and state runtime requirements plainly.
- Organize the README for quick scanning, with a 💅 emoji beside the title.
- Edit for STE100 English and Strunk & White: use short sentences, common words, active voice, and direct instructions. Remove repetition and unsupported claims.
- Check every command, link, version, requirement, and behavior against the final app and its existing documentation.

## Acceptance criteria

- [ ] README serves human users; agent-only workflow instructions remain in `AGENTS.md` and linked agent docs.
- [ ] README title includes 💅 next to the title text.
- [ ] README explains all behavior and limits unique to Fleek, including supported checks, coverage, findings, diagnostics, and exit status.
- [ ] README links to existing Flay and Reek documentation where it discusses their general behavior.
- [ ] A new user can follow concise installation and first-run instructions that work for the current release.
- [ ] Prose follows STE100 and Strunk & White guidance; commands, versions, links, and claims match the shipped app.
- [ ] No other unfinished ticket remains when this ticket is completed.

## Verification

- [ ] Check README statements against CLI help, implementation, release artifacts, and current project documentation.
- [ ] Run the documented installation and first-run commands against the current release artifact.
- [ ] Check links and review all prose for STE100 and Strunk & White style.

