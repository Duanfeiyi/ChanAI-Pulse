# GitHub Workflow

## Safe day-to-day flow

```text
main (stable legacy baseline) or develop/v2.0 (v2 integration)
  -> focused working branch
  -> local tests and manual GUI review when applicable
  -> push branch
  -> pull request
  -> owner manual review and manual merge
```

Use the repository URL shown on GitHub when cloning. Do not use placeholder organization URLs or old draft repositories.

```bash
git clone https://github.com/Duanfeiyi/ChanAI-Pulse.git
cd ChanAI-Pulse
git switch develop/v2.0
git pull --ff-only
git switch -c feature/v2-descriptive-name
```

For legacy documentation or maintenance that targets `main`, branch from current `main` instead. Confirm the PR base branch before opening the PR.

## Commit and review rules

- Keep commits small and descriptive, for example `docs: synchronize prediction workflow`.
- Never force-push shared branches or rewrite published history without explicit owner direction.
- Never merge your own PR automatically. The owner reviews and merges through GitHub manually.
- Resolve conflicts deliberately; do not accept all conflict changes blindly.

## Safety checks

```bash
git status
git diff --check
```

Run the relevant MATLAB tests and record manual GUI validation where required. See [Contributing](CONTRIBUTING.md) and [Testing](TESTING.md).
