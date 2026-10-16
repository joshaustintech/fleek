# ADR 0041: Carry default check coverage as an analysis profile

Default invocation selects 29 pinned checks while only Flay structural duplication and Reek ClassVariable currently run. Carry the selected, runnable, disabled, and unsupported sets through the existing combined runner as one profile; this keeps explicit `--checks` behavior stable and makes unsupported coverage force an incomplete result even when supported checks are clean. Do not infer default coverage from findings or silently treat unimplemented checks as passing.
