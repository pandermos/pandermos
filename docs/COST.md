# Cost and usage

## Subscription or API key

- **Claude Pro / Max subscription**: run `claude setup-token` once, put the token in `secrets.env` as `CLAUDE_CODE_OAUTH_TOKEN`. Runs count against the same usage limits as your interactive Claude Code sessions. When a limit is hit, Pandermos backs off for `LIMIT_BACKOFF` seconds (default 1 hour) instead of failing every task.
- **API key**: `ANTHROPIC_API_KEY`. You pay per token; the `API-USD` column of `pandermos usage` is then your real bill.

## Reading `pandermos usage`

Example output:

```text
$ pandermos usage 1
TASK                    RUNS  MINUTES   OUT-TOKENS    API-USD
wordpress-news            22      198       310412      41.80
website-health             6       61        64220       9.10
server-health             11       52        30987       5.20
improve                    2      140       180330      38.40
total                     41      451                   94.50
```

`API-USD` is what the same tokens would have cost on the API. On a subscription it is not a bill, but it is the best single number for "how much of my quota does this task eat".

## What we saw in production

On one server with a dozen sites, a news site publishing dozens of articles a day and a SaaS app:

- A routine check (server or site health) costs roughly 1.5–4 USD API-equivalent per run with Sonnet.
- The news review is the biggest consumer because it opens images and sources for every article.
- A one-off "go through 300 old articles and fix the images" job cost about 57 USD API-equivalent in a single run. Put open-ended jobs behind `manual` and give them a tight timeout.
- Opus twice a day for code work is fine on Max; Opus for every routine check is not.

## Tuning

- **Model per task**: `sonnet` for checks, `opus` for code changes and hard investigations, `haiku` for trivial checks.
- **Frequency**: `every 4` instead of `every 1` cuts a task's usage by four. Security reviews rarely need more than `at 03:30`.
- **Batch limits in the task**: "at most 25 articles per run, leave the rest for the next one" keeps run size predictable.
- **Timeouts**: the timeout is a cost ceiling. A task that regularly hits it is doing too much per run.
- **Short tasks write short reports**: ask for numbers and changes, not essays.
- **notes.md**: every accepted situation you write there is something the agent stops re-investigating.
