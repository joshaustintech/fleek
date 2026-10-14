# Spinel version and Ruby practices

## Pinned compiler

- Release: `2026.09.12`
- Repository: <https://github.com/matz/spinel>
- Tag commit: `00ce35bb96e489620358ffbc48791001a73778a5`
- Build Spinel from that tag and verify `spinel --version` identifies the pinned release and commit before using it. Do not build from `master` or follow an unpinned installer.
- Change this pin only as a planned, reviewed harness update. Recheck the new release's `docs/limitations.md`, then compile and run every existing end-to-end test before changing the version here.

The source archive for a release includes vendored parsers, so the compiler can be built reproducibly without fetching dependencies during the build.

## Ruby practices for this version

- Prefer ordinary classes, methods, modules, explicit arguments, and blocks. Keep the program's call graph visible to whole-program inference; pass consistent types at each call site.
- Use literal method names and class structure. Do not depend on `eval`, `method_missing`, runtime-generated methods/classes, runtime changes to ancestors, or reflection that needs a runtime name-to-slot table. These features need runtime metadata Spinel does not retain.
- Avoid runtime-computed `send` names. If dispatch is needed, use explicit branches or a closed set of literal method names visible in the program.
- Treat `require` as compile-time source inclusion. Require each library used, and use only libraries/packages verified to compile under this pinned release. Do not rely on runtime gem loading or CRuby's transitive `require` behavior.
- String literals are frozen with no opt-out. Create mutable strings with `+"text"`, `String.new`, interpolation, or `dup` before mutating them.
- Integer representation and overflow behavior are selected at compile time. Default overflow raises rather than producing CRuby's arbitrary-precision `Integer`; use the documented `--int-overflow=promote` mode only when arbitrary precision is required, and test boundary values.
- Restrict text handling to UTF-8 and ASCII-8BIT. Do not assume encoding objects, transcoding, or mixed-encoding behavior available in CRuby.
- Treat compile refusals and type widening as design feedback. Fix the code to fit supported constructs or narrow the slice; do not defer refusals into runtime failures or assume successful compilation proves CRuby compatibility.

## Versioned references

- [Spinel 2026.09.12 README](https://github.com/matz/spinel/blob/2026.09.12/README.md)
- [Spinel 2026.09.12 limitations](https://github.com/matz/spinel/blob/2026.09.12/docs/limitations.md)
