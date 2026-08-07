# Lint

Health checks for the wiki. Also hosts the shared walk logic that `status` reuses.

## When this runs

**Lint** runs when the user explicitly asks (`"lint my wiki"`, `"audit the knowledge base"`, `"check for contradictions"`) or monthly as hygiene.

**Status** runs when the user asks for a snapshot (`"what's in my wiki"`, `"status"`, `"how many pages"`). It's the no-severity, read-only subset of lint — counts only.

## The walk (shared with status)

Both operations start by walking the wiki tree:

1. `Glob` for every `docs/02_learning/wiki/**/*.md` file.
2. For each file, parse the YAML frontmatter (title, created, last_updated, source_count, status, tags, aliases).
2b. **Strip fenced code blocks and inline code spans before any `[[link]]` or `[Source:]` regex pass.** Wiki pages routinely quote link *syntax* as illustrative examples (`` `[[People/Name]]` ``, `` `[[slug]]` ``), and Obsidian does not resolve links inside code spans either — so a scanner that matches raw text reports them as broken. This has produced false positives in consecutive lint runs; strip first, match second.

   ```python
   text = re.sub(r"```.*?```", "", text, flags=re.S)   # fenced blocks
   text = re.sub(r"`[^`\n]*`", "", text)                # inline spans
   ```

   Keep the unstripped text for line-number reporting; match against the stripped copy.
3. Build three indices in memory:
   - **slug → page** (from filename and frontmatter `title`)
   - **slug → inbound-links** (by scanning every page for `[[target]]` references)
   - **slug → outbound-links** (from each page's `[[...]]` references)
4. Parse `wiki/index.md` into a set of listed slugs.
5. Read the last N=20 entries of `wiki/log.md`.

This walk is cheap for wikis up to ~200 pages. For larger wikis, consider bundling a script; see the `scripts/` note in SKILL.md.

## Lint checks

Run every check. Group findings by severity in the report.

| # | Check | Severity | Detection |
|---|---|---|---|
| 1 | Contradictions between pages | high | Grep for `> [!warning] CONTRADICTION` and legacy `> CONTRADICTION:`. Also cross-read pages sharing a tag; flag semantic conflicts the callouts missed. |
| 2 | Claims missing `[Source:]` attribution | high | Line-by-line scan of `## Key claims` sections. Any non-empty, non-heading line without a `[Source: ...]` trailing marker or a preceding line carrying one is a finding. |
| 2b | **`[Source:]` targets that don't resolve** | high | For every `[Source: ...]` marker, split on `,` for multi-source and on ` — ` for the negative-citation form, then check each filename exists in `raw/`. A marker pointing at a nonexistent file is functionally an uncited claim. |
| 3 | Broken wiki-links | high | For every `[[target]]`, resolve to a file or a frontmatter `aliases:` entry. Unresolved = broken. |
| 4 | Missing frontmatter fields | high | YAML parse. Required: `title`, `created`, `last_updated`, `source_count`, `status`. Obsidian-extended (warn only if totally absent): `tags`, `aliases`. |
| 5 | Index drift | high | Set diff between (files under `wiki/`) and (slugs in `wiki/index.md`). Both directions: page-without-index-entry and index-entry-without-page. |
| 6 | Stale claims | medium | `status: draft` older than **90 days**, or `status != reviewed` on a page whose most-recent source is > 18 months old. See "Tuning the staleness check" below before changing the threshold. |
| 7 | Orphan pages | medium | Pages with zero inbound `[[links]]` AND not listed in `index.md` as a hub. |
| 8 | Mentioned-but-never-defined | medium | `[[links]]` whose target has no file. Overlaps with #3 but reported separately because the fix is different (create a page vs. fix a typo). |
| 9 | `last_updated` older than most recent citing source | low | Compare `last_updated` to the **`date:` frontmatter** of every `[Source:]`-cited raw file. **Never use `mtime`** — in a git repo it records checkout time, not authoring time, so a clone or rebase resets every file at once and the check reports the entire wiki. Observed: 75 findings clustered on two git-operation dates vs. 13 real ones from `date:`. Skip raw files with no `date:` field rather than falling back to `mtime`. |
| 10 | Tag sprawl | low | Fuzzy-compare the tag universe. Near-duplicate tags (`recsys` vs `recommender-systems`) are a finding. |

Exclude `wiki/index.md`, `wiki/log.md`, and `wiki/lint-report-*.md` from the page-level checks — they have their own format.

## Severity meaning

- **high** — breaks the contract the wiki makes with its reader. Fix soon.
- **medium** — degrades trust or discoverability but isn't wrong.
- **low** — cosmetic or future-proofing.

## Tuning the staleness check

Check #6 is the easiest check in this file to render meaningless, because it fires
on a frontmatter *default* rather than an observed condition.

`ingest` writes `status: authored` for pages it fully wrote from a source (see
`references/ingest.md`). If it wrote `status: draft` instead — as versions through
v2.7.1 did — then every page starts in the state the check penalizes, nothing ever
clears it, and the finding count grows monotonically with the wiki. A real vault hit
**142 of 290 pages (49%) flagged**, with a **completely empty 31–60 day band**: the
gradient you'd expect from pages aging in and graduating out was absent, because no
page had ever been promoted. The check was measuring the template, not the wiki.

Two rules follow:

1. **Only count a status that a human action can clear.** `draft` must mean "genuine
   stub, needs work," not "the skill made this." That is why `authored` exists.
2. **If the finding rate exceeds ~15% of pages, the threshold is wrong, not the wiki.**
   A check that fires on half the corpus carries no information — the user learns to
   ignore it, and it can no longer warn them when something genuinely rots. Raise the
   threshold or fix the classifier; do not report the number and move on.

When reporting check #6, always include the **age-band histogram**, not just a total.
The shape is what distinguishes real decay (a smooth gradient) from a stuck default
(a cliff with an empty near band).

**Never propose bulk-flipping `draft` → `reviewed` to clear this check.** It asserts
human review that did not happen and destroys the only signal the vault has for
tracking real review. If the user asks for it, say so.

## Report

Write the report to `docs/02_learning/wiki/lint-report-YYYY-MM-DD.md` using the lint report template in `references/templates.md`.

Sections:

1. **Summary counts** — total findings by severity, total pages scanned.
2. **High severity** — one subsection per finding with file:line references.
3. **Medium severity** — same.
4. **Low severity** — same.
5. **Proposed fix plan** — grouped by fix cost (cheap / medium / expensive) using the "Lint triage" prompt in `references/prompts.md`.
6. **Sign-off** — empty signature line for the user.

**Never auto-apply fixes.** Lint proposes; the user decides. If the user then says "apply the cheap ones", that becomes a separate mutation turn.

## Cleanliness composite score

After running all checks, compute a single `cleanliness_score` (0–100) from the raw counts. This single number makes wiki health trendable across runs — inspired by the codebase-cleanliness-index pattern (see [[codebase-cleanliness-index]]).

### Inputs

Collect these counts from the walk and checks above:

| Symbol | What it measures |
|--------|-----------------|
| `P` | Total wiki pages scanned (exclude `index.md`, `log.md`, `lint-report-*.md`) |
| `orphans` | Pages with zero inbound links AND not listed as a hub in `index.md` (check #7) |
| `broken_links` | Unresolved `[[wiki-link]]`s (check #3), counted **after** code-stripping (walk step 2b) |
| `contradictions` | Pages carrying an unresolved `> [!warning] CONTRADICTION` callout (check #1) |
| `missing_citations` | Claims lacking a `[Source: ...]` marker (check #2) **plus** markers whose target doesn't resolve in `raw/` (check #2b) — an unresolvable citation is functionally an uncited claim |
| `missing_frontmatter` | Pages missing ≥1 required frontmatter field (check #4) |
| `index_drift` | Count of index-vs-file mismatches in both directions (check #5) |
| `stale_pages` | Pages flagged as stale by check #6 |

### Formula

```
penalty = (
    (orphans            / max(P,1)) * 30  +   # orphan rate          (high weight)
    (broken_links       / max(P,1)) * 25  +   # broken-link rate     (high weight)
    (contradictions     / max(P,1)) * 20  +   # contradiction rate   (medium)
    (missing_citations  / max(P,1)) * 10  +   # citation completeness (medium)
    (missing_frontmatter/ max(P,1)) * 10  +   # frontmatter health   (medium)
    (index_drift        / max(P,1)) * 3   +   # index hygiene        (low)
    (stale_pages        / max(P,1)) * 2        # freshness            (low)
)
cleanliness_score = round(max(0, 100 - penalty))
```

Weights sum to 100 percentage-points of penalty headroom. Each term is a rate (finding-count / page-count) so the score is comparable as the wiki grows.

> **Do not reintroduce a `* 100` on `penalty`.** The weights are already expressed in
> penalty *points*, so `penalty` lands on a 0–100 scale directly. Multiplying by a
> further 100 degenerates almost any non-trivial wiki to `0` — a wiki with a single
> broken link in 200 pages would score 87 instead of 99.9. This bug shipped through
> v2.7.1 and forced two consecutive lint runs to hand-correct the number, which
> silently made `.lint-history.tsv` non-reproducible for anyone following the spec.
>
> Sanity check when editing this formula: a wiki with **zero** findings must score
> `100`, and a wiki where *every* page is an orphan must score `70`.

### Interpretation

| Score | Health |
|-------|--------|
| 90–100 | Clean — compounding is safe |
| 75–89 | Acceptable — a few targeted fixes needed |
| 60–74 | Degraded — fix high-severity items before next ingest |
| < 60 | Critical — wiki debt is outpacing value |

### Output line

Emit as the last line of the report **Summary** section:

```
cleanliness_score: NN/100 (orphans=A, broken_links=B, contradictions=C, missing_citations=D, missing_frontmatter=E, index_drift=F, stale_pages=G)
```

### Persistence

Append one tab-separated row to `docs/02_learning/wiki/.lint-history.tsv` (create if absent):

```
YYYY-MM-DD\tNN\tA\tB\tC\tD\tE\tF\tG
```

Header row (write only if the file is new):

```
date\tcleanliness_score\torphan_pages\tbroken_links\tcontradictions\tmissing_citations\tmissing_frontmatter\tindex_drift\tstale_pages
```

This file is the trend source. It is never modified — only appended to.

## Log entry

Append after writing the report:

```
## [YYYY-MM-DD] lint | N findings (H high / M medium / L low) | score: NN/100
```

## State write

After the lint report and log entry are written, update the vault's cadence-state file if it exists at the canonical path:

- **Target**: `docs/00_ops/meta/state.md`
- **Writes**:
  - Replace `last_wiki_lint:` value with today's date (`YYYY-MM-DD`).
  - Replace `last_wiki_lint_score:` value with the computed `cleanliness_score`. Add the line if absent (place it next to `last_wiki_lint`).

This closes the loop with downstream cadence trackers (e.g. `chief-of-staff weekly`) so they don't keep flagging lint as overdue after a successful run.

**Vault-shape-aware**: skip the write silently if `docs/00_ops/meta/state.md` is not present — the skill stays portable to vaults without a chief-of-staff setup. In that case, emit a one-line reminder at the end of the lint output:

```
No state.md found at docs/00_ops/meta/ — track lint cadence yourself.
```

Surface the proposed `state.md` diff to the user as part of the lint output before writing. Never write to `state.md` without showing the diff, same contract as every other mutation in this skill.

## Status report (no-mutation variant)

Status reuses the walk. It writes nothing to disk. Output to the user:

**Counts**:
- Raw sources: X
- Wiki pages: Y (by status: A draft, B authored, C reviewed, D needs_update)
- Orphan pages: Z
- Unresolved `CONTRADICTION` callouts: C
- Pending `[!question]` open questions: Q

**Activity**:
- Last ingest: `<date>` — `<source-slug>`
- Days since last lint: D
- Recent log entries: last 5

**Summary**: 5-bullet narrative using the "Status summary" prompt in `references/prompts.md`. Emphasize what's stale and what's well-covered.

Status never writes a log entry. It's a pure read.
