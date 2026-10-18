## Agent skills

### Issue tracker

Issues live as Markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Use `needs-triage`, `needs-info`, `ready-for-agent`, and `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Use single-context docs: root `CONTEXT.md` and `docs/adr/`. See `docs/agents/domain.md`.

## Engineering harness

1. Build Spinel from release `2026.09.12`, commit `00ce35bb96e489620358ffbc48791001a73778a5`; report its version and follow [`spinel.md`](docs/agents/spinel.md).
2. When a check, build, scan, or code path is slow or regresses, follow [the performance-bugs skill](.agents/skills/performance-bugs/SKILL.md), track confirmed bottlenecks as local bug tickets, and remove the measured bottleneck before continuing feature work.
3. Implement one tiny end-to-end slice at a time. Write a failing test first, then implement and use mutation checks to prove it detects behavioral faults. Write every one-off project helper, including temporary determinism scripts, as a Spinel Ruby `.rb` program run with the pinned compiler; use shell only to invoke existing commands, and put no helper logic in shell or Python. Follow [`ruby-maintainability.md`](docs/agents/ruby-maintainability.md).
4. Before committing, run the full Spinel native build and test suite, Flay, Reek, and mutation checks. Require passing build/tests, zero Flay/Reek findings, and no surviving non-equivalent mutants; explain exclusions. Record project commands when established.
5. Keep each commit one coherent, human-readable slice. Commit passing slices sequentially on `main` and push each directly to `origin/main`, leaving `main` passing after every push.
