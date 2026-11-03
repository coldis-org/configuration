# Bug candidates

Observed on 2026-11-03 while configuring the code review for this repository (AGENTS.md and
`src/agents/review/review.toml`). These are **candidates**: noticed while reading, not verified,
not triaged. Credentials are named by location only. Remove an entry once it is confirmed and
tracked elsewhere, or found not to be a bug.

- `config/test` is a `git filter-branch` history-rewrite script and looks stale.
- The pom `<scm><tag>` is `configuration-2.0.143` while the version is 2.0.156-SNAPSHOT.
