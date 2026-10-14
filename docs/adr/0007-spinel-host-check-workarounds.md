# Use compatible host tools for the pinned Spinel checks

Spinel 2026.09.12's full suite assumes a suitable `ruby` is on `PATH`, and its packaged-project e2e emits Makefile syntax unsupported by macOS's GNU Make 3.81. The temporary `/private/tmp` checkout otherwise selects system Ruby 2.6 and fails the CRuby parity check; the pack check fails parsing before compilation.

For the full check, put mise Ruby 3.4.9 and Homebrew GNU Make 4.4.1 first on `PATH`. Run with host network/socket access because the upstream suite opens local sockets and HTTP servers. No upstream source or expected result was changed. These host tools support verification only; Fleek's implementation remains compiled by pinned Spinel.
