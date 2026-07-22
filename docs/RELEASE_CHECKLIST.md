# Release Checklist

## Source and data safety

- [ ] `git status` contains no private data, archives, local output, model or installer artifact.
- [ ] Public demo files are synthetic and documented as demonstrations only.
- [ ] No documentation, report or screenshot contains an absolute local path, identifier, location or token.

## Validation

- [ ] Run the applicable tests from [Testing](TESTING.md) and record exact outcomes.
- [ ] Complete [GUI Manual Test Checklist](GUI_MANUAL_TEST_CHECKLIST.md) when App behavior is in scope.
- [ ] Record all tests not run and their reason.
- [ ] Confirm scientific limitations are reflected in README, release notes and the roadmap.

## Documentation and versioning

- [ ] README, changelog, roadmap and citation match the intended revision/tag.
- [ ] Documentation links resolve and future plans are not presented as implemented.
- [ ] A release tag and GitHub Release are created only after owner approval.
- [ ] Merges and release publication are performed manually by the repository owner.
