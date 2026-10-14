# ADR 0011: File and directory scan contract

## Status

Accepted for ticket 05.

## Reference behavior

Reek 6.6.0 recursively scans visible directory entries in sorted order, skips hidden directories, and does not recurse into directory symlinks. It includes `.rb` file symlinks and reports their supplied path. Repeated explicit paths are analyzed repeatedly. Non-Ruby files are ignored by directory discovery but explicit non-Ruby arguments are errors.

## Decision

Match those file-selection and repeated-path rules. An explicit directory symlink is an error instead of Reek's silent empty success, because empty discovery must never masquerade as complete clean analysis. If any requested path fails, analyze all other discovered sources, retain their findings, report failed paths, mark coverage incomplete, and exit 1. A request yielding no Ruby sources is also an error.

## Consequences

Users can distinguish clean complete scans from empty, invalid, or partially analyzed inputs. Discovery tests compare findings and exit status with Reek where behavior is shared. Mutations cover path selection, duplicate handling, and incomplete/empty status.
