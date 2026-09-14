# Measuring the onboarding funnel (D1)

Answers: *what share of installs finish onboarding, what share drop out during
it, and what share reach login or sign-up.*

The Firebase console's **Realtime** screen cannot answer this. It shows a
rolling 30-minute window of raw events with no notion of a user moving from one
step to the next. Funnels live in **GA4**, in the Explore section, and they read
from the same Firebase Analytics stream — the events are already being
collected, they just are not being assembled into a funnel yet.

---

## 1. The events Splixa already emits

All of these ship today from `lib/core/analytics_service.dart`:

| Event | Parameters | Fires when |
|---|---|---|
| `first_open` | — | Automatic (Firebase). First launch after install. |
| `onboarding_start` | `variant`, `total_steps` | Onboarding screen mounts. |
| `onboarding_step_viewed` | `step`, `step_name`, `variant`, `total_steps` | Each slide is shown. |
| `onboarding_interrupted` | `step`, `total_steps`, `variant`, `duration_ms` | App is backgrounded *during* onboarding. This is the abandonment signal — it records exactly which slide lost them. |
| `onboarding_complete` | `completion_method`, `variant`, `total_steps`, `duration_ms` | Onboarding is finished or skipped. `completion_method` separates the two. |
| `sign_up` | `method` | Account created. |
| `login` | `method` | Signed in. |
| `login_attempt` / `login_failed` | `method`, (`reason`) | Auth attempted / failed. |

Two user properties are set alongside them — `onboarding_variant` and
`paywall_variant` — so every funnel below can be split by A/B arm without any
extra work.

---

## 2. Do this first, or the funnel will be useless

**Register the custom parameters as custom dimensions.** GA4 discards
event-parameter values for reporting unless the parameter is registered, and
**registration is not retroactive** — you only get data from the moment you
register onward. Nothing you have collected so far is broken up by step until
this is done.

GA4 → **Admin** → **Custom definitions** → **Create custom dimension**, scope
*Event*, once per parameter:

- `step`
- `step_name`
- `completion_method`
- `variant`
- `method`

Do this before anything else in this document. There is a 50-dimension limit;
five is nothing.

Standard reports also lag roughly 24 hours. **DebugView** (Admin → DebugView,
with the app running a debug build) is the live one, and is how you confirm an
event fires at all before you go looking for it in a report.

---

## 3. The funnel

GA4 → **Explore** → **Funnel exploration**. Set *Open funnel* off (closed
funnel: users must pass through the steps in order).

Steps:

1. `first_open`
2. `onboarding_start`
3. `onboarding_complete`
4. `sign_up` **or** `login` — add both as conditions in one step, joined with OR,
   so a returning user who signs in counts the same as a new one who registers

That gives, directly:

- **install → onboarding started** — how many people who opened the app for the
  first time actually reached the intro. A gap here is a launch or routing
  problem, not a content problem.
- **onboarding started → completed** — the number the question is really about.
- **completed → account** — how many finished the intro and then would not hand
  over an email.

Tick **Show elapsed time** to see how long each step takes; a step people spend
a long time on is usually a step they are re-reading, not enjoying.

### Per-slide drop-off

Once `step` is registered, replace step 3 above with four separate steps, each
`onboarding_step_viewed` filtered to `step` = 1, 2, 3, 4. The funnel then shows
exactly which slide loses people. This is the version worth keeping as a saved
exploration.

### Who got bored and left

`onboarding_interrupted` is purpose-built for this and needs no funnel: GA4 →
**Reports** → **Engagement** → **Events** → `onboarding_interrupted`, broken down
by `step`. It fires when the app is backgrounded mid-onboarding, so the `step`
distribution *is* the abandonment curve. Compare its total against
`onboarding_start` for a straight abandonment rate.

Note it fires on every backgrounding, so one user who checks a message twice
produces two events; use *Total users* rather than *Event count* when you want a
people number.

### Split by A/B arm

Add **Breakdown** → `onboarding_variant` (the user property) to any of the
above. That is the comparison that tells you whether a redesign actually moved
completion, rather than whether the week was busier.

---

## 4. What the numbers should look like

Rough industry reference points, useful only as a smell test:

- A completion rate under ~50% means the intro is too long or asks for something
  too early.
- Most abandonment concentrates on one slide. If it is spread evenly, the
  problem is length, not content.
- `first_open` → `onboarding_start` should be near 100%. Anything else is a bug.

---

## 5. Keep it

Save the exploration (top right → Save) and name it. Unsaved GA4 explorations
are per-user and vanish; a saved one can be shared with anyone on the property
and is what you compare against after the next onboarding change.
