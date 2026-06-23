# Task Roulette — Implementation Plan

**Date:** 2026-06-18
**Working title:** Roulette (rename freely — bundle id `dev.rafaelmancini.Roulette`)
**Plan file:** `/Users/rafaelmancini/Projects/personal/project-task-roulette/.claude/plans/2026-06-18-task-roulette-plan.md`

## 1. Concept

A macOS menu-bar app that removes "what do I start?" decision paralysis (ADHD-oriented).
The user stores tasks in two buckets — **need to do** and **want to do** — and spins a
weighted roulette to be handed exactly one task to start next.

### Critique baked into the design
- **Selection is the product, not the wheel animation.** Pure uniform random surfaces
  contextually-wrong tasks and erodes trust. We pick **weighted-random among _eligible_
  tasks** (eligibility = chosen mode + not archived).
- **Mode selector (Need / Want / Both)** prevents the wheel from rationalising
  procrastination by handing you a "want" while you're avoiding work. The user chooses
  intent before spinning.

## 2. Decisions (locked 2026-06-18)

| Area | Decision |
|------|----------|
| Stack | Native Swift / SwiftUI |
| Menu bar | SwiftUI `MenuBarExtra` (agent app, `LSUIElement`, no Dock icon) |
| Trigger | Both menu-bar icon **and** global hotkey |
| Global hotkey | `KeyboardShortcuts` SPM package (Carbon `RegisterEventHotKey`, no Accessibility permission) |
| Persistence | SwiftData (local store) |
| Selection | Weighted random; weight = user-set priority (Low/Med/High) |
| Want lifecycle | Cross off + archive on completion (never reappears) |
| Need lifecycle | Per-task `repeats` toggle: one-shot archives; recurring stays in pool |
| Stats | Completion history + today-count + streak + recent list |
| v1 scope | MVP + polish (spin animation, tags, stats) |
| Project gen | XcodeGen (`project.yml` committed, `.xcodeproj` gitignored) |

## 3. Data model (SwiftData)

### `TaskItem` (@Model)
- `id: UUID`
- `title: String`
- `notes: String`
- `kindRaw: String` → `TaskKind` (need / want)
- `priorityRaw: Int` → `Priority` (low=1, medium=2, high=3; weights 1/3/6)
- `repeats: Bool` (recurrence toggle)
- `tags: [String]`
- `isArchived: Bool` (one-shot completed → removed from wheel, kept for history)
- `createdAt: Date`
- `lastCompletedAt: Date?`

### `CompletionRecord` (@Model)
Denormalized snapshot so history survives task edits/deletes.
- `id: UUID`, `taskID: UUID`, `titleSnapshot: String`, `kindRaw: String`, `completedAt: Date`

## 4. Core logic (pure, unit-tested)

- **`TaskPicker.pick(from:using:)`** — weighted-random selection over
  `[WeightedCandidate(id, weight)]` with an injectable RNG → deterministic tests.
- **`StatsCalculator`** — today count, current streak (consecutive days with ≥1 completion),
  recent completions, from `[CompletionRecord]`.
- Both operate on plain values, decoupled from SwiftData fetches, so they test without a
  ModelContainer.

## 5. UI

- `MenuBarExtra` (SF Symbol `dice.fill`), `.menuBarExtraStyle(.window)` panel.
- **Spin tab:** mode segmented control → big Spin button → animated reveal → result card
  with **Start / Done / Re-spin**.
- **Tasks tab:** list grouped by kind, add/edit (title, notes, kind, priority, repeats,
  tags), swipe to archive/delete.
- **Stats tab:** today count, streak, recent completions.
- `Settings` scene: rebind global hotkey via `KeyboardShortcuts.Recorder`.

## 6. Targets

- `Roulette` (app)
- `RouletteTests` (unit tests for `TaskPicker`, `StatsCalculator`)

## 7. Milestones

1. **M0 — Skeleton:** project.yml, buildable empty MenuBarExtra app, hotkey opens panel. ✅ first checkpoint
2. **M1 — Core:** data model + TaskPicker + tasks CRUD + spin (no animation).
3. **M2 — Lifecycle:** Done/archive/recurrence + CompletionRecord logging.
4. **M3 — Polish:** spin animation, stats tab, tags, hotkey settings.
5. **M4 — Tests + package:** unit tests green, `.app` builds, run instructions.

## 7b. Release / Distribution (direct download)

Channel decision: **direct download** (notarized DMG), not Mac App Store.
Tip platform: **GitHub Sponsors** (link in Settings → Support; placeholder handle
`your-handle` in `SettingsView.swift` — replace before release).

Pipeline scaffolded at `scripts/build-release.sh` (archive → Developer ID export →
notarize → staple → DMG → notarize DMG). Needs env: `TEAM_ID`, `NOTARY_PROFILE`.

**Blockers before a public release:**
- [ ] Apple Developer Program membership ($99/yr) + Developer ID Application cert.
- [ ] `notarytool store-credentials` profile in keychain.
- [ ] **App icon** — no `AppIcon` asset exists yet; required for Finder/DMG. Need a
      1024×1024 source (an asset catalog must be added to `Sources/` and wired).
- [ ] Replace GitHub Sponsors placeholder handle.
- [ ] LICENSE file + decide open-source vs closed.
- [ ] (later) Sparkle auto-update with a signed appcast.
- [ ] (optional) Enable App Sandbox entitlement (deps are sandbox-compatible).

Privacy posture: fully local (SwiftData), zero network calls → trivial privacy story,
painless notarization.

## 8. Open / deferred (not v1)
- Staleness boost in weighting (older un-picked → higher weight).
- iCloud/CloudKit sync, mobile companion, reminders/notifications.
- "Time available / energy" filters (stronger eligibility) — revisit after using v1.
