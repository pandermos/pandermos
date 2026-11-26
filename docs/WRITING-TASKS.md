# Writing tasks

A task file is the prompt for one kind of run. The runner appends a context block (time, report path, previous report, state and backup folders), and `CLAUDE.md` adds the standing rules, so a task only needs to describe the job.

## What a good task contains

1. **One sentence of purpose.** "Editorial audit of every new article." It sets the bar for judgement calls.
2. **Where things are.** Paths, URLs, commands, the read-only DB connection. Every fact you leave out is something the agent rediscovers on every run, at your expense.
3. **What wrong looks like**, concretely. "Disk over 85%", "a photo of a different city", "a 5xx rate above 1%".
4. **Order of checks.** Cheap and important first, so a run that times out has still done the useful part.
5. **What it may fix, and how.** The exact safe commands. Everything not listed is report-only.
6. **What it must never do** in this area, if it is not already in `CLAUDE.md`.
7. **Progress handling** for work that spans runs: a state file (`last-post-id`) and a batch limit.

## Patterns that work

- **"Look, don't infer."** For images, download and view them. For pages, fetch them. For claims, open the source. Agents will otherwise judge by file names and metadata.
- **Fix ladder.** List acceptable fixes in order of preference and end with "if none fits, leave it and report". Without the last step, an agent asked to fix something will find *some* fix, even a worse one.
- **Compare with the previous report.** Ask for "new / ongoing / resolved". It keeps notifications quiet and shows trends.
- **Numbers with deltas.** "disk / 91% (+4% since last report)" beats "disk is getting full".
- **Date every alarm.** Log lines without timestamps, cached pages and stale metrics produce false alarms. Tell the agent to raise an alarm only from evidence it can date.
- **Batch limits.** "At most 25 items per run" keeps runs predictable and cheap.

## Anti-patterns

- **"Make the site better."** Unbounded goals produce unbounded runs. Give one job.
- **Filler content.** Do not ask the agent to "add SEO text" or "fill empty sections". It will, and it will read like it.
- **Background jobs.** Never ask it to start something and check back later in the same run. The run ends, the job is orphaned, the report is missing. Split across runs with a state file instead.
- **Secrets in tasks.** Task files are plain text in the working directory. Point to a file only the `pandermos` user can read.
- **Several tasks in one file.** Separate files get separate schedules, models, locks and notifications.

## One-off jobs

Put them in a task file with `manual` in the schedule (or no schedule entry at all) and run them by hand:

```bash
sudo -u pandermos pandermos run fix-old-images --model sonnet --timeout 80m \
  --note "only posts from November, skip official announcements"
```

Check `pandermos usage` afterwards. One-off jobs are where usage spikes come from.

## Language

Tasks can be written in any language. The report contract accepts `STATUS:`/`NOTIFY:` and the Turkish `DURUM:`/`TELEGRAM:` (with `TEMIZ`, `DUZELTILDI`, `UYARI`, `KRITIK`). The agent replies in the language of the task unless `CLAUDE.md` says otherwise.
