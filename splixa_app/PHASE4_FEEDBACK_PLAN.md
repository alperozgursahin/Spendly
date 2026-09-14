# Phase 4 — Device-test feedback backlog

Owner's device test on 14 Sep 2026 produced this list. Work top-down; tick each
item and record what changed. Do not start Phase 5/6 items from here.

Legend: `[ ]` open · `[~]` in progress · `[x]` done · `[?]` needs owner input

---

## A. Broken — fix first

- [x] **A1. Pro Tools → "Advanced analytics & date ranges" does nothing.**
  Button does not navigate. Check the route and the Pro guard in
  `pro_tools_screen.dart`.
- [x] **A2. Activity heatmap ignores history.** Data added 24 Jul 2026 does not
  appear when that date range is selected. Suspect the heatmap query is pinned
  to a rolling window and ignores the picked range
  (`heatmap_provider.dart`, `statistics_screen.dart`).
- [x] **A3. Biometric lock screen is ugly.** Wants: black background, Splixa
  logo, nothing else. Remove the red error text
  (`app_lock_service.dart` + its lock UI).
- [x] **A4. Social chat input bar sits off the bottom** on Android 14 — had to
  tap blind to reveal it. Safe-area / keyboard inset bug in `chat_screen.dart`.
- [x] **A5. Group info → "Delete group" button is half off-screen.**
  Overflow in `group_info_screen.dart`.
- [ ] **A6. 7-day trial not shown on the paywall** although the Play Console
  base plan has it. Verify what the store actually reports; the badge is gated
  on an exact `P1W` free phase.
- [~] **A7. Recurring expenses cannot be tested by the owner** (weekly/monthly
  only). ASSISTANT must verify generation server-side. Also still open: the
  cron run logged `Recurring generation failed` with an empty error code; the
  widened logging needs deploying and the next run checking.

## B. Product changes — small

- [ ] **B1. Custom categories: drop colour and emoji.** Name only — users can
  type an emoji into the name. Simplifies the form and the model.
- [ ] **B2. PRO / STANDARD badge on the dashboard header,** to the right of the
  Splixa logo and wordmark.
- [ ] **B3. Group "Add expense" → "What for?" needs the same default category
  set as the home screen,** plus "Other". Custom categories stay Pro-only.
  This is also why the trip summary shows "uncategorized".
- [ ] **B4. Invite-to-group member list:** show avatars; members already in the
  group appear disabled with an "already in group" label instead of an enabled
  button.
- [ ] **B5. Other user's profile should show** bio, avatar, shared groups, and
  how many months they have been on Splixa.

## C. Product changes — larger

- [ ] **C1. Trip summary card is too plain and not useful.** Needs: member
  names, who owes whom and how much *right now*, payer + category + amount per
  expense, and a clear "everyone is settled up" state when there is no debt.
  Must stay simple enough to drop into a WhatsApp group. Keep it privacy-safe.
- [ ] **C2. Statistics screen needs 1–2 more views** — a bar chart plus one
  other. Deliberately not more.
- [ ] **C3. Paywall redesign.** Owner finds it unprofessional. Research what
  strong subscription paywalls do (Splitwise and peers) before rewriting.
- [ ] **C4. Onboarding redesign.** Current animation is placeholder-grade.
  Wants something striking, with real animation.

## D. Measurement question (no code)

- [ ] **D1. Explain how to answer:** what share of installs finish onboarding,
  what share drop out during it, what share reach login/signup. The Firebase
  realtime screen does not show this; needs a GA4 funnel exploration on the
  events Phase 1 already emits (`onboarding_start`, `onboarding_step_viewed`,
  `onboarding_complete`, `login`, `first_open`).

## E. Carried over from Phase 4, still open

- [ ] **E1. Native Android widget strings are English-only** for all 12 shipped
  locales.
- [ ] **E2. iOS widget extension** is not an Xcode target yet (needs macOS).
- [ ] **E3. Native-speaker review** of the 10 machine-assisted locales.

---

## Progress log

_Append one line per completed item: what changed, which files, how verified._

- **A7 (generation half) — VERIFIED, no code change needed.** Ran two
  rollback-scoped (`BEGIN … ROLLBACK`) end-to-end tests of
  `generate_recurring_expenses_for_user` against production.
  Test 1 — monthly TRY template: `generated=1 amount=100.00000000
  source=recurring:identity runs=1 next_run=2026-10-13`, and a second pass in
  the same transaction produced `0` (idempotent, advisory lock + next_run guard
  both hold).
  Test 2 — three templates in one run: `generated=3`, weekly template advanced
  `next_run` by exactly 7 days (`2026-09-20`); a USD template locked the
  **fresh** FX rate (`rate=40.0000 base=400.00000000
  src=recurring:scheduled_open_er_api`) rather than the stale `30` stored on the
  row; a `manual_user_locked` template **kept** its own rate
  (`rate=25.0000 base=250.00000000 src=recurring:manual_user_locked`).
  Zero leakage confirmed after rollback. **Still open:** the cron run that
  logged `Recurring generation failed` with an empty error code — the widened
  JSON logging in `generate-recurring-expenses` needs deploying and the next
  scheduled run inspecting.

- **A1 — FIXED. Root cause was the ShellRoute's Navigator GlobalKey.**
  `statistics` was a child of `/dashboard`, i.e. *inside* the `ShellRoute`.
  `/pro-tools` is a top-level route, so pushing `/dashboard/statistics` from it
  asked go_router to mount a second instance of the shell's Navigator while the
  first was still on the stack — one `GlobalKey`, two Navigators — and the
  navigation failed outright. The same push works from the dashboard because
  the shell is already the current branch, which is why only the Pro-tools entry
  point looked broken. Statistics never shows the bottom navigation
  (`MainScaffold._showsPrimaryNavigation` returns false for it), so it gained
  nothing from the shell: moved it to a top-level `/statistics` route.
  Files: `lib/main.dart`, `pro_tools_screen.dart`, `splixa_home_screen.dart`,
  `dashboard_screen.dart`. Audited every other non-shell screen for the same
  cross-boundary `push` — none.

- **A2 — FIXED, two separate causes.** (1) `heatmapDataProvider` filtered on
  `heatmapRangeProvider`, a `String` of `1M/3M/6M/1Y` that no widget ever set,
  so it was permanently `1M` = "since the 1st of the current month" — July data
  was dropped before it reached the calendar. (2) The picked `DateTimeRange`
  lived in `_StatisticsScreenState` and was never shown to the heatmap at all,
  and `HeatMapCalendar` copies `initDate` into its own state on first build, so
  it stayed on the current month regardless. Now: `heatmapRangeProvider` is a
  `DateTimeRange?` defaulting to `null` (= all history, no rolling window), the
  statistics screen reads *and* writes that one provider instead of local state
  so the pie chart and heatmap can never disagree, and `HeatmapCard` takes an
  `initialMonth` with a `ValueKey` so picking a range jumps the calendar to it.
  Day-normalised comparison on both ends, so an expense at 14:00 on the last
  day of a range is no longer excluded from its own range.
  Files: `heatmap_provider.dart`, `heatmap_widget.dart`, `statistics_screen.dart`.

- **A3 — FIXED. The red text was Flutter's, not ours.** `AppLockGate` renders
  inside `MaterialApp.builder`, above the Navigator, where there is no `Material`
  ancestor — so every `Text` inherited `WidgetsApp`'s deliberately loud fallback
  style (large red monospace, yellow double underline). Replaced the whole gate
  with what the owner asked for: `Material(color: Colors.black)`, the Splixa
  mark centred, no copy at all. The logo breathes (1.8 s opacity loop) and the
  whole screen is tappable to retry, so cancelling the system biometric prompt
  is not a dead end — and with no text there is nothing to translate into 12
  locales. `pro_app_locked_title` / `_body` / `pro_unlock` are left in the
  catalog unused; the key-usage test only guards the missing direction.
  File: `app_lock_service.dart`.

- **A4 — FIXED.** Android 14 runs Flutter edge-to-edge, and the social DM
  composer had no `SafeArea`, so it sat under the gesture bar. `GroupChatView`
  already had `SafeArea(top: false)` and `onSubmitted` — the social chat was
  simply never given the same treatment. Brought it in line.
  File: `lib/features/social/chat_screen.dart`.

- **A5 — FIXED.** Same edge-to-edge cause: the "Delete group" / "Leave group"
  buttons are the last children of a `Column` with only 16 px of bottom padding,
  which the gesture bar covers. Wrapped both in one `SafeArea(top: false)` and
  gave the delete button its missing top padding.
  File: `lib/features/groups/group_info_screen.dart`.
