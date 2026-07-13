import React, { useState } from "react";
import {
  Wallet,
  Menu,
  X,
  ArrowRight,
  Check,
  Flame,
  PieChart,
  Crown,
  Sparkles,
  Play,
  Star,
  Shield,
  ChevronDown,
  Send,
} from "lucide-react";

/* ---------------------------------------------------------
   Translations
--------------------------------------------------------- */

const translations = {
  en: {
    nav: {
      features: "Features",
      pro: "Pro",
      faq: "FAQ",
      contact: "Contact",
      signIn: "Sign in",
      getApp: "Get Spendly",
    },
    hero: {
      eyebrow: "SOCIAL FINANCE, SIMPLIFIED",
      titleLine1: "Split the bill.",
      titleLine2: "Not the friendship.",
      desc: "Spendly tracks shared expenses for trips, roommates and squads. It tells you exactly who owes whom, so no one has to be the one who brings up money.",
      ctaSecondary: "See how it works",
      stats: [
        ["50K+", "balances settled"],
        ["4.8", "average rating"],
        ["120+", "countries"],
      ],
    },
    how: {
      eyebrow: "THE FLOW",
      title: "From chaos to settled in three steps",
      steps: [
        { title: "Start a group", desc: "Roommates, a trip, a shared apartment. Name it and add the people in." },
        { title: "Log an expense", desc: "Enter the total and pick who is in on it. Spendly splits it evenly or however you choose." },
        { title: "Settle in one tap", desc: "Everyone sees the same Net Summary. Pay it off, mark it settled and move on with your night." },
      ],
    },
    features: {
      eyebrow: "THE SELLING POINTS",
      title: "Everything money with friends should feel like",
      subtitle: "Built for trips, roommates and squads. Not spreadsheets.",
      items: [
        {
          eyebrow: "GROUP SPLITTING",
          title: "Add friends. Split fair. Done.",
          desc: "Create a group for any trip or apartment, log a shared expense and pick who is in on it. Spendly handles the math instantly.",
          bullets: [
            "Create a group in seconds for any trip or apartment",
            "Add shared expenses and choose exactly who is included",
            "Get an exact Net Summary of who owes whom, automatically",
          ],
        },
        {
          eyebrow: "VISUAL ANALYTICS",
          title: "See your money, not just your statements",
          desc: "Monthly category distribution charts turn a wall of transactions into a picture you actually understand at a glance.",
          bullets: [
            "Monthly category breakdowns show exactly where money goes",
            "Interactive charts make patterns obvious immediately",
            "Track spending down to the exact transaction",
          ],
        },
        {
          eyebrow: "SPENDING HEATMAP",
          title: "A full year of habits, one glance away",
          desc: "A GitHub style calendar grid of every day you spent. Streaks and spikes jump out instead of hiding in a list.",
          bullets: [
            "A full year of activity styled like a contribution graph",
            "Spot high spend days and streaks instantly",
            "Tap any day to see exactly what you spent",
          ],
        },
      ],
    },
    pro: {
      eyebrow: "SPENDLY PRO",
      title: "When two groups are not enough",
      free: {
        name: "Free",
        price: "$0",
        priceNote: "Forever, for the essentials",
        features: [
          "Track unlimited basic expenses",
          "Real-time cloud sync",
          "Core dashboard access",
          "Standard group splitting",
          "Bank-level security",
        ],
      },
      pro: {
        name: "Pro",
        price: "$4.99",
        priceNote: "per month, for serious splitters",
        features: [
          "Unlimited groups",
          "Advanced spending insights",
          "Full Spending Heatmap history",
          "Priority settle-up reminders",
          "Custom category tagging",
        ],
        cta: "Upgrade to Pro",
      },
    },
    faq: {
      eyebrow: "FAQ",
      title: "Questions, answered",
      items: [
        {
          q: "Is my financial data secure?",
          a: "Yes. Every transaction is protected with bank-level 256 bit encryption, both in transit and at rest. Spendly never stores your banking credentials on our servers, and you can revoke access at any time.",
        },
        {
          q: "How does group splitting work?",
          a: "Create a group, add the people involved and log an expense. Spendly automatically calculates a Net Summary showing exactly who owes whom.",
        },
        {
          q: "What is included in Spendly Pro?",
          a: "Pro unlocks unlimited groups, your full Spending Heatmap history, advanced category insights and priority settle-up reminders, all for $4.99 per month.",
        },
        {
          q: "Is Spendly free to use?",
          a: "Yes. Core splitting, the dashboard and basic analytics are free forever. Upgrade to Pro whenever you want deeper insights or more than two active groups.",
        },
        {
          q: "Can I use Spendly while traveling internationally?",
          a: "Absolutely. Spendly supports multiple currencies within a single group, so shared travel expenses convert and split cleanly no matter where the trip takes you.",
        },
      ],
    },
    contact: {
      eyebrow: "CONTACT",
      title: "Got a question? Just ask",
      desc: "Questions, feedback or partnership ideas. Our team would love to hear from you.",
      nameLabel: "Full name",
      namePlaceholder: "Your name",
      emailLabel: "Email",
      emailPlaceholder: "you@example.com",
      messageLabel: "Message",
      messagePlaceholder: "How can we help?",
      send: "Send message",
      sentMessage: "Thanks for reaching out! We will get back to you shortly.",
    },
    finalCta: {
      title: "Ready to split smarter?",
      desc: "Download Spendly and settle your first group before the check even arrives.",
      ratingText: "average rating from early users",
    },
    footer: {
      tagline: "Split fair, stay friends.",
      security: "Bank-level encryption",
    },
  },

  tr: {
    nav: {
      features: "Özellikler",
      pro: "Pro",
      faq: "SSS",
      contact: "İletişim",
      signIn: "Giriş yap",
      getApp: "Spendly'i indir",
    },
    hero: {
      eyebrow: "SOSYAL FİNANSIN BASİTİ",
      titleLine1: "Hesabı böl.",
      titleLine2: "Dostluğu bölme.",
      desc: "Spendly; gezilerde, ev arkadaşlarında ve arkadaş gruplarında ortak harcamaları takip eder. Kimin kime ne kadar borçlu olduğunu anında söyler, parayı konu etmek artık kimseye kalmaz.",
      ctaSecondary: "Nasıl çalıştığını gör",
      stats: [
        ["50K+", "bakiye kapatıldı"],
        ["4.8", "ortalama puan"],
        ["120+", "ülke"],
      ],
    },
    how: {
      eyebrow: "AKIŞ",
      title: "Üç adımda kaostan ödemeye",
      steps: [
        { title: "Bir grup oluştur", desc: "Ev arkadaşları, bir gezi, paylaşılan bir daire. Adını ver, kişileri ekle." },
        { title: "Bir harcama gir", desc: "Toplam tutarı gir, kimin dahil olduğunu seç. Spendly eşit ya da istediğin şekilde böler." },
        { title: "Tek dokunuşla kapat", desc: "Herkes aynı Net Özet'i görür. Öde, kapalı olarak işaretle, gecene devam et." },
      ],
    },
    features: {
      eyebrow: "ÖNE ÇIKAN ÖZELLİKLER",
      title: "Arkadaşlarla para işi böyle hissettirmeli",
      subtitle: "Geziler, ev arkadaşları ve arkadaş grupları için tasarlandı. Excel tabloları için değil.",
      items: [
        {
          eyebrow: "GRUP BÖLÜŞÜMÜ",
          title: "Arkadaş ekle. Adil böl. Bitti.",
          desc: "Herhangi bir gezi ya da daire için grup oluştur, ortak bir harcama gir ve kimin dahil olacağını seç. Spendly hesabı anında yapar.",
          bullets: [
            "Herhangi bir gezi ya da daire için saniyeler içinde grup oluştur",
            "Ortak harcamaları ekle, kimin dahil olacağını sen seç",
            "Kimin kime ne kadar borçlu olduğunu gösteren tam bir Net Özet al",
          ],
        },
        {
          eyebrow: "GÖRSEL ANALİZ",
          title: "Sadece ekstreni değil, paranı gör",
          desc: "Aylık kategori dağılımı grafikleri, bir yığın işlemi tek bakışta anlayacağın bir resme dönüştürür.",
          bullets: [
            "Aylık kategori dağılımları paranın nereye gittiğini gösterir",
            "Etkileşimli grafikler örüntüleri hemen ortaya çıkarır",
            "Harcamaları tek işlem düzeyinde takip et",
          ],
        },
        {
          eyebrow: "HARCAMA ISI HARİTASI",
          title: "Bir yıllık alışkanlık, tek bakışta",
          desc: "GitHub tarzı bir takvim ızgarasında geçirdiğin her gün. Ani artışlar ve seriler listede kaybolmak yerine hemen göze çarpar.",
          bullets: [
            "Katkı grafiği tarzında tam yıllık aktivite görünümü",
            "Yoğun harcama günlerini ve serileri anında fark et",
            "Herhangi bir güne dokun, tam olarak ne harcadığını gör",
          ],
        },
      ],
    },
    pro: {
      eyebrow: "SPENDLY PRO",
      title: "İki grup yetmediğinde",
      free: {
        name: "Ücretsiz",
        price: "0₺",
        priceNote: "Temel özellikler için, süresiz",
        features: [
          "Sınırsız temel harcama takibi",
          "Gerçek zamanlı bulut senkronizasyonu",
          "Temel panoya tam erişim",
          "Standart grup bölüşümü",
          "Banka düzeyinde güvenlik",
        ],
      },
      pro: {
        name: "Pro",
        price: "$4.99",
        priceNote: "aylık, ciddi bölüşücüler için",
        features: [
          "Sınırsız grup",
          "Gelişmiş harcama analizleri",
          "Tam Harcama Isı Haritası geçmişi",
          "Öncelikli ödeme hatırlatmaları",
          "Özel kategori etiketleme",
        ],
        cta: "Pro'ya yükselt",
      },
    },
    faq: {
      eyebrow: "SSS",
      title: "Sorular, cevaplandı",
      items: [
        {
          q: "Finansal verilerim güvende mi?",
          a: "Evet. Her işlem, aktarım sırasında ve saklanırken banka düzeyinde 256 bit şifrelemeyle korunur. Spendly, banka bilgilerini sunucularında hiçbir zaman saklamaz ve erişimi istediğin an kaldırabilirsin.",
        },
        {
          q: "Grup bölüşümü nasıl çalışır?",
          a: "Bir grup oluştur, dahil olan kişileri ekle ve bir harcama gir. Spendly, kimin kime ne kadar borçlu olduğunu gösteren bir Net Özet'i otomatik olarak hesaplar.",
        },
        {
          q: "Spendly Pro'ya neler dahil?",
          a: "Pro; sınırsız grup, tam Harcama Isı Haritası geçmişi, gelişmiş kategori analizleri ve öncelikli ödeme hatırlatmalarını aylık $4.99 karşılığında sunar.",
        },
        {
          q: "Spendly ücretsiz mi?",
          a: "Evet. Temel bölüşüm, pano ve temel analizler süresiz ücretsizdir. Daha derin analiz ya da ikiden fazla aktif grup istediğinde Pro'ya geçebilirsin.",
        },
        {
          q: "Spendly'i yurt dışı seyahatlerde kullanabilir miyim?",
          a: "Kesinlikle. Spendly, tek bir grup içinde birden fazla para birimini destekler, böylece seyahat harcamaları nerede olursan ol sorunsuz şekilde dönüştürülür ve bölüşülür.",
        },
      ],
    },
    contact: {
      eyebrow: "İLETİŞİM",
      title: "Bir sorun mu var? Yazabilirsin",
      desc: "Sorular, geri bildirimler ya da ortaklık teklifleri için ekibimiz seni dinlemeye hazır.",
      nameLabel: "Ad Soyad",
      namePlaceholder: "Adını yaz",
      emailLabel: "E-posta",
      emailPlaceholder: "sen@ornek.com",
      messageLabel: "Mesaj",
      messagePlaceholder: "Nasıl yardımcı olabiliriz?",
      send: "Mesaj gönder",
      sentMessage: "Mesajın için teşekkürler! En kısa sürede dönüş yapacağız.",
    },
    finalCta: {
      title: "Daha akıllı bölüşmeye hazır mısın?",
      desc: "Spendly'i indir, ilk grubunu hesap gelmeden kapat.",
      ratingText: "ilk kullanıcılardan ortalama puan",
    },
    footer: {
      tagline: "Adil böl, arkadaş kal.",
      security: "Banka düzeyinde şifreleme",
    },
  },
};

const STEP_NUMBERS = ["01", "02", "03"];

const FEATURE_META = [
  { image: "/groups-ss.png", imageAlt: "Spendly group and Net Summary screen", reverse: false },
  { image: "/analytics-ss.png", imageAlt: "Spendly category distribution analytics screen", reverse: true },
  { image: "/heatmap-ss.png", imageAlt: "Spendly spending heatmap screen", reverse: false },
];

/* ---------------------------------------------------------
   Small building blocks
--------------------------------------------------------- */

function GhostGrid() {
  return (
    <div
      className="pointer-events-none absolute inset-0 opacity-[0.35]"
      style={{
        backgroundImage: "radial-gradient(circle, rgba(168,85,247,0.35) 1px, transparent 1px)",
        backgroundSize: "22px 22px",
        maskImage: "radial-gradient(ellipse 60% 50% at 50% 0%, black 40%, transparent 100%)",
        WebkitMaskImage: "radial-gradient(ellipse 60% 50% at 50% 0%, black 40%, transparent 100%)",
      }}
    />
  );
}

function SectionEyebrow({ children }) {
  return (
    <div
      className="inline-flex items-center gap-2 rounded-full border border-purple-500/30 bg-purple-500/10 px-3 py-1 text-xs font-medium tracking-wide text-purple-300"
      style={{ fontFamily: "'JetBrains Mono', monospace" }}
    >
      {children}
    </div>
  );
}

function PlayBadge({ className = "" }) {
  return (
    <button
      className={
        "group inline-flex items-center gap-3 rounded-xl bg-white px-6 py-3.5 text-slate-900 shadow-lg shadow-purple-500/10 transition-transform hover:-translate-y-0.5 active:translate-y-0 " +
        className
      }
    >
      <Play className="h-5 w-5 fill-slate-900 text-slate-900" />
      <span className="text-left leading-tight">
        <span className="block text-[10px] text-slate-500">GET IT ON</span>
        <span className="block text-sm font-semibold">Google Play</span>
      </span>
    </button>
  );
}

function LanguageToggle({ lang, setLang, className = "" }) {
  return (
    <div className={`inline-flex items-center rounded-full border border-slate-700 p-1 ${className}`}>
      {["en", "tr"].map((code) => (
        <button
          key={code}
          onClick={() => setLang(code)}
          className={`rounded-full px-3 py-1 text-xs font-semibold transition-colors ${
            lang === code ? "bg-white text-slate-900" : "text-slate-400 hover:text-white"
          }`}
        >
          {code.toUpperCase()}
        </button>
      ))}
    </div>
  );
}

/**
 * Realistic, premium phone mockup for real app screenshots.
 * Uses object-contain so the full screenshot is always visible,
 * never stretched or cropped. Swap the src for your own screenshot.
 */
function PhoneMockup({ src, alt, size = "w-[250px] sm:w-[290px]" }) {
  return (
    <div className={`relative ${size}`}>
      <div
        className="absolute inset-0 -z-10 rounded-full bg-purple-600/30 blur-3xl"
        style={{ transform: "scale(1.15)" }}
      />
      <div
        className="relative border border-slate-700/60 bg-gradient-to-b from-slate-800 to-slate-950 shadow-2xl shadow-purple-500/20"
        style={{ borderRadius: "2.75rem", padding: "10px" }}
      >
        <div className="absolute bg-slate-700" style={{ left: "-2px", top: "96px", width: "2px", height: "28px", borderRadius: "2px" }} />
        <div className="absolute bg-slate-700" style={{ left: "-2px", top: "150px", width: "2px", height: "48px", borderRadius: "2px" }} />
        <div className="absolute bg-slate-700" style={{ right: "-2px", top: "120px", width: "2px", height: "56px", borderRadius: "2px" }} />
        <div className="pointer-events-none absolute inset-0 border border-white/5" style={{ borderRadius: "2.75rem" }} />

        <div
          className="relative flex items-center justify-center overflow-hidden bg-black"
          style={{ borderRadius: "2.1rem", aspectRatio: "9 / 19.5" }}
        >
          <div
            className="absolute left-1/2 top-2.5 z-10 bg-black"
            style={{ transform: "translateX(-50%)", width: "86px", height: "22px", borderRadius: "999px" }}
          />
          {src ? (
            <img src={src} alt={alt} className="h-full w-full object-contain" />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-xs text-slate-600">screenshot</div>
          )}
        </div>
      </div>
    </div>
  );
}

/* ---------------------------------------------------------
   Nav
--------------------------------------------------------- */

function Nav({ t, lang, setLang }) {
  const [open, setOpen] = useState(false);
  const links = [
    { label: t.nav.features, href: "#features" },
    { label: t.nav.pro, href: "#pro" },
    { label: t.nav.faq, href: "#faq" },
    { label: t.nav.contact, href: "#contact" },
  ];
  return (
    <header className="sticky top-0 z-50 border-b border-white/5 bg-slate-950/70 backdrop-blur-xl">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-5 py-4">
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-purple-500 to-blue-500">
            <Wallet className="h-4 w-4 text-white" />
          </div>
          <span className="text-lg font-semibold tracking-tight text-white" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
            Spendly
          </span>
        </div>

        <nav className="hidden items-center gap-8 md:flex">
          {links.map((l) => (
            <a key={l.label} href={l.href} className="text-sm text-slate-400 transition-colors hover:text-white">
              {l.label}
            </a>
          ))}
        </nav>

        <div className="hidden items-center gap-4 md:flex">
          <LanguageToggle lang={lang} setLang={setLang} />
          <a href="#pro" className="text-sm text-slate-400 hover:text-white">{t.nav.signIn}</a>
          <a
            href="#download"
            className="rounded-lg bg-gradient-to-r from-purple-500 to-blue-500 px-4 py-2 text-sm font-medium text-white shadow-lg shadow-purple-500/20 transition-transform hover:-translate-y-0.5"
          >
            {t.nav.getApp}
          </a>
        </div>

        <div className="flex items-center gap-3 md:hidden">
          <LanguageToggle lang={lang} setLang={setLang} />
          <button className="text-slate-300" onClick={() => setOpen((o) => !o)} aria-label="Toggle menu">
            {open ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
          </button>
        </div>
      </div>

      {open && (
        <div className="border-t border-white/5 bg-slate-950 px-5 pb-5 md:hidden">
          <div className="flex flex-col gap-4 pt-4">
            {links.map((l) => (
              <a key={l.label} href={l.href} onClick={() => setOpen(false)} className="text-sm text-slate-300">
                {l.label}
              </a>
            ))}
            <a
              href="#download"
              onClick={() => setOpen(false)}
              className="rounded-lg bg-gradient-to-r from-purple-500 to-blue-500 px-4 py-2 text-center text-sm font-medium text-white"
            >
              {t.nav.getApp}
            </a>
          </div>
        </div>
      )}
    </header>
  );
}

/* ---------------------------------------------------------
   Hero
--------------------------------------------------------- */

function Hero({ t }) {
  return (
    <section className="relative overflow-hidden px-5 pb-24 pt-20 sm:pt-28">
      <GhostGrid />
      <div className="mx-auto grid max-w-6xl items-center gap-16 lg:grid-cols-2">
        <div>
          <SectionEyebrow>{t.hero.eyebrow}</SectionEyebrow>
          <h1
            className="mt-6 text-5xl font-semibold leading-[1.05] tracking-tight text-white sm:text-6xl lg:text-7xl"
            style={{ fontFamily: "'Space Grotesk', sans-serif" }}
          >
            {t.hero.titleLine1}
            <br />
            <span className="bg-gradient-to-r from-purple-400 to-blue-400 bg-clip-text text-transparent">
              {t.hero.titleLine2}
            </span>
          </h1>
          <p className="mt-6 max-w-md text-lg leading-relaxed text-slate-400">{t.hero.desc}</p>

          <div className="mt-10 flex flex-col gap-3 sm:flex-row sm:items-center">
            <PlayBadge />
            <a
              href="#how"
              className="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-700 px-6 py-3.5 text-sm font-medium text-slate-200 transition-colors hover:border-slate-500 hover:text-white"
            >
              {t.hero.ctaSecondary}
              <ArrowRight className="h-4 w-4" />
            </a>
          </div>

          <div className="mt-14 flex flex-wrap items-center gap-x-10 gap-y-4 border-t border-white/5 pt-8">
            {t.hero.stats.map(([n, l]) => (
              <div key={l}>
                <p className="text-2xl font-semibold text-white" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>{n}</p>
                <p className="text-xs text-slate-500">{l}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="flex justify-center">
          <PhoneMockup src="/dashboard-ss.png" alt="Spendly dashboard screen" size="w-[260px] sm:w-[310px]" />
        </div>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------
   How it works
--------------------------------------------------------- */

function HowItWorks({ t }) {
  return (
    <section id="how" className="relative border-y border-white/5 bg-slate-900/20 px-5 py-24">
      <div className="mx-auto max-w-6xl">
        <div className="mb-16 max-w-xl">
          <SectionEyebrow>{t.how.eyebrow}</SectionEyebrow>
          <h2 className="mt-5 text-4xl font-semibold tracking-tight text-white sm:text-5xl" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
            {t.how.title}
          </h2>
        </div>
        <div className="grid gap-10 sm:grid-cols-3">
          {t.how.steps.map((s, i) => (
            <div key={s.title} className="relative">
              <span
                className="text-6xl font-semibold text-transparent"
                style={{ WebkitTextStroke: "1px rgba(168,85,247,0.4)", fontFamily: "'Space Grotesk', sans-serif" }}
              >
                {STEP_NUMBERS[i]}
              </span>
              <h3 className="mt-4 text-xl font-semibold text-white" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
                {s.title}
              </h3>
              <p className="mt-3 text-base leading-relaxed text-slate-400">{s.desc}</p>
              {i < t.how.steps.length - 1 && (
                <div className="absolute right-[-1.25rem] top-8 hidden h-px w-10 bg-gradient-to-r from-purple-500/40 to-transparent sm:block" />
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------
   Zig-zag features
--------------------------------------------------------- */

function ZigZagFeature({ item, meta }) {
  return (
    <div className={`flex flex-col items-center gap-12 lg:gap-20 ${meta.reverse ? "lg:flex-row-reverse" : "lg:flex-row"}`}>
      <div className="flex w-full justify-center lg:w-1/2">
        <PhoneMockup src={meta.image} alt={meta.imageAlt} />
      </div>
      <div className="w-full lg:w-1/2">
        <SectionEyebrow>{item.eyebrow}</SectionEyebrow>
        <h3
          className="mt-5 text-3xl font-semibold tracking-tight text-white sm:text-4xl lg:text-5xl"
          style={{ fontFamily: "'Space Grotesk', sans-serif" }}
        >
          {item.title}
        </h3>
        <p className="mt-5 max-w-lg text-lg leading-relaxed text-slate-400">{item.desc}</p>
        <ul className="mt-7 space-y-4">
          {item.bullets.map((b) => (
            <li key={b} className="flex items-start gap-3 text-slate-300">
              <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-purple-500/15">
                <Check className="h-3.5 w-3.5 text-purple-400" />
              </span>
              <span className="text-base leading-relaxed">{b}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

function Features({ t }) {
  return (
    <section id="features" className="relative px-5 py-24 sm:py-32">
      <div className="mx-auto max-w-6xl">
        <div className="mb-20 max-w-xl">
          <SectionEyebrow>{t.features.eyebrow}</SectionEyebrow>
          <h2 className="mt-5 text-4xl font-semibold tracking-tight text-white sm:text-5xl" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
            {t.features.title}
          </h2>
          <p className="mt-4 text-lg text-slate-400">{t.features.subtitle}</p>
        </div>

        <div className="space-y-28 sm:space-y-36">
          {t.features.items.map((item, i) => (
            <ZigZagFeature key={item.title} item={item} meta={FEATURE_META[i]} />
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------
   Pro pricing
--------------------------------------------------------- */

function Pro({ t }) {
  return (
    <section id="pro" className="relative border-y border-white/5 bg-slate-900/20 px-5 py-24 sm:py-32">
      <div className="mx-auto max-w-6xl">
        <div className="mb-16 max-w-xl">
          <SectionEyebrow>{t.pro.eyebrow}</SectionEyebrow>
          <h2 className="mt-5 text-4xl font-semibold tracking-tight text-white sm:text-5xl" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
            {t.pro.title}
          </h2>
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          <div className="rounded-2xl border border-slate-800 bg-slate-900/40 p-10">
            <p className="text-sm font-medium text-slate-400">{t.pro.free.name}</p>
            <p className="mt-3 text-4xl font-semibold text-white" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>{t.pro.free.price}</p>
            <p className="mt-1 text-sm text-slate-500">{t.pro.free.priceNote}</p>
            <ul className="mt-8 space-y-4">
              {t.pro.free.features.map((f) => (
                <li key={f} className="flex items-start gap-3 text-base text-slate-300">
                  <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-slate-800">
                    <Check className="h-3.5 w-3.5 text-slate-400" />
                  </span>
                  {f}
                </li>
              ))}
            </ul>
          </div>

          <div className="relative overflow-hidden rounded-2xl border border-purple-500/40 bg-gradient-to-b from-purple-500/10 to-slate-900/40 p-10">
            <div className="absolute -right-10 -top-10 h-48 w-48 rounded-full bg-purple-500/20 blur-3xl" />
            <div className="mb-2 flex items-center gap-2">
              <Crown className="h-4 w-4 text-purple-400" />
              <p className="text-sm font-medium text-purple-300">{t.pro.pro.name}</p>
            </div>
            <p className="text-4xl font-semibold text-white" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
              {t.pro.pro.price}
              <span className="text-lg font-normal text-slate-400">/mo</span>
            </p>
            <p className="mt-1 text-sm text-slate-500">{t.pro.pro.priceNote}</p>
            <ul className="mt-8 space-y-4">
              {t.pro.pro.features.map((f) => (
                <li key={f} className="flex items-start gap-3 text-base text-slate-200">
                  <Sparkles className="mt-0.5 h-5 w-5 shrink-0 text-purple-400" />
                  {f}
                </li>
              ))}
            </ul>
            <button className="mt-10 w-full rounded-xl bg-gradient-to-r from-purple-500 to-blue-500 py-3.5 text-sm font-medium text-white shadow-lg shadow-purple-500/20 transition-transform hover:-translate-y-0.5">
              {t.pro.pro.cta}
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------
   FAQ accordion
--------------------------------------------------------- */

function FaqItem({ item, isOpen, onToggle }) {
  return (
    <div className="border-b border-white/5">
      <button onClick={onToggle} className="flex w-full items-center justify-between gap-4 py-6 text-left">
        <span className="text-lg font-medium text-white" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
          {item.q}
        </span>
        <span
          className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-slate-700 text-slate-400 transition-transform duration-300 ${
            isOpen ? "rotate-180 border-purple-500/50 text-purple-400" : ""
          }`}
        >
          <ChevronDown className="h-4 w-4" />
        </span>
      </button>
      <div className="overflow-hidden transition-all duration-300 ease-in-out" style={{ maxHeight: isOpen ? "220px" : "0px" }}>
        <p className="max-w-2xl pb-6 text-base leading-relaxed text-slate-400">{item.a}</p>
      </div>
    </div>
  );
}

function FAQ({ t }) {
  const [openIndex, setOpenIndex] = useState(0);
  return (
    <section id="faq" className="relative px-5 py-24 sm:py-32">
      <div className="mx-auto max-w-3xl">
        <div className="mb-14 text-center">
          <div className="flex justify-center">
            <SectionEyebrow>{t.faq.eyebrow}</SectionEyebrow>
          </div>
          <h2 className="mt-5 text-4xl font-semibold tracking-tight text-white sm:text-5xl" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
            {t.faq.title}
          </h2>
        </div>

        <div>
          {t.faq.items.map((item, i) => (
            <FaqItem key={item.q} item={item} isOpen={openIndex === i} onToggle={() => setOpenIndex(openIndex === i ? -1 : i)} />
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------
   Contact
--------------------------------------------------------- */

function Contact({ t }) {
  const [form, setForm] = useState({ name: "", email: "", message: "" });
  const [sent, setSent] = useState(false);

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setSent(true);
    setForm({ name: "", email: "", message: "" });
  };

  const inputClasses =
    "w-full rounded-xl border border-slate-800 bg-slate-900/60 px-4 py-3 text-sm text-white placeholder-slate-500 outline-none transition-colors focus:border-purple-500";

  return (
    <section id="contact" className="relative border-t border-white/5 px-5 py-24 sm:py-32">
      <GhostGrid />
      <div className="relative mx-auto max-w-2xl">
        <div className="mb-12 text-center">
          <div className="flex justify-center">
            <SectionEyebrow>{t.contact.eyebrow}</SectionEyebrow>
          </div>
          <h2 className="mt-5 text-4xl font-semibold tracking-tight text-white sm:text-5xl" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
            {t.contact.title}
          </h2>
          <p className="mx-auto mt-4 max-w-md text-lg text-slate-400">{t.contact.desc}</p>
        </div>

        <form onSubmit={handleSubmit} className="rounded-2xl border border-slate-800 bg-slate-900/40 p-6 sm:p-8">
          <div className="grid gap-5 sm:grid-cols-2">
            <div>
              <label className="mb-2 block text-xs font-medium uppercase tracking-wide text-slate-500">
                {t.contact.nameLabel}
              </label>
              <input
                type="text"
                name="name"
                required
                value={form.name}
                onChange={handleChange}
                placeholder={t.contact.namePlaceholder}
                className={inputClasses}
              />
            </div>
            <div>
              <label className="mb-2 block text-xs font-medium uppercase tracking-wide text-slate-500">
                {t.contact.emailLabel}
              </label>
              <input
                type="email"
                name="email"
                required
                value={form.email}
                onChange={handleChange}
                placeholder={t.contact.emailPlaceholder}
                className={inputClasses}
              />
            </div>
          </div>

          <div className="mt-5">
            <label className="mb-2 block text-xs font-medium uppercase tracking-wide text-slate-500">
              {t.contact.messageLabel}
            </label>
            <textarea
              name="message"
              required
              rows={4}
              value={form.message}
              onChange={handleChange}
              placeholder={t.contact.messagePlaceholder}
              className={`${inputClasses} resize-none`}
            />
          </div>

          <button
            type="submit"
            className="mt-6 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-purple-500 to-blue-500 py-3.5 text-sm font-medium text-white shadow-lg shadow-purple-500/20 transition-transform hover:-translate-y-0.5 sm:w-auto sm:px-8"
          >
            <Send className="h-4 w-4" />
            {t.contact.send}
          </button>

          {sent && <p className="mt-4 text-sm text-purple-300">{t.contact.sentMessage}</p>}
        </form>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------
   Final CTA + Footer
--------------------------------------------------------- */

function FinalCTA({ t }) {
  return (
    <section id="download" className="relative overflow-hidden border-t border-white/5 px-5 py-28">
      <GhostGrid />
      <div className="mx-auto max-w-3xl text-center">
        <div className="mx-auto mb-7 flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-purple-500 to-blue-500">
          <Wallet className="h-7 w-7 text-white" />
        </div>
        <h2 className="text-4xl font-semibold tracking-tight text-white sm:text-5xl" style={{ fontFamily: "'Space Grotesk', sans-serif" }}>
          {t.finalCta.title}
        </h2>
        <p className="mx-auto mt-4 max-w-md text-lg text-slate-400">{t.finalCta.desc}</p>
        <div className="mt-10 flex justify-center">
          <PlayBadge />
        </div>
        <div className="mt-7 flex items-center justify-center gap-1 text-slate-500">
          {[...Array(5)].map((_, i) => (
            <Star key={i} className="h-4 w-4 fill-purple-400 text-purple-400" />
          ))}
          <span className="ml-2 text-sm">4.8 {t.finalCta.ratingText}</span>
        </div>
      </div>
    </section>
  );
}

function Footer({ t }) {
  return (
    <footer className="border-t border-white/5 px-5 py-12">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 sm:flex-row">
        <div className="flex items-center gap-2">
          <Wallet className="h-4 w-4 text-purple-400" />
          <span className="text-sm text-slate-400">Spendly</span>
        </div>
        <p className="text-xs text-slate-600">{t.footer.tagline}</p>
        <div className="flex items-center gap-1.5 text-xs text-slate-600">
          <Shield className="h-3.5 w-3.5" />
          {t.footer.security}
        </div>
      </div>
    </footer>
  );
}

/* ---------------------------------------------------------
   Root
--------------------------------------------------------- */

export default function SpendlyLanding() {
  const [lang, setLang] = useState("en");
  const t = translations[lang];

  return (
    <div className="min-h-screen w-full bg-slate-950 text-slate-100" style={{ fontFamily: "'Inter', sans-serif" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap');
      `}</style>
      <Nav t={t} lang={lang} setLang={setLang} />
      <Hero t={t} />
      <HowItWorks t={t} />
      <Features t={t} />
      <Pro t={t} />
      <FAQ t={t} />
      <Contact t={t} />
      <FinalCTA t={t} />
      <Footer t={t} />
    </div>
  );
}