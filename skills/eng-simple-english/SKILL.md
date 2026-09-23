---
name: eng-simple-english
description: |
  Rewrite one document into plain English that a non-native reader understands
  on the first read. Use it on a design doc, an internal doc, a spec, a
  runbook, a PR description, or an agent-instructions file such as CLAUDE.md
  or a SKILL.md. It strips business idioms, unexplained jargon, and metaphors,
  and enforces short sentences, one idea per sentence, and one word per idea.

  Do not use this for a normal chat reply. The "Plain English" output style
  already covers every reply, on every message, with no extra step. Do not use
  it for marketing copy, a blog post, or anything meant to persuade. It
  removes the hedges and color that persuasive writing needs, on purpose.

  Trigger phrases: "make this readable", "rewrite in plain English",
  "simplify this doc", "this is hard to understand", "non-native readers
  won't get this", "run eng-simple-english on this", "clean up this SKILL.md".
disable-model-invocation: false
allowed-tools: Read Edit Grep Bash
---

# Eng Simple English Skill

**Verb:** Rewrite one document so a reader who does not read English as a first
language understands it correctly on the first pass, without changing what it
means.

**Input:** A file path (or a PR's changed files) containing prose meant to be
read once and acted on.

**Output:** The same file, same technical content, rewritten under the rule
list in section 4, plus the self-check results from section 5.

## 1. When to use this skill

| Use it for | Do not use it for |
|---|---|
| A design doc | A normal chat reply. The "Plain English" output style already covers that, every time, automatically. |
| A `SKILL.md` or `CLAUDE.md` | Marketing copy or a blog post. This method removes hedges, filler, and color on purpose. That is wrong for persuasive writing. |
| A PR description or review comment | A quote from someone else. Leave quoted text exactly as written. |
| A runbook or setup guide | Code itself. This skill edits prose, not `.dart` files. |
| An internal doc read once by the team | A README meant to sell the project to outsiders. Ask the user first: that is closer to marketing copy. |

If you are unsure which bucket a document falls in, ask: will one person read
this once and act on it, or will many people read it to decide whether they
like the project? The first is this skill's job. The second is not.

## 2. Where these rules come from

This rule list is built on the same idea as two established standards, not
copied from either:

- **ASD-STE100 (Simplified Technical English).** A controlled-English standard
  aircraft maintenance manuals use. Not every reader reads English as a first
  language, and a tired reader must not misread an instruction. The standard
  restricts vocabulary to roughly 900 approved words, each with one approved
  meaning, and gives each word exactly one part of speech.
- **The US Plain Writing Act and plainlanguage.gov guidelines.** Federal
  agencies write for the reader: short sentences, active voice, everyday
  words, one idea at a time, no legal or technical jargon left unexplained.

Inside this repo, two more things already apply and this skill does not
replace them:

- **The "Plain English" output style** (`~/.claude/output-styles/plain-english.md`)
  governs every chat reply, automatically, on every message. This skill is
  the equivalent discipline for a document, not a reply. The rules below are
  stricter, because a document gets read more than once and nobody is present
  to answer a follow-up question about it.
- **A Stop hook** (`~/.claude/hooks/plain-english-lint.py`) checks chat
  replies for banned phrases, em dashes, run-on semicolons, and long
  sentences. It is a personal setup, so not every machine has it installed.
  This skill's rule list works with or without it. If it is present, run it
  as an extra check (section 5), never as a replacement for reading the
  document yourself.

## 3. The method, in four steps

1. **Sort the text.** Mark each paragraph as an instruction or an explanation.
   The two types get different word limits and different verb forms.
2. **Lock your words.** Find each idea with two or more common names
   ("check" / "verify" / "confirm", "config" / "settings"). Pick one word and
   use only that word for the rest of the document.
3. **Apply the rule list** in section 4.
4. **Run the self-check** in section 5 before you call the document done.
   This step is required, not optional.

### Step 1 in detail: instruction vs. explanation

| | Instruction | Explanation |
|---|---|---|
| Job | Tells the reader what to do | Tells the reader what something is or does |
| Verb form | Command form: "Open the settings page." | Plain present or past: "The settings page holds the API key." |
| Sentence limit | 20 words | 25 words |
| One-thing rule | One action per sentence | One topic per paragraph, six sentences per paragraph at most |

A step-by-step guide is instructions. A design doc's background section is an
explanation. A note inside a set of steps ("this can take up to a minute") is
still an explanation: it gets the 25-word limit and no command form.

### Step 2 in detail: lock your words

Before you rewrite a sentence, decide the one word you will use for each idea
that has more than one common name in the document. Example lock, for a doc
about an approval flow:

- "check", "verify", "confirm" → use **confirm**, always
- "config", "settings", "options" → use **settings**, always
- "delete", "remove" → use **delete** for a user action, **remove** for a
  system action, and keep that split the same everywhere

Skipping this step is why the same document ends up calling one thing three
different names, and the reader has to guess whether they mean the same
thing.

## 4. Rule list

### Words

- **Avoid these phrases.** Each one is a business idiom or engineering
  metaphor that a non-native reader, or a reader outside this specific team,
  cannot look up:

  `load-bearing`, `blast radius`, `footgun`, `yak shaving`, `happy path`,
  `sad path`, `source of truth`, `single source of truth`,
  `first-class citizen`, `lives in`, `lives under`, `surface area`,
  `wire up`, `glue code`, `north star`, `move the needle`,
  `low-hanging fruit`, `boil the ocean`, `circle back`, `double-click on`,
  `in the weeds`, `table stakes`, `non-trivial`, `orthogonal`,
  `out of the box`, `batteries included`, `grok`, `dogfood`, `bikeshed(ding)`,
  `rabbit hole`,
  `at the end of the day`, `it's worth noting`, `worth noting that`,
  `needless to say`, `when in doubt`, `belt-and-suspenders`, `smoking gun`,
  `kill shot`, `money shot`, `sidecar`, `escape hatch`, `worth calling out`,
  `worth recording`, `it is important to note`, `anchoring` (on an idea),
  `safety net`, `construction brief`, `the loop` (for "the workflow"),
  `living code`, `architectures rot`.

  This list overlaps with `~/.claude/hooks/plain-english-lint.json`'s
  `banned_phrases`, kept here so the skill works on a machine without that
  personal hook. If you also have that hook, treat its list as the more
  current one and fold new entries back into this list when you find them.

- **Use the plain word.** "Use" beats "leverage" or "utilize." "Before" beats
  "prior to." "If" beats "in the event that." "Show" beats "surface." "Start"
  beats "kick off."

- **One idea, one word, for the whole document.** This is Step 2, enforced.

- **Keep a real technical or domain name exact, and define it once.** A term
  is real, not a metaphor, when it names a specific thing in this codebase or
  in Dart. Examples: `PowerSyncDatabaseWrapper`, cascade notation, a gate (the
  consent gate feature), a hook (a callback registration point), a guardrail,
  a spine, plumbing (a real construction term, since this app estimates
  building costs). **`seam`** is the case to watch. This repo's own skills use
  it constantly (the `PowerSyncDatabaseWrapper` seam, the `SupabaseWrapper`
  seam) to mean "the interface a feature depends on instead of the real SDK."
  That is a real, defined term in this repo now, not an unexplained metaphor,
  so keep using it. The first time any one document uses it, say what it
  means in one clause: "behind the `PowerSyncDatabaseWrapper` seam (the
  interface features depend on instead of the SDK directly)." After that
  first sentence, use the bare word freely in that document. Do not coin a
  *new* metaphor to stand in for "a place code plugs into." A new metaphor is
  exactly what turns one team's shorthand into another reader's confusion.

### Sentences

- Keep the word limit from Step 1 (20 words for an instruction, 25 for an
  explanation).
- One idea per sentence. Do not join two ideas with a semicolon or an em
  dash. Write two sentences instead.
- Do not drop words to sound short. Keep "that." Keep articles ("the," "a,"
  "an").
- Put a condition before the action it controls: "If the build fails, read
  the log," not "Read the log if the build fails."
- Use a numbered list for three or more steps done in order.

### Verbs

- **Use only these modal words: can, will, must.** Do not use "should,"
  "would," "may," "might," or "could." See the modal ladder below for the
  rewrite.
- Use the command form for an instruction: "Open the file," not "The file
  should be opened" and not "You will need to open the file."
- Avoid the passive voice unless the actor truly is not known. "The server
  rejects the request" beats "the request is rejected" whenever you know what
  does the rejecting.
- Do not use an "-ing" verb as the main verb of a sentence. "The job runs
  every hour," not "The job is running every hour."
- Name the action with a verb, not a noun: "compress the file," not "perform
  compression of the file."

**The modal ladder:**

| You wrote | Write instead |
|---|---|
| "should" (a requirement) | "must" |
| "should" (a suggestion) | State it as a fact and say why ("X is better because Y"), or delete the sentence |
| "may," "might," "could" (something is possible) | "can": "The build can fail if the disk is full." |
| "may" (permission) | "can" |
| "would" (a hypothetical) | Restate as a real condition: "If X happens, Y happens." |

### Structure

- One topic per paragraph.
- State the most important fact first in a paragraph, then support it.
- Use a heading that names the topic in plain words. Do not make the heading
  a clever phrase.

### Punctuation

- No semicolons. Write two sentences.
- No em dashes, and no double hyphen used as a dash. Use a full stop, a
  comma, or brackets.
- Code, a command, a file path, or a quoted error message counts as one word
  for the sentence-length count, even when it has several words inside it.

### Never touch (Untouchables)

Leave these exact, even when they break a rule above:

- Code, commands, flags, file paths, identifiers.
- Quoted error messages and log lines.
- Product names, API names, config keys, ticket ids (`CA-XXX`).
- A number with a unit ("512 MB," "30 seconds").
- Text already inside a quote from another person.

## 5. Self-check, before you call it done

Run these checks on the rewritten document. Fix what they find, then stop.

1. **Length.** Find the three longest sentences and count the words. Any
   sentence over the Step 1 limit gets split.
2. **Banned forms.** Search the document for `'ll`, `'re`, `'s` used as a
   contraction, `should`, `would`, `may`, `might`, `could`, an em dash, a
   semicolon, and any phrase from the list in section 4. Fix every hit.
3. **Condition order.** Search for every `if` and every `when`. Each one must
   open its sentence, ahead of the action it controls, not sit in the middle.
4. **Word lock.** Search for every word you did not pick in Step 2 for a
   concept you locked. Replace each hit with the word you chose.
5. **If `~/.claude/hooks/plain-english-lint.py` exists on this machine**, run
   it against the file as an extra pass: `python3
   ~/.claude/hooks/plain-english-lint.py --check <file>`. Treat any output as
   more things to fix, not as the whole job. It only catches banned phrases,
   em dashes, run-on semicolons, and long sentences. It does not catch
   passive voice, missing word locks, or a metaphor it has never seen before.

## 6. Worked example

This example is a real excerpt from `docs/Agentic-Skills-Migration-Plan.md`
in this repo, sorted as an explanation.

**Before:**

> Every skill's frontmatter also carries a natural-language description, so
> the model *may* auto-invoke a skill when your sentence matches
> (`disable-model-invocation: false`). That's a convenience, not a contract —
> phrasing drift can miss, or fire the wrong skill. `/command` never misses.
> **Rule of thumb: drive the workflow with slash commands; let
> auto-invocation be a safety net, never the plan.**

**After** (word lock: "load" for "invoke"/"fire"/"drive"):

> Every skill's frontmatter also carries a plain-language description. When
> `disable-model-invocation: false` is set and your sentence matches that
> description, the model can load the skill on its own. This automatic
> loading is a convenience. It is not a guarantee: a slightly different
> sentence can miss the match, or match the wrong skill. Typing `/command`
> always loads the right skill. Run the workflow with slash commands. Treat
> automatic loading as a backup, not the plan.

What changed: one 45-word sentence with an em dash and a semicolon-joined
clause became six short sentences. "May," "that's," and "drive the workflow"
became plain, direct statements. "Safety net" (an idiom) became "backup" (a
plain word), then that same word is used again, not swapped for a synonym.

**A second example, from the same file:**

**Before:**

> When a coding agent (Cursor, Claude Code) invokes a skill, it loads the
> entire `SKILL.md` into its context window. Every line costs tokens whether
> the agent needs it or not. A skill that bundles unrelated behaviors forces
> the agent to read past irrelevant content — and risks it anchoring on the
> wrong pattern for the moment.

**After:**

> When a coding agent, such as Cursor or Claude Code, runs a skill, it loads
> the whole `SKILL.md` file into its context window. Every line in that file
> uses tokens, even a line the agent does not need right now. A skill that
> mixes unrelated behaviors makes the agent read past content it does not
> need. That unrelated content can also make the agent copy the wrong pattern
> for the current step.

What changed: "invokes," "bundles," and "anchoring on" (a cognitive-bias
metaphor) became "runs," "mixes," and "copy." The em-dash clause became its
own sentence.

## 7. Applying this skill

**As the author of a document:** run this skill on the full file before you
open the PR, not after a reviewer asks for it.

**As a reviewer:** when a document is hard to read, name the specific
sentence. Point the author at this skill by name, the same way you point them
at any other skill: "Run `eng-simple-english` on this file and push the
result."

**As the agent asked to fix a flagged document:** read the whole file first.
Do not rewrite sentence by sentence without the full context, or the word
lock in Step 2 will drift partway through. Rewrite the whole file in one
pass, run the self-check, then show a diff, not just a restated summary of
what you changed.

## Checklist

- [ ] Every paragraph is sorted as an instruction or an explanation, and
      follows that type's word limit.
- [ ] Words are locked: one word per idea, for the whole document.
- [ ] No sentence uses a banned phrase from section 4.
- [ ] No sentence uses an em dash, a double-hyphen dash, or a semicolon
      joining two clauses.
- [ ] No sentence uses "should," "would," "may," "might," or "could" outside
      a direct quote.
- [ ] Every condition ("if," "when") opens its sentence.
- [ ] Every real technical or domain term (like `seam`) is defined once, on
      first use, then used freely.
- [ ] Code, commands, file paths, quoted errors, product names, and numbers
      with units are left exactly as they were.
- [ ] The self-check in section 5 ran, and its findings are fixed.
