# Resolve the Spinel release tag before building

The repository harness names `00ce35bb96e489620358ffbc48791001a73778a5` as a commit. GitHub identifies it as the annotated `2026.09.12` tag object; it peels to source commit `112bae85c1a25fc5399009a849f805bfe691426b`. Build only after verifying both identities. This resolves the naming ambiguity without changing the requested release.

The tag contains no tracked vendor tree; its Makefile can fetch Prism 1.9.0. Record the parser dependency and executable identity in the build receipt. `git verify-tag` reports no signature, so the tag has no cryptographic signature evidence. See the pinned release source and make rules for provenance; do not describe this as a signed release.
