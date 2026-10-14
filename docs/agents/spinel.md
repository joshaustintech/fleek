# Spinel version and Ruby practices

## Pinned compiler

- Release: `2026.09.12`
- Repository: <https://github.com/matz/spinel>
- Annotated tag object: `00ce35bb96e489620358ffbc48791001a73778a5`
- Peeled release source commit: `112bae85c1a25fc5399009a849f805bfe691426b`
- Build Spinel from that tag and verify `spinel --version` identifies the pinned release and commit before using it. Do not build from `master` or follow an unpinned installer.
- GitHub marks this ref as an annotated tag object, not a commit. Resolve and verify both the expected object and peeled commit before building.
- Change this pin only as a planned, reviewed harness update. Recheck the new release's `docs/limitations.md`, then compile and run every existing end-to-end test before changing the version here.

The 2026.09.12 Git tag has no tracked `vendor/` tree; its Makefile can fetch Prism 1.9.0 with `make deps`. Record the exact Prism source and build identity so this fetch does not silently change the parser.

## Verified Apple Silicon build

- Host: macOS arm64, Apple clang 21.0.0 (`clang-2100.3.34.2`).
- Compiler output: `spinel 112bae85c1a2 (2026.09.12) [Apple clang version 21.0.0 (clang-2100.3.34.2)]`.
- Parser: Prism 1.9.0, fetched from its RubyGems artifact; SHA-256 `7b530c6a9f92c24300014919c9dcbc055bf4cdf51ec30aed099b06cd6674ef85`.
- `make test` checks the vendored Prism version header and locked gem checksum. It does not hash the expanded vendor tree against the gem archive.
- A Fleek executable compiled by that compiler had SHA-256 `d8dea81e63c1e336620792a753c60439ea207fd73df355ec1686d9e4e9a2a519`.
- The fetched RBS 4.0.1 dependency supplies signature data and extraction support; it is not Fleek's analyzed-source parser.
- In `/private/tmp`, the inherited `ruby` resolves to macOS System Ruby 2.6. Upstream `tools/spin.rb` launches `ruby` for its CRuby parity check, so use `/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin` first in `PATH` when running Spinel's full `make check` there.
- The pack e2e generates a Makefile requiring newer syntax than Apple's GNU Make 3.81. GNU Make 4.4.1 was installed with Homebrew and placed first in `PATH` for `tools/spin_e2e.sh`; the upstream helper remained unchanged.

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
