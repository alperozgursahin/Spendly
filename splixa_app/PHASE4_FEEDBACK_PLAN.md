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
- [x] **A6. 7-day trial not shown on the paywall** although the Play Console
  base plan has it. Verify what the store actually reports; the badge is gated
  on an exact `P1W` free phase.
- [~] **A7. Recurring expenses cannot be tested by the owner** (weekly/monthly
  only). ASSISTANT must verify generation server-side. Also still open: the
  cron run logged `Recurring generation failed` with an empty error code; the
  widened logging needs deploying and the next run checking.

## B. Product changes — small

- [x] **B1. Custom categories: drop colour and emoji.** Name only — users can
  type an emoji into the name. Simplifies the form and the model.
- [x] **B2. PRO / STANDARD badge on the dashboard header,** to the right of the
  Splixa logo and wordmark.
- [x] **B3. Group "Add expense" → "What for?" needs the same default category
  set as the home screen,** plus "Other". Custom categories stay Pro-only.
  This is also why the trip summary shows "uncategorized".
- [x] **B4. Invite-to-group member list:** show avatars; members already in the
  group appear disabled with an "already in group" label instead of an enabled
  button.
- [x] **B5. Other user's profile should show** bio, avatar, shared groups, and
  how many months they have been on Splixa.

## C. Product changes — larger

- [x] **C1. Trip summary card is too plain and not useful.** Needs: member
  names, who owes whom and how much *right now*, payer + category + amount per
  expense, and a clear "everyone is settled up" state when there is no debt.
  Must stay simple enough to drop into a WhatsApp group. Keep it privacy-safe.
- [x] **C2. Statistics screen needs 1–2 more views** — a bar chart plus one
  other. Deliberately not more.
- [x] **C3. Paywall redesign.** Owner finds it unprofessional. Research what
  strong subscription paywalls do (Splitwise and peers) before rewriting.
- [x] **C4. Onboarding redesign.** Current animation is placeholder-grade.
  Wants something striking, with real animation.

## D. Measurement question (no code)

- [x] **D1. Explain how to answer:** what share of installs finish onboarding,
  what share drop out during it, what share reach login/signup. The Firebase
  realtime screen does not show this; needs a GA4 funnel exploration on the
  events Phase 1 already emits (`onboarding_start`, `onboarding_step_viewed`,
  `onboarding_complete`, `login`, `first_open`).

## F. Found during the pre-push repo audit

- [ ] **F1. `create-load-test-users` is still ACTIVE in production** with
  `verify_jwt = false`. The guard itself is sound — it demands an
  `x-load-test-token` header, refuses outright unless `LOAD_TEST_ADMIN_TOKEN` is
  at least 32 characters, and compares in constant time — but it is a function
  whose whole job is minting `auth.users` rows, and it exists for load testing,
  not for the product. Delete the deployed function before the public launch and
  redeploy it only when a load test is actually being run.

- [x] **F2. `anon` can execute 16 `SECURITY DEFINER` functions in `public`.**
  Most are harmless — they call `auth.uid()` internally, which is null for an
  anonymous caller, so they return nothing. Three are not, because they take the
  identity to check *as a parameter* and only default it to `auth.uid()`:
  `can_view_profile(p_profile_id, p_viewer_id)`,
  `is_group_creator(p_group_id, p_user_id)` and
  `is_group_member(p_group_id, p_user_id)`. An unauthenticated `POST` to
  `/rest/v1/rpc/can_view_profile` with two chosen UUIDs answers "are these two
  people friends, or in a group together" about users the caller is neither of.
  It needs real UUIDs to be useful, so it is an oracle rather than a dump, but
  it is one anyone can now find by reading the public repo. Cheapest correct
  fix: `revoke execute ... from anon` across `public` — the app is always
  authenticated, so nothing breaks. These three are RLS helpers, so the
  parameter itself cannot simply be dropped without auditing every policy that
  passes it; do that as a follow-up, not in the same change.
- [x] **F3. `handle_splixa_user_signup()` has no `search_path` set.** It is the
  `SECURITY DEFINER` trigger that runs on every signup, so it executes as its
  owner. Exploiting a mutable `search_path` requires CREATE on a schema in the
  path, which `anon`/`authenticated` do not have, so this is hardening rather
  than an open door — but it is a one-line fix (`set search_path = ''` plus
  schema-qualifying the calls) and every other function in the project already
  does it.
- [ ] **F4. Leaked-password protection is off.** Supabase can check new
  passwords against HaveIBeenPwned. One toggle in Auth settings.

  Not findings: `auth_login_rate_limits` and `receipt_storage_deletion_queue`
  are flagged as "RLS enabled, no policy". That is the intended posture — RLS on
  with no policy denies `anon` and `authenticated` outright and leaves only
  `service_role`, which bypasses RLS, able to touch them.

## E. Carried over from Phase 4, still open

- [x] **E1. Native Android widget strings are English-only** for all 12 shipped
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

- **CRITICAL, found during the pre-push audit and fixed — `public.profiles` was
  world-readable.** The table carried two permissive SELECT policies granted to
  the PUBLIC pseudo-role with `using (true)`
  ("Public profiles are viewable by everyone" and `profiles_select`). Permissive
  policies are OR-ed, so those two overrode every narrower policy on the table,
  and PUBLIC includes `anon` — whose key ships inside the published APK.
  Measured, not assumed: `set local role anon; select count(*) from
  public.profiles` inside a rolled-back transaction returned **56 rows, e-mail
  column included**. Fixed in migration `20260914194049`: both policies dropped
  along with their duplicate `{public}` write counterparts, and, since username
  search and group member lists legitimately need to read strangers' rows, the
  `email` column was removed from the API surface with a revoke-then-grant
  rather than narrowing rows and breaking those features. Re-measured against
  production after applying: anon `DENIED`, authenticated still reads the app's
  columns (56), authenticated `email` `DENIED`, zero `{public}` policies left.
  `currentUserProfileProvider` was the only caller doing `select *` on profiles
  and now lists its columns.

- **F2/F3 — FIXED in migration `20260914194333`.** EXECUTE revoked from `anon`
  *and* `public` on all 17 exposed functions — revoking from `anon` alone would
  not have worked, because 11 of them also carried a PUBLIC grant and privileges
  are additive. Dry-run in a rolled-back transaction first: anon denied on
  `can_view_profile`, while `is_group_member`, `get_auth_group_ids` and selects
  against the RLS-protected ledger tables all still succeeded as
  `authenticated`. `handle_splixa_user_signup` now has `search_path = ''`.
  Supabase's security advisor afterwards: the entire
  `anon_security_definer_function_executable` category (16 findings) and
  `function_search_path_mutable` are gone. What remains is
  `authenticated_security_definer_function_executable` (31), which is the app's
  own RPC layer and is by design, plus F4.

- **Housekeeping:** `supabase/migrations/20260914000100_close_public_profile_exposure.sql`
  is a leftover from before the migration was applied and got its real version
  number. Delete it — the same change is recorded at `20260914194049`. It is
  idempotent, so pushing it by accident does nothing, but it should not stay.

- **A6 — FIXED.** The badge was gated three ways at once: only
  `PackageType.monthly` was considered, only `defaultOption` was read (Play
  exposes a trial as its own entry in `subscriptionOptions` and only sometimes
  promotes it to the default), and the period had to equal `P1W` exactly, so the
  same seven days entered as `P7D` did not count. `_freeTrialPeriod` now scans
  every option on every package and returns the real ISO-8601 period; the badge
  and the CTA render the actual length instead of a hard-coded week.

- **B1 — DONE.** Colour palette and emoji box removed from the editor and from
  `CustomCategory`. Migration `20260914194938` relaxes NOT NULL and defaults the
  two columns rather than dropping them, so existing rows keep their values.

- **B2 — DONE.** `_MembershipBadge` beside the wordmark; PRO opens Pro tools,
  STANDARD opens the paywall, so the badge is a route rather than decoration.

- **B3 — DONE.** Group expenses carried no category at all, which is why every
  trip summary read "uncategorized". `kPredefinedCategories` now lives in
  `app_strings.dart` and both screens read it, so they cannot drift again. The
  group sheet uses `kPredefinedExpenseCategories` — the same list minus `Maaş`,
  since a shared expense is never a salary — plus the user's own categories.

- **B4 — DONE.** Avatars come through `getAcceptedFriends` (which now selects
  `avatar_url`), and existing members render disabled with "Already in group"
  rather than being hidden, so the inviter can tell the difference between
  "already added" and "forgot to add".

- **B5 — DONE.** Avatar, bio, months-on-Splixa and the *names* of shared groups,
  each row tapping through to the group. Backed by migration `20260914195219`:
  `profiles.created_at` backfilled from `auth.users` (all 56 rows verified to
  match) and `shared_groups_with_v1`, which reads the viewer from `auth.uid()`
  rather than taking it as an argument — deliberately not the caller-supplied
  identity shape that had to be closed on `can_view_profile`.

- **C1 — DONE.** The card now leads with settle-up state: either "Everyone is
  settled up" or the actual "A → B, amount" list, computed by greedy debt
  simplification over `groupBalancesProvider` (largest debtor against largest
  creditor; never more than n-1 payments). Under it, up to five recent expenses
  as description / payer · category / amount, then "+N more". Names resolve
  through group members, with "You" for the viewer.

- **C2 — DONE.** A monthly-spend bar chart plus three stat tiles (total, daily
  average, largest single expense). Single series, so one hue and no legend; the
  tallest month is the only labelled bar. Every month in the window is seeded at
  zero so a quiet month shows as a gap rather than silently compressing the axis.

- **C3 — DONE (needs a visual pass).** Researched first, then changed the three
  things the research is clearest about: the "best value" badge is now a computed
  **SAVE n%** derived from the two live store prices; the CTA names the trial
  ("Start my 7-day free trial") instead of a generic continue; and an honest
  trust row sits under it — cancel anytime, no charge today, secure store
  payment. Deliberately **no** star ratings or install counts: invented social
  proof makes a paywall less trustworthy, not more, and the real numbers are not
  ours to quote yet.

- **C4 — DONE (needs a visual pass).** The complaint was motion, not structure,
  so the structure stayed. Each page now reveals in stages (art, eyebrow, title,
  body, chips, ~60 ms apart), the illustration parallaxes against the swipe at a
  third of finger speed and scales down as it leaves, and the dots became a
  progress bar that starts a fifth filled — the endowed-progress effect. All of
  it collapses to the end state when the platform asks for reduced motion.

- **D1 — ANSWERED** in `ONBOARDING_FUNNEL_GUIDE.md`. Short version: Realtime
  cannot do this, GA4 → Explore → Funnel exploration can, and the events are
  already being collected. The one thing that must happen first is registering
  `step`, `step_name`, `completion_method`, `variant` and `method` as custom
  dimensions — GA4 drops parameter values for reporting until you do, and
  registration is **not** retroactive. `onboarding_interrupted` already carries
  the step it died on, so the abandonment curve needs no funnel at all.

- **E1 — DONE.** `res/values-{tr,es,pt,de,fr,it,nl,ru,ar,hi,in}/strings.xml` for
  the three widget strings. Indonesian uses Android's legacy `in` qualifier, not
  `id`. Apostrophes are backslash-escaped; an unescaped one fails the build.

### Still open after this pass

- **A7 (second half)** — the cron `Recurring generation failed` with an empty
  error code. Generation itself is proven; the widened JSON logging needs
  deploying and the next scheduled run inspecting.
- **F1** — delete the deployed `create-load-test-users` function.
- **F4** — turn on leaked-password protection in Supabase Auth settings.
- **E2 / E3** — the iOS widget target needs macOS, and native-speaker review of
  the 10 machine-assisted locales is a people task, not a code one.
