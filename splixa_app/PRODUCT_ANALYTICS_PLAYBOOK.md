# Splixa Product Analytics & Experimentation Playbook

## Measurement stack

- **Firebase Analytics / GA4:** screen flow, acquisition, retention, product funnels, and key events.
- **Firebase Remote Config + A/B Testing:** stable experiment assignment by Firebase installation ID.
- **RevenueCat:** subscription state and store-side revenue truth; Firebase receives the matching funnel events.
- **BigQuery export:** raw event-level analysis, cohorting, and durable dashboards.
- **Google Ads link:** campaign attribution, audiences, and key-event optimization.

The app sends pseudonymous Supabase user IDs after authentication. It never
sends email addresses, usernames, expense descriptions, group names, receipt
content, transaction amounts, or debt amounts to Firebase Analytics.

## Event catalog

| Event | Purpose | Important parameters |
| --- | --- | --- |
| `first_open`, `app_open`, `session_start` | Install, launch, and retention baseline | Firebase automatic |
| `screen_view` | Navigation and screen drop-off | Stable route name; never a user/group ID |
| `onboarding_start` | Funnel entry and experiment activation | `variant`, `total_steps` |
| `onboarding_step_viewed` | Step-to-step conversion | `step`, `step_name`, `variant`, `total_steps` |
| `onboarding_interrupted` | App backgrounded mid-flow | `step`, `variant`, `duration_ms` |
| `onboarding_complete` | Completion or skip | `completion_method`, `variant`, `duration_ms` |
| `sign_up` | Successful account creation | `method` |
| `login_attempt` | Authentication funnel entry | `method` |
| `login` | Successful authentication | `method` |
| `login_failed` | Auth friction without error text or PII | `method`, `reason_code` |
| `profile_setup_complete` | Google profile setup completion | `source` |
| `group_created` | First collaborative value moment | none |
| `expense_added` | Core habit event | `scope` (`personal`/`group`) |
| `ledger_action_completed` | Approval/payment lifecycle progress | `action` |
| `paywall_view` | Monetization funnel entry | `source`, `variant` |
| `paywall_package_selected` | Package intent | `source`, `variant`, `package_id`, `product_id` |
| `purchase_attempt` | Checkout opened | package/product context |
| `purchase_success` | RevenueCat purchase success | package/product, store currency/value |
| `purchase_ended` | Cancelled or failed checkout | `outcome` |
| `subscription_started` | First subscription activation | package/product context |
| `paywall_dismissed` | Paywall exit and dwell time | `purchase_completed`, `duration_ms` |

User properties available for segmentation:

- `onboarding_variant`
- `paywall_variant`
- `app_language`
- `subscription_tier` (`free` / `pro`)

## Remote Config parameters

Create these exact parameters in Firebase Remote Config:

| Key | Default | Supported values | Behavior |
| --- | --- | --- | --- |
| `onboarding_flow_variant` | `control` | `control`, `focused` | Four-step baseline vs. three-step focused flow |
| `paywall_layout_variant` | `control` | `control`, `plans_first` | Benefits-first baseline vs. plans-first layout |

Unknown or unavailable values fail closed to `control`. The onboarding value
is frozen when the flow opens, so a background Remote Config refresh cannot
change the number of pages during a session.

Recommended first onboarding experiment:

1. Firebase Console → A/B Testing → Create experiment → Remote Config.
2. Parameter: `onboarding_flow_variant`.
3. Baseline: `control`; variant: `focused`; start with a 50/50 split.
4. Activation event: `onboarding_start`.
5. Primary goal: `onboarding_complete`.
6. Secondary metrics: `sign_up`, `group_created`, `expense_added`, and day 2–3 retention.
7. Do not change copy or targeting while the experiment is running.

For the paywall experiment, use `paywall_layout_variant`, activate on
`paywall_view`, and optimize for `purchase_success`. Evaluate cancellation,
dismissal, and seven-day retention as guardrails—not conversion alone.

## GA4 reports to create

Create these Explorations in the linked GA4 property:

1. **Acquisition to activation:** `first_open` → `onboarding_start` →
   `onboarding_complete` → `sign_up`/`login` → `group_created` or
   `expense_added`.
2. **Onboarding drop-off:** one step per `step_name`, broken down by
   `onboarding_variant`, language, country, platform, and app version.
3. **Monetization:** `paywall_view` → `paywall_package_selected` →
   `purchase_attempt` → `purchase_success`, broken down by `source`, variant,
   package, country, and acquisition campaign.
4. **Habit and retention:** users with 1, 3, and 5 `expense_added` events;
   compare day 1, day 7, and day 30 retention.
5. **Reliability guardrails:** `login_failed`, `purchase_ended`, and
   `onboarding_interrupted` rates by app version and device model.

Mark `onboarding_complete`, `sign_up`, `group_created`, `expense_added`, and
`purchase_success` as GA4 key events. Register event-scoped custom dimensions
for `variant`, `source`, `step_name`, `completion_method`, `reason_code`,
`scope`, `action`, and `outcome` before relying on standard GA4 reports.

## Console setup before paid acquisition

- Firebase Console → Project settings → Integrations → enable the GA4 link.
- Link the GA4 property to Google Ads and import only intentional key events.
- Firebase Console → Project settings → Integrations → BigQuery → link Google
  Analytics. Choose the data region deliberately; it cannot be changed in
  place later.
- Use Analytics DebugView on a debug build before publishing:
  `adb shell setprop debug.firebase.analytics.app net.splixa.app.debug`
- Exclude internal/test devices from production reporting and RevenueCat test
  transactions from commercial decisions.
- Before running personalized advertising in regulated regions, implement and
  document a compliant consent-management flow. Analytics collection and Ads
  personalization must follow the user’s consent state and the current Google
  and store policies.

BigQuery export and Google Ads linking are console-side operations; no service
account key or advertising credential belongs in the Flutter app.
