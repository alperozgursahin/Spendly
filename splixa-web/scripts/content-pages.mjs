/**
 * React uygulamasının dışında, tamamen statik içerik sayfaları.
 *
 * Bunlar bilerek React'e bağlanmaz: App.jsx bilinmeyen bir yolu ana sayfa
 * olarak render ettiği için, /pricing'e React yüklenirse kullanıcı ana
 * sayfayı görürdü. Kendi HTML'i olan sayfalar hem bu sorunu çözer hem de
 * JavaScript çalıştırmayan her tarayıcı için %100 okunabilirdir.
 */

export const PLAY = "https://play.google.com/store/apps/details?id=net.splixa.app";

export const contentPages = [
  {
    path: "/pricing",
    title: "Splixa Pricing — What's Free and What Pro Adds",
    description:
      "Splixa's free plan covers unlimited group expenses, 2 active groups and 50 personal transactions a month, with no ads. Here is exactly what Pro unlocks.",
    h1: "Splixa pricing",
    lede:
      "Splixa is free to use and shows no advertising on any plan. This page lists the free limits exactly, so you know what you are getting before you install anything.",
    updated: "2026-09-14",
    blocks: [
      { h2: "Free" },
      {
        p: "The free plan is built around the thing people actually hit limits on in other apps: adding a shared expense. Splixa places no daily cap on that.",
      },
      {
        ul: [
          "<strong>Unlimited group expenses.</strong> No daily cap, no monthly cap, no throttling.",
          "<strong>Up to 2 active groups.</strong> A flatshare and a trip, for example.",
          "<strong>50 personal transactions per calendar month.</strong> This counts only your own private budget entries, not anything logged inside a group.",
          "<strong>No advertising.</strong> On any plan, anywhere in the app.",
          "Net Summary settlement, multi-currency groups, and all 12 languages.",
        ],
      },
      { h2: "Splixa Pro" },
      {
        p: "Pro removes both free limits — unlimited groups and unlimited personal transactions — and unlocks the features below.",
      },
      {
        ul: [
          "<strong>Receipt scanning (OCR).</strong> Photograph a receipt and Splixa reads the total and date. Every scan is shown for review before it is saved.",
          "<strong>Recurring expenses.</strong> Rent, utilities and subscriptions generated automatically on schedule.",
          "<strong>Custom categories.</strong> Your own categories with colours and emoji.",
          "<strong>Receipt attachments.</strong> Photos stored in private storage, accessible only to the group.",
          "<strong>Biometric app lock</strong> and a home screen widget for quick entry.",
          "<strong>Advanced analytics.</strong> Category heatmaps and custom date ranges.",
          "<strong>Exports.</strong> Localised PDF and CSV for any period.",
          "<strong>Manual exchange rates</strong> and shareable trip summaries.",
        ],
      },
      {
        p: "Pro is sold monthly, yearly, or as a one-time lifetime purchase. Prices are set per country and shown in your own currency inside the app, so we do not list a single figure here.",
      },
      { h2: "Frequently asked" },
      {
        faq: [
          [
            "Is Splixa really free?",
            "Yes. The free plan is not a trial and does not expire. It limits you to 2 active groups and 50 personal transactions a month, and there is no advertising on it.",
          ],
          [
            "What happens when I reach 50 personal transactions?",
            "Group expenses keep working normally — the limit only applies to entries in your own private budget. The counter resets at the start of each calendar month in your local timezone.",
          ],
          [
            "Do I need a Pro subscription to split bills?",
            "No. Splitting bills in a group, calculating who owes whom and settling up are all free, with no cap on how many expenses you add.",
          ],
          [
            "Can I cancel?",
            "Yes. Monthly and yearly plans are managed through Google Play and can be cancelled there at any time. A lifetime purchase is one payment and is not a subscription.",
          ],
        ],
      },
    ],
  },

  {
    path: "/alternatives/splitwise",
    title: "Splixa vs Splitwise — An Honest Comparison",
    description:
      "Splitwise caps free users at roughly four expenses a day and shows ads. Splixa has no daily cap, no ads, and a personal budget tracker built in. Where each one wins.",
    h1: "Splixa vs Splitwise",
    lede:
      "We make Splixa, so read this knowing that. We have kept the comparison factual and said plainly where Splitwise is still the better choice.",
    updated: "2026-09-14",
    blocks: [
      { h2: "The short version" },
      {
        p: "Pick Splitwise if most of the people you split with already use it — its network is far larger, and it runs on iOS, Android and the web. Pick Splixa if you keep running into the free daily expense cap, do not want ads, or want your personal budget and your shared expenses in the same app.",
      },
      { h2: "Side by side" },
      {
        table: {
          head: ["", "Splixa", "Splitwise"],
          rows: [
            ["Daily expense cap on free plan", "None", "Reported by users at around four entries a day"],
            ["Ads on free plan", "None", "Yes"],
            ["Free plan limits", "2 active groups, 50 personal transactions a month", "Daily expense entry cap"],
            ["Personal budget tracking", "Yes, in the same app", "No"],
            ["Multi-currency groups", "Yes, rate locked at entry", "Yes"],
            ["Receipt scanning (OCR)", "Pro", "Pro"],
            ["Platforms", "Android (iOS in development)", "iOS, Android, Web"],
            ["Languages", "12, including RTL", "Multiple"],
          ],
        },
      },
      {
        note:
          "Splitwise has not published an exact number for its free daily limit and reports from users range from two to five entries depending on account and region. Treat the figure above as the commonly reported one, not an official specification.",
      },
      { h2: "Where Splitwise is genuinely better" },
      {
        ul: [
          "<strong>It is on iOS and the web.</strong> Splixa is Android-only today; an iOS version is in development. If your group is mixed, this decides it.",
          "<strong>Everyone already has it.</strong> Getting four flatmates to install a new app is real friction that no feature list cancels out.",
          "<strong>It has a decade of history.</strong> Long-running balances, an established export path and a large support base.",
        ],
      },
      { h2: "Where Splixa is better" },
      {
        ul: [
          "<strong>No daily cap.</strong> You can log a whole week of a trip in one sitting on the free plan.",
          "<strong>No ads, on any plan.</strong> Including the free one.",
          "<strong>Your own budget lives here too.</strong> Income, expenses, monthly category breakdowns and charts sit next to the group ledger, so you are not running two apps.",
          "<strong>Locked exchange rates.</strong> The rate is fixed at the moment you record the expense, so a rate move next week never changes a balance you already settled.",
          "<strong>No bank linking.</strong> Splixa never asks for banking credentials and does not connect to bank accounts.",
        ],
      },
      { h2: "Moving from Splitwise" },
      {
        ol: [
          "Settle or note the outstanding balances in your Splitwise groups — Splixa cannot import them automatically.",
          "Export your Splitwise history to CSV from the web app if you want a record.",
          "Create the equivalent group in Splixa and add the same people.",
          "Enter the current net balances as one opening expense per person so nobody loses money in the switch.",
          "Log new expenses in Splixa from that date and leave the old group archived.",
        ],
      },
      { h2: "Frequently asked" },
      {
        faq: [
          [
            "Is there a Splitwise alternative with no daily limit?",
            "Yes. Splixa places no daily cap on adding group expenses on its free plan. Splid and Tricount also have no daily entry cap.",
          ],
          [
            "Which expense splitting apps have no ads?",
            "Splixa and Splid show no advertising. Splitwise and Tricount show ads on their free tiers.",
          ],
          [
            "Does Splixa work on iPhone?",
            "Not yet. Splixa is available on Android and an iOS version is in development.",
          ],
          [
            "Can I import my Splitwise data into Splixa?",
            "There is no automatic import. The practical approach is to settle up in Splitwise, then enter the closing balances as opening entries in Splixa.",
          ],
        ],
      },
    ],
  },

  {
    path: "/blog/best-splitwise-alternatives",
    title: "Best Splitwise Alternatives in 2026",
    description:
      "Six expense splitting apps compared on free limits, ads, offline use and platforms — including ours, and where each of the others is the better pick.",
    h1: "Best Splitwise alternatives in 2026",
    lede:
      "Most people start looking for an alternative for one reason: they hit the free daily expense cap halfway through a trip. Here is what is actually worth switching to, compared on the things that decide it.",
    updated: "2026-09-14",
    blocks: [
      {
        note:
          "Disclosure: we make Splixa, one of the apps on this list. We have kept the comparison factual and named the cases where a different app is the better answer.",
      },
      { h2: "Short answer" },
      {
        p: "If you want the simplest free switch and do not need accounts, use Splid. If you want your personal budget in the same app as your shared expenses, that is what we built Splixa for. If half your group is on iPhone and half on Android and you need the web too, staying on Splitwise is a defensible choice.",
      },
      { h2: "Compared" },
      {
        table: {
          head: ["App", "Best for", "Free plan limit", "Ads", "Personal budget", "Platforms"],
          rows: [
            ["Splixa", "Splitting plus your own budget", "2 groups, 50 personal tx/month", "No", "Yes", "Android"],
            ["Splitwise", "The largest user network", "~4 expenses a day", "Yes", "No", "iOS, Android, Web"],
            ["Splid", "Offline trips, no sign-up", "None", "No", "No", "iOS, Android"],
            ["Tricount", "Travel groups", "None", "Yes", "No", "iOS, Android, Web"],
            ["SplitMyExpenses", "Web-first, Splitwise import", "None", "No", "No", "Web"],
            ["Spliit", "Self-hosting, open source", "None", "No", "No", "Web"],
          ],
        },
      },
      { h2: "1. Splid — the easiest switch" },
      {
        p: "Splid needs no account at all and works fully offline, which makes it the lowest-friction option for a one-off trip: you share a code, everyone joins, and it handles more than 150 currencies. There is no personal budgeting and no real-time sync unless you go online, and exporting to Excel is a paid extra. If you only split costs and never track your own spending, this is the honest recommendation.",
      },
      { h2: "2. Splixa — splitting and budgeting in one app" },
      {
        p: "This is ours. The free plan has no daily cap on group expenses and no ads; the limits are 2 active groups and 50 personal transactions a month. What makes it different from everything else on this list is that your own budget lives in the same app — income, expenses, monthly category breakdowns and charts sit next to the group ledger, so you are not running a splitting app and a budgeting app side by side. Multi-currency groups lock the exchange rate at the moment of entry. Android only for now, with iOS in development, and that is the main reason to pick something else.",
      },
      { h2: "3. Tricount — long-standing travel option" },
      {
        p: "Tricount has been around a long time and handles trip groups well, with a web version that helps when someone in the group refuses to install anything. It shows ads on the free tier and does not do personal budgeting.",
      },
      { h2: "4. SplitMyExpenses — web-first with a Splitwise import" },
      {
        p: "Runs in the browser rather than as an app, and can import an existing Splitwise ledger, which is the single most useful thing on this list if you have years of history you do not want to lose. No mobile app.",
      },
      { h2: "5. Spliit — open source and self-hostable" },
      {
        p: "Free and open source, and you can run it on your own server if you would rather not hand your expense history to anyone. That also means you maintain it. Web only.",
      },
      { h2: "6. Venmo, PayPal and Revolut — not really alternatives" },
      {
        p: "These move money but do not keep a shared ledger. They are what you use to settle after a splitting app has worked out who owes whom, not a replacement for one.",
      },
      { h2: "How to switch without losing money" },
      {
        ol: [
          "Settle up in your current app, or write down each person's net balance.",
          "Export your history to CSV if the app offers it.",
          "Recreate the group in the new app with the same members.",
          "Enter each person's closing balance as an opening entry.",
          "Agree a switch date with the group so expenses do not get logged in two places.",
        ],
      },
      { h2: "Frequently asked" },
      {
        faq: [
          [
            "Is there a Splitwise alternative with no daily limit?",
            "Yes — Splixa, Splid, Tricount, SplitMyExpenses and Spliit all let you add expenses without a daily cap on their free tiers.",
          ],
          [
            "Which expense splitting app works offline?",
            "Splid is the strongest offline option: it needs no account and works entirely without a connection, syncing later via a code.",
          ],
          [
            "Which splitting app also tracks my personal budget?",
            "Splixa is the one on this list that does both in a single app. The others are shared-ledger tools only.",
          ],
          [
            "Can I export my Splitwise data?",
            "Yes, from the Splitwise web app you can export a group to CSV. SplitMyExpenses can import that file directly.",
          ],
        ],
      },
    ],
  },

  {
    path: "/blog/splitwise-daily-limit",
    title: "Splitwise Daily Limit — Why You Can't Add an Expense",
    description:
      "Splitwise caps free accounts at a small number of expense entries a day. What the limit is, why it appears, and the three ways around it.",
    h1: "Splitwise's daily limit, and what to do about it",
    lede:
      "You are halfway through logging a weekend away and Splitwise stops accepting entries. Nothing is broken — you have hit the free plan's daily cap.",
    updated: "2026-09-14",
    blocks: [
      { h2: "What the limit actually is" },
      {
        p: "Splitwise restricts how many expenses a free account can add per day. The company has not published an exact figure, and reports from users put it at roughly four entries a day, with some accounts seeing as few as two and others up to five. The counter resets the following day.",
      },
      {
        p: "It is not a bug and it is not tied to a specific group — it applies to your account as a whole, which is why it tends to bite hardest on the day you are catching up on a trip.",
      },
      { h2: "Your three options" },
      {
        ol: [
          "<strong>Wait it out.</strong> The cap resets daily, so if you are not in a hurry you can log the rest tomorrow. Combining several small expenses into one entry also stretches the allowance.",
          "<strong>Pay for Splitwise Pro.</strong> This removes the cap and the ads. It is a fair option if the rest of your group is already on Splitwise and switching is not realistic.",
          "<strong>Switch to an app without a daily cap.</strong> Splid, Tricount and Splixa all let you add expenses freely on their free tiers.",
        ],
      },
      { h2: "If you switch" },
      {
        p: "Splixa is ours, so weigh that accordingly: the free plan has no daily cap on group expenses and no ads, with limits of 2 active groups and 50 personal transactions a month. It also keeps your personal budget in the same app as your shared expenses, which is the part that does not exist in the others. It is Android-only today, so if your group is on iPhone, Splid or Tricount are the better answers.",
      },
      {
        p: "Whichever you pick, settle up in Splitwise first or note everyone's net balance, then enter those as opening entries in the new app so nobody loses track of what they are owed.",
      },
      { h2: "Frequently asked" },
      {
        faq: [
          [
            "How many expenses can I add per day on Splitwise for free?",
            "Splitwise does not publish the number. Users commonly report around four entries a day, with some accounts seeing between two and five.",
          ],
          [
            "Does the Splitwise limit reset?",
            "Yes, it resets daily. If you have hit it, you can add more the next day.",
          ],
          [
            "Is there a free expense splitting app with no daily limit?",
            "Yes. Splid, Tricount and Splixa all allow unlimited expense entries on their free plans.",
          ],
        ],
      },
    ],
  },
];
