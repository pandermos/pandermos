Task: improve one codebase, one small change per run, delivered as a pull request.

<!-- Adjust these -->
Repository clone: /var/lib/pandermos/work/myapp (NOT the production checkout)
Base branch: main
Test command: npm test
Lint/type check: npm run lint && npx tsc --noEmit
Ideas backlog: improve-backlog.md in the state directory

## How to work
1. `git fetch && git checkout <base> && git pull`. Never work in the production directory.
2. Pick the single most valuable item: first the top of the backlog file, otherwise the most frequent error from production logs or from the latest reports of the other tasks (reports directory), otherwise a failing or flaky test.
3. Reproduce it. Write a failing test when the project has tests.
4. Make the smallest change that fixes it. Follow the code style around you. No drive-by refactors.
5. Run the test and lint commands. If anything fails that you cannot fix in this run, abandon the branch and record why in the backlog.
6. Commit on a new branch `pandermos/<short-topic>`, push, and open a pull request with `gh pr create`. The description says what was wrong, how you verified the fix, and the risk.
7. Never merge, never push to the base branch, never deploy. A human reviews the PR.

Update the backlog: remove what you did, add what you noticed (one line each).
