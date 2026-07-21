import React, { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Analytics } from "@vercel/analytics/react";
import {
  Wallet,
  Menu,
  X,
  ArrowRight,
  Check,
  Play,
  ChevronDown,
  LifeBuoy,
  LockKeyhole,
  ShieldCheck,
  Trash2,
  ChevronRight,
  Sun,
  Moon,
  Shield,
  ArrowLeft,
} from "lucide-react";

// TAM SAYFA ÇEVİRİ OBJESİ
const translations = {
  en: {
    nav: {
      privacy: "Privacy Policy",
      terms: "Terms",
      faq: "FAQ",
      support: "Support",
      deleteAccount: "Delete Account",
    },
    hero: {
      eyebrow: "SOCIAL FINANCE, SIMPLIFIED",
      titleLine1: "Split the bill.",
      titleLine2: "Not the friendship.",
      desc: "Splixa tracks shared expenses for trips, roommates and squads. It tells you exactly who owes whom, so no one has to be the one who brings up money.",
      ctaSecondary: "Explore features",
      stats: [
        ["256-bit", "AES Encryption"],
        ["Zero", "Hidden fees"],
        ["100%", "Data control"],
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
          desc: "Create a group for any trip or apartment, log a shared expense and pick who is in on it. Splixa handles the math instantly.",
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
      ],
    },
    faq: {
      eyebrow: "FAQ",
      title: "Questions, answered",
      items: [
        {
          q: "Is my financial data secure?",
          a: "Yes. Every transaction is protected with bank-level 256 bit encryption. Splixa never stores your banking credentials on our servers.",
        },
        {
          q: "How does group splitting work?",
          a: "Create a group, add the people involved and log an expense. Splixa automatically calculates a Net Summary showing exactly who owes whom.",
        },
        {
          q: "Is Splixa free to use?",
          a: "Yes. Core splitting, the dashboard and basic analytics are free forever.",
        },
        {
          q: "Can I use Splixa while traveling internationally?",
          a: "Absolutely. Splixa supports multiple currencies within a single group, so shared travel expenses convert and split cleanly.",
        },
      ],
    },
    legalGrid: {
      eyebrow: "HELP & LEGAL",
      title: "Everything you need, clearly available.",
      desc: "Your privacy and control matter. Find policies, support, and account options in one place.",
      open: "Open",
      cards: [
        {
          title: "Privacy Policy",
          description: "Learn how Splixa collects, protects, and handles your data.",
          href: "/privacy",
        },
        {
          title: "Terms of Service",
          description: "The straightforward terms for using Splixa services.",
          href: "/terms",
        },
        {
          title: "Support",
          description: "Get answers, report an issue, or ask our team for help.",
          href: "mailto:splixa.support@gmail.com",
        },
        {
          title: "Delete Account",
          description: "Request deletion of your Splixa account and data.",
          href: "mailto:splixa.support@gmail.com?subject=Delete%20my%20Splixa%20account",
        },
      ]
    },
    legalPages: {
      backToHome: "Back to Home",
      lastUpdated: "Last updated: July 2026",
      privacyTitle: "Privacy Policy",
      privacyBody: `
        At Splixa Labs, we take your privacy seriously. This Privacy Policy explains how we collect, use, and protect your information when you use the Splixa mobile application.
        
        1. Information We Collect
        We only collect information necessary to provide our services. This includes your name, email address, and the expense data you voluntarily enter into the app (e.g., group names, transaction amounts).
        
        2. Data Security & Encryption
        Your financial data is protected with bank-level 256-bit AES encryption both in transit and at rest. We do NOT ask for, process, or store your actual bank account or credit card credentials.
        
        3. Account Deletion (Right to be Forgotten)
        You have complete control over your data. You can request permanent deletion of your account and all associated financial records at any time by emailing splixa.support@gmail.com with the subject "Delete my Splixa account".
        
        4. Third-Party Sharing
        We do not sell your personal data to advertisers. 
      `,
      termsTitle: "Terms of Service",
      termsBody: `
        By downloading or using the Splixa application, these terms will automatically apply to you. You should make sure therefore that you read them carefully before using the app.
        
        1. Use of the App
        Splixa is designed to help friends and groups track shared expenses. While we strive for 100% mathematical accuracy, Splixa Labs is not legally responsible for real-world financial disputes between users.
        
        2. User Conduct
        You agree not to use the app in any way that is illegal or harmful. You must not attempt to extract the source code of the app, and you must not translate the app into other languages or make derivative versions without our explicit permission.
        
        3. Limitations of Liability
        Splixa Labs will not be liable for any direct, indirect, or consequential loss or damage arising under these terms and conditions or in connection with our application.
        
        If you have any questions about these Terms, please contact us at splixa.support@gmail.com.
      `
    },
    playBadge: {
      getItOn: "GET IT ON",
      store: "Google Play"
    },
    footer: {
      contactTitle: "Contact",
      security: "Bank-level encryption",
      rights: "© 2026 Splixa Labs"
    },
  },
  tr: {
    nav: {
      privacy: "Gizlilik Politikası",
      terms: "Koşullar",
      faq: "SSS",
      support: "Destek",
      deleteAccount: "Hesabı Sil",
    },
    hero: {
      eyebrow: "SOSYAL FİNANSIN BASİT HÂLİ",
      titleLine1: "Hesabı böl.",
      titleLine2: "Dostluğu bölme.",
      desc: "Splixa; gezilerde, ev arkadaşlarında ve gruplarda ortak harcamaları takip eder. Kimin kime ne kadar borçlu olduğunu anında söyler.",
      ctaSecondary: "Özellikleri keşfet",
      stats: [
        ["256-bit", "AES Şifreleme"],
        ["Sıfır", "Gizli Ücret"],
        ["%100", "Veri Kontrolü"],
      ],
    },
    features: {
      eyebrow: "ÖNE ÇIKAN ÖZELLİKLER",
      title: "Arkadaşlarla para işi böyle hissettirmeli",
      subtitle: "Geziler, ev arkadaşları ve gruplar için tasarlandı. Excel tabloları için değil.",
      items: [
        {
          eyebrow: "GRUP BÖLÜŞÜMÜ",
          title: "Arkadaş ekle. Adil böl. Bitti.",
          desc: "Herhangi bir gezi ya da daire için grup oluştur, ortak harcama gir ve kimin dahil olduğunu seç. Splixa hesabı anında yapar.",
          bullets: [
            "Herhangi bir gezi ya da daire için saniyeler içinde grup oluştur",
            "Ortak harcamaları ekle, kimin dahil olacağını seç",
            "Kimin kime ne kadar borçlu olduğunu gösteren Net Özet al",
          ],
        },
        {
          eyebrow: "GÖRSEL ANALİZ",
          title: "Sadece ekstreni değil, paranı gör",
          desc: "Aylık kategori dağılımı grafikleri, işlemleri tek bakışta anlayacağın bir resme dönüştürür.",
          bullets: [
            "Aylık kategori dağılımları paranın nereye gittiğini gösterir",
            "Etkileşimli grafikler örüntüleri ortaya çıkarır",
            "Harcamaları tek işlem düzeyinde takip et",
          ],
        },
      ],
    },
    faq: {
      eyebrow: "SSS",
      title: "Sorular, cevaplandı",
      items: [
        {
          q: "Finansal verilerim güvende mi?",
          a: "Evet. Her işlem, aktarım sırasında ve saklanırken banka düzeyinde 256 bit şifrelemeyle korunur. Banka şifrelerinizi asla sunucularımızda saklamayız.",
        },
        {
          q: "Grup bölüşümü nasıl çalışır?",
          a: "Bir grup oluştur, dahil olan kişileri ekle ve bir harcama gir. Splixa kimin kime ne kadar borçlu olduğunu otomatik hesaplar.",
        },
        {
          q: "Splixa ücretsiz mi?",
          a: "Evet. Temel bölüşüm, pano ve analizler süresiz ücretsizdir.",
        },
        {
          q: "Splixa'yı yurt dışı seyahatlerde kullanabilir miyim?",
          a: "Kesinlikle. Splixa, tek bir grup içinde birden fazla para birimini destekler.",
        },
      ],
    },
    legalGrid: {
      eyebrow: "YARDIM VE YASAL",
      title: "İhtiyacın olan her şey burada.",
      desc: "Gizliliğin ve kontrolün bizim için önemli. Politikaları, destek kanallarını ve hesap seçeneklerini tek bir yerde bulabilirsin.",
      open: "Aç",
      cards: [
        {
          title: "Gizlilik Politikası",
          description: "Splixa'nın verilerini nasıl topladığını ve koruduğunu öğren.",
          href: "/privacy",
        },
        {
          title: "Kullanım Koşulları",
          description: "Splixa hizmetlerini kullanmanın anlaşılır kuralları.",
          href: "/terms",
        },
        {
          title: "Destek",
          description: "Cevap bul, sorun bildir veya ekibimizden yardım iste.",
          href: "mailto:splixa.support@gmail.com",
        },
        {
          title: "Hesabı Sil",
          description: "Splixa hesabının ve verilerinin silinmesini talep et.",
          href: "mailto:splixa.support@gmail.com?subject=Delete%20my%20Splixa%20account",
        },
      ]
    },
    legalPages: {
      backToHome: "Ana Sayfaya Dön",
      lastUpdated: "Son güncelleme: Temmuz 2026",
      privacyTitle: "Gizlilik Politikası",
      privacyBody: `
        Splixa Labs olarak gizliliğinize büyük önem veriyoruz. Bu Gizlilik Politikası, Splixa mobil uygulamasını kullandığınızda bilgilerinizi nasıl topladığımızı, kullandığımızı ve koruduğumuzu açıklar.
        
        1. Topladığımız Bilgiler
        Yalnızca hizmetlerimizi sağlamak için gerekli olan bilgileri toplarız. Bunlar arasında adınız, e-posta adresiniz ve uygulamaya kendi isteğinizle girdiğiniz harcama verileri (ör. grup adları, işlem tutarları) bulunur.
        
        2. Veri Güvenliği ve Şifreleme
        Finansal verileriniz hem aktarım hem de depolama sırasında banka düzeyinde 256-bit AES şifreleme ile korunur. Gerçek banka hesabı veya kredi kartı bilgilerinizi İSTEMİYORUZ, işlemiyoruz veya saklamıyoruz.
        
        3. Hesap Silme (Unutulma Hakkı)
        Verileriniz üzerinde tam kontrole sahipsiniz. Hesabınızın ve ilgili tüm finansal kayıtlarınızın kalıcı olarak silinmesini istediğiniz an, "Delete my Splixa account" konu başlığıyla splixa.support@gmail.com adresine e-posta göndererek talep edebilirsiniz.
        
        4. Üçüncü Taraflarla Paylaşım
        Kişisel verilerinizi reklamverenlere veya üçüncü şahıslara satmıyoruz.
      `,
      termsTitle: "Kullanım Şartları",
      termsBody: `
        Splixa uygulamasını indirerek veya kullanarak bu şartları otomatik olarak kabul etmiş olursunuz. Bu nedenle, uygulamayı kullanmadan önce lütfen bu şartları dikkatlice okuyun.
        
        1. Uygulamanın Kullanımı
        Splixa, arkadaşların ve grupların ortak harcamalarını takip etmelerine yardımcı olmak için tasarlanmıştır. %100 matematiksel doğruluk sağlamaya çalışsak da, Splixa Labs kullanıcılar arasındaki gerçek dünyadaki finansal anlaşmazlıklardan yasal olarak sorumlu tutulamaz.
        
        2. Kullanıcı Davranışları
        Uygulamayı yasadışı veya zararlı bir şekilde kullanmamayı kabul edersiniz. Açık iznimiz olmadan uygulamanın kaynak kodunu çıkarmaya çalışmamalı, uygulamayı diğer dillere çevirmemeli veya türev sürümlerini yapmamalısınız.
        
        3. Sorumlulukların Sınırlandırılması
        Splixa Labs, uygulamamızla bağlantılı olarak ortaya çıkan doğrudan, dolaylı veya sonuç olarak ortaya çıkan kayıp veya hasarlardan sorumlu olmayacaktır.
        
        Bu Şartlarla ilgili herhangi bir sorunuz varsa, lütfen splixa.support@gmail.com adresinden bizimle iletişime geçin.
      `
    },
    playBadge: {
      getItOn: "HEMEN İNDİR",
      store: "Google Play"
    },
    footer: {
      contactTitle: "İletişim",
      security: "Banka düzeyinde şifreleme",
      rights: "© 2026 Splixa Labs"
    },
  },
};

const FEATURE_META = [
  {
    image: "/groups-ss.png",
    imageAlt: "Splixa group and Net Summary screen",
  },
  {
    image: "/analytics-ss.png",
    imageAlt: "Splixa category distribution analytics screen",
  },
];

const ICONS = [ShieldCheck, LockKeyhole, LifeBuoy, Trash2];

const revealProps = {
  initial: { opacity: 0, y: 28 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true, amount: 0.18 },
  transition: { duration: 0.6, ease: "easeOut" },
};

function Reveal({ children, delay = 0, className = "" }) {
  return (
    <motion.div
      {...revealProps}
      transition={{ duration: 0.6, ease: "easeOut", delay }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

function MountReveal({ children, delay = 0, className = "" }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.65, ease: "easeOut", delay }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

function AmbientOrbs() {
  return (
    <>
      <motion.div
        animate={{ opacity: [0.12, 0.28, 0.12], scale: [1, 1.1, 1] }}
        transition={{ repeat: Infinity, duration: 5, ease: "easeInOut" }}
        className="pointer-events-none absolute -left-24 top-10 -z-10 h-72 w-72 rounded-full bg-cyan-500/20 blur-3xl"
      />
      <motion.div
        animate={{ opacity: [0.1, 0.24, 0.1], scale: [1.05, 1, 1.05] }}
        transition={{ repeat: Infinity, duration: 5, ease: "easeInOut", delay: 1 }}
        className="pointer-events-none absolute -right-24 bottom-0 -z-10 h-72 w-72 rounded-full bg-cyan-500/15 blur-3xl"
      />
    </>
  );
}

function GhostGrid() {
  return (
    <div
      className="pointer-events-none absolute inset-0 opacity-[0.03] dark:opacity-30"
      style={{
        backgroundImage: "radial-gradient(circle, rgba(6,182,212,0.35) 1px, transparent 1px)",
        backgroundSize: "22px 22px",
        maskImage: "radial-gradient(ellipse 60% 50% at 50% 0%, black 40%, transparent 100%)",
        WebkitMaskImage: "radial-gradient(ellipse 60% 50% at 50% 0%, black 40%, transparent 100%)",
      }}
    />
  );
}

function SectionEyebrow({ children }) {
  return (
    <div className="inline-flex items-center gap-2 rounded-full border border-cyan-500/30 bg-cyan-500/10 px-3 py-1 text-xs font-medium tracking-wide text-[#06B6D4] dark:text-[#67E8F9]">
      {children}
    </div>
  );
}

function PlayBadge({ t, className = "" }) {
  return (
    <motion.button
      whileHover={{ y: -3 }}
      whileTap={{ scale: 0.97 }}
      className={`group inline-flex items-center gap-3 rounded-xl bg-[#06B6D4] px-6 py-3.5 text-white dark:text-[#0B0F19] shadow-lg shadow-cyan-500/20 ${className}`}
    >
      <Play className="h-5 w-5 fill-current text-current" />
      <span className="text-left leading-tight">
        <span className="block text-[10px] opacity-80">{t.playBadge.getItOn}</span>
        <span className="block text-sm font-semibold">{t.playBadge.store}</span>
      </span>
    </motion.button>
  );
}

function LanguageToggle({ lang, setLang, className = "" }) {
  return (
    <div className={`inline-flex items-center rounded-full border border-slate-200 dark:border-slate-700 p-1 ${className}`}>
      {["en", "tr"].map((code) => (
        <button
          key={code}
          onClick={() => setLang(code)}
          className={`rounded-full px-3 py-1 text-xs font-semibold transition-colors ${
            lang === code
              ? "bg-[#06B6D4] text-white dark:text-[#0B0F19]"
              : "text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
          }`}
        >
          {code.toUpperCase()}
        </button>
      ))}
    </div>
  );
}

function ThemeToggle({ theme, setTheme }) {
  return (
    <button
      onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
      className="flex h-8 w-8 items-center justify-center rounded-full border border-slate-200 text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-900 dark:border-slate-700 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-white"
      aria-label="Toggle theme"
    >
      {theme === "dark" ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
    </button>
  );
}

function PhoneMockup({ src, alt }) {
  return (
    <div className="w-full max-w-[320px] mx-auto lg:mx-0">
      <motion.div
        animate={{ y: [0, -20, 0] }}
        transition={{ repeat: Infinity, duration: 4, ease: "easeInOut" }}
        className="relative"
      >
        <motion.div
          animate={{ opacity: [0.16, 0.34, 0.16], scale: [0.96, 1.05, 0.96] }}
          transition={{ repeat: Infinity, duration: 4, ease: "easeInOut" }}
          className="absolute inset-0 -z-10 rounded-full bg-cyan-500/30 blur-3xl"
        />
        <motion.div
          whileHover={{ scale: 1.025 }}
          className="relative border border-slate-300 bg-gradient-to-b from-white to-slate-50 p-2.5 shadow-2xl shadow-cyan-900/10 dark:border-slate-600 dark:from-[#1E293B] dark:to-[#0B0F19] dark:shadow-cyan-950/60"
          style={{ borderRadius: "2.75rem" }}
        >
          <div className="absolute left-[-2px] top-24 h-7 w-[2px] rounded bg-slate-300 dark:bg-slate-600" />
          <div className="absolute left-[-2px] top-[150px] h-12 w-[2px] rounded bg-slate-300 dark:bg-slate-600" />
          <div className="absolute right-[-2px] top-[120px] h-14 w-[2px] rounded bg-slate-300 dark:bg-slate-600" />
          <div
            className="relative flex aspect-[9/19.5] items-center justify-center overflow-hidden bg-slate-100 dark:bg-black"
            style={{ borderRadius: "2.1rem" }}
          >
            <div className="absolute left-1/2 top-2.5 z-10 h-[22px] w-[86px] -translate-x-1/2 rounded-full bg-black" />
            {src ? (
              <img src={src} alt={alt} className="h-full w-full object-contain" />
            ) : (
              <div className="text-xs text-slate-500">screenshot</div>
            )}
          </div>
        </motion.div>
      </motion.div>
    </div>
  );
}

function Nav({ t, lang, setLang, theme, setTheme, navigate }) {
  const [open, setOpen] = useState(false);

  const handleNavigate = (e, path) => {
    e.preventDefault();
    setOpen(false);
    navigate(path);
  };

  const links = [
    { label: t.nav.faq, href: "#faq" },
    { label: t.nav.privacy, href: "/privacy", internal: true },
    { label: t.nav.terms, href: "/terms", internal: true },
    { label: t.nav.support, href: "mailto:splixa.support@gmail.com" },
    { label: t.nav.deleteAccount, href: "mailto:splixa.support@gmail.com?subject=Delete%20my%20Splixa%20account" },
  ];

  return (
    <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/90 px-5 py-4 backdrop-blur-xl dark:border-white/5 dark:bg-[#0B0F19]/90">
      <div className="mx-auto flex max-w-6xl items-center justify-between">
        {/* LOGO İLE ANA SAYFAYA VE EN TEPEYE DÖNÜŞ DÜZELTİLDİ */}
        <a 
          href="/" 
          onClick={(e) => {
            e.preventDefault();
            if(window.location.pathname === "/") {
              window.scrollTo({ top: 0, behavior: "smooth" });
            } else {
              handleNavigate(e, "/");
            }
          }} 
          className="flex items-center gap-2 cursor-pointer"
        >
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#06B6D4]">
            <Wallet className="h-4 w-4 text-white dark:text-[#0B0F19]" />
          </div>
          <span className="text-lg font-semibold tracking-tight text-slate-900 dark:text-white">
            Splixa
          </span>
        </a>

        <nav className="hidden items-center gap-7 md:flex">
          {links.map((link) => (
            <a
              key={link.label}
              href={link.href}
              onClick={(e) => link.internal && handleNavigate(e, link.href)}
              className="text-sm text-slate-600 transition-colors hover:text-[#06B6D4] dark:text-slate-300 dark:hover:text-[#06B6D4]"
            >
              {link.label}
            </a>
          ))}
          <div className="flex items-center gap-3 border-l border-slate-200 pl-4 dark:border-slate-700">
            <LanguageToggle lang={lang} setLang={setLang} />
            <ThemeToggle theme={theme} setTheme={setTheme} />
          </div>
        </nav>

        <div className="flex items-center gap-3 md:hidden">
          <ThemeToggle theme={theme} setTheme={setTheme} />
          <LanguageToggle lang={lang} setLang={setLang} />
          <button
            className="text-slate-600 dark:text-slate-300"
            onClick={() => setOpen(!open)}
            aria-label="Toggle menu"
          >
            {open ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
          </button>
        </div>
      </div>

      {open && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: "auto" }}
          exit={{ opacity: 0, height: 0 }}
          className="border-t border-slate-200 bg-white px-5 dark:border-white/5 dark:bg-[#0B0F19] md:hidden"
        >
          <div className="flex flex-col gap-4 py-5">
            {links.map((link) => (
              <a
                key={link.label}
                href={link.href}
                onClick={(e) => {
                  if(link.internal) handleNavigate(e, link.href);
                  else setOpen(false);
                }}
                className="text-sm text-slate-700 dark:text-slate-200"
              >
                {link.label}
              </a>
            ))}
          </div>
        </motion.div>
      )}
    </header>
  );
}

function Hero({ t }) {
  return (
    <section className="relative overflow-hidden px-5 pb-24 pt-20 sm:pt-28">
      <GhostGrid />
      <AmbientOrbs />

      <div className="mx-auto max-w-6xl">
        <div className="grid grid-cols-1 items-center gap-12 lg:grid-cols-2">
          
          {/* 1. YAZI KISMI - 'order-2 lg:order-1' yerine sadece 'order-1' yapıyoruz */}
          <div className="order-1">
            <MountReveal delay={0}>
              <SectionEyebrow>{t.hero.eyebrow}</SectionEyebrow>
            </MountReveal>

            <MountReveal delay={0.1}>
              <h1 className="mt-6 max-w-xl text-5xl font-semibold leading-[1.05] tracking-tight text-slate-900 sm:text-6xl lg:text-7xl dark:text-white">
                {t.hero.titleLine1}
                <br />
                <span className="text-[#06B6D4]">{t.hero.titleLine2}</span>
              </h1>
            </MountReveal>

            <MountReveal delay={0.2}>
              <p className="mt-6 max-w-md text-lg leading-relaxed text-slate-600 dark:text-slate-300">
                {t.hero.desc}
              </p>
            </MountReveal>

            <MountReveal delay={0.3}>
              <div className="mt-10 flex flex-col gap-3 sm:flex-row sm:items-center">
                <PlayBadge t={t} />
                <motion.a
                  whileHover={{ y: -3 }}
                  whileTap={{ scale: 0.97 }}
                  href="#features"
                  className="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-300 px-6 py-3.5 text-sm font-medium text-slate-700 hover:border-[#06B6D4] hover:text-slate-900 dark:border-slate-700 dark:text-slate-200 dark:hover:border-[#06B6D4] dark:hover:text-white"
                >
                  {t.hero.ctaSecondary}
                  <ArrowRight className="h-4 w-4" />
                </motion.a>
              </div>
            </MountReveal>
            
            <MountReveal delay={0.4}>
              <div className="mt-14 flex flex-wrap items-center gap-x-10 gap-y-4 border-t border-slate-200 pt-8 dark:border-white/5">
                {t.hero.stats.map(([number, label]) => (
                  <div key={label}>
                    <p className="text-2xl font-semibold text-slate-900 dark:text-white">
                      {number}
                    </p>
                    <p className="text-xs text-slate-500 dark:text-slate-400">
                      {label}
                    </p>
                  </div>
                ))}
              </div>
            </MountReveal>
          </div>

          {/* 2. TELEFON KISMI - 'order-1 lg:order-2' yerine sadece 'order-2' yapıyoruz */}
          <motion.div
            initial={{ opacity: 0, y: 28 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, ease: "easeOut", delay: 0.2 }}
            className="order-2 flex justify-center lg:justify-end"
          >
            <PhoneMockup src="/dashboard-ss.png" alt="Splixa dashboard screen" />
          </motion.div>
          
        </div>
      </div>
    </section>
  );
}

function ZigZagFeature({ item, meta, reverse }) {
  return (
    <div className="grid grid-cols-1 items-center gap-12 lg:grid-cols-2">
      <Reveal className={reverse ? "order-2 lg:order-2" : "order-2 lg:order-1"}>
        <SectionEyebrow>{item.eyebrow}</SectionEyebrow>
        <h3 className="mt-5 text-3xl font-semibold tracking-tight text-slate-900 sm:text-4xl lg:text-5xl dark:text-white">
          {item.title}
        </h3>
        <p className="mt-5 max-w-lg text-lg leading-relaxed text-slate-600 dark:text-slate-300">
          {item.desc}
        </p>
        <ul className="mt-7 space-y-4">
          {item.bullets.map((bullet) => (
            <li key={bullet} className="flex items-start gap-3 text-slate-700 dark:text-slate-200">
              <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-cyan-500/10">
                <Check className="h-3.5 w-3.5 text-[#06B6D4]" />
              </span>
              <span className="text-base leading-relaxed">{bullet}</span>
            </li>
          ))}
        </ul>
      </Reveal>

      <Reveal
        delay={0.12}
        className={reverse ? "order-1 flex justify-center lg:order-1 lg:justify-end" : "order-1 flex justify-center lg:order-2 lg:justify-end"}
      >
        <PhoneMockup src={meta.image} alt={meta.imageAlt} />
      </Reveal>
    </div>
  );
}

function Features({ t }) {
  return (
    <section id="features" className="relative border-y border-slate-200 bg-slate-50 px-5 py-24 dark:border-white/5 dark:bg-[#111827] sm:py-32">
      <div className="mx-auto max-w-6xl">
        <Reveal className="mb-20 max-w-xl">
          <SectionEyebrow>{t.features.eyebrow}</SectionEyebrow>
          <h2 className="mt-5 text-4xl font-semibold tracking-tight text-slate-900 sm:text-5xl dark:text-white">
            {t.features.title}
          </h2>
          <p className="mt-4 text-lg text-slate-600 dark:text-slate-300">
            {t.features.subtitle}
          </p>
        </Reveal>

        <div className="space-y-28 sm:space-y-36">
          {t.features.items.map((item, index) => (
            <ZigZagFeature key={item.title} item={item} meta={FEATURE_META[index]} reverse={index % 2 === 1} />
          ))}
        </div>
      </div>
    </section>
  );
}

function FAQ({ t }) {
  const [openIndex, setOpenIndex] = useState(0);

  return (
    <section id="faq" className="relative px-5 py-24 sm:py-32">
      <div className="mx-auto max-w-3xl">
        <Reveal className="mb-14 text-center">
          <div className="flex justify-center">
            <SectionEyebrow>{t.faq.eyebrow}</SectionEyebrow>
          </div>
          <h2 className="mt-5 text-4xl font-semibold tracking-tight text-slate-900 sm:text-5xl dark:text-white">
            {t.faq.title}
          </h2>
        </Reveal>

        <div>
          {t.faq.items.map((item, index) => {
            const isOpen = openIndex === index;
            return (
              <Reveal key={item.q} delay={index * 0.08}>
                <div className="border-b border-slate-200 dark:border-white/10">
                  <button
                    onClick={() => setOpenIndex(isOpen ? -1 : index)}
                    className="flex w-full items-center justify-between gap-4 py-6 text-left"
                  >
                    <span className="text-lg font-medium text-slate-900 dark:text-white">{item.q}</span>
                    <motion.span
                      animate={{ rotate: isOpen ? 180 : 0, borderColor: isOpen ? "#06B6D4" : "var(--border-color)" }}
                      className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-slate-300 text-slate-500 dark:border-slate-700 dark:text-slate-300"
                    >
                      <ChevronDown className="h-4 w-4" />
                    </motion.span>
                  </button>
                  <motion.div
                    initial={false}
                    animate={{ height: isOpen ? "auto" : 0, opacity: isOpen ? 1 : 0 }}
                    transition={{ duration: 0.28, ease: "easeInOut" }}
                    className="overflow-hidden"
                  >
                    <p className="max-w-2xl pb-6 text-base leading-relaxed text-slate-600 dark:text-slate-300">{item.a}</p>
                  </motion.div>
                </div>
              </Reveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}

function LegalGrid({ t, navigate }) {
  const handleNavigate = (e, path) => {
    e.preventDefault();
    navigate(path);
  };

  return (
    <section id="legal" className="border-t border-slate-200 bg-slate-50 px-5 py-24 dark:border-white/5 dark:bg-[#111827] sm:py-32">
      <div className="mx-auto max-w-6xl">
        <Reveal className="max-w-2xl">
          <SectionEyebrow>{t.legalGrid.eyebrow}</SectionEyebrow>
          <h2 className="mt-5 text-4xl font-semibold tracking-tight text-slate-900 sm:text-5xl dark:text-white">
            {t.legalGrid.title}
          </h2>
          <p className="mt-4 text-lg leading-relaxed text-slate-600 dark:text-slate-300">
            {t.legalGrid.desc}
          </p>
        </Reveal>

        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.2 }}
          variants={{ hidden: {}, visible: { transition: { staggerChildren: 0.1 } } }}
          className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-4"
        >
          {t.legalGrid.cards.map((card, index) => {
            const Icon = ICONS[index];
            const isInternal = card.href.startsWith('/');
            return (
              <motion.a
                key={card.title}
                href={card.href}
                onClick={(e) => isInternal && handleNavigate(e, card.href)}
                variants={{ hidden: { opacity: 0, y: 24 }, visible: { opacity: 1, y: 0 } }}
                transition={{ duration: 0.5, ease: "easeOut" }}
                whileHover={{ y: -8, borderColor: "#06B6D4", boxShadow: "0 0 30px rgba(6,182,212,0.24)" }}
                className="group rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-[#1E293B] dark:shadow-none"
              >
                <Icon className="h-6 w-6 text-[#06B6D4]" />
                <h3 className="mt-8 text-lg font-semibold text-slate-900 dark:text-white">{card.title}</h3>
                <p className="mt-3 text-sm leading-6 text-slate-600 dark:text-slate-300">{card.description}</p>
                <span className="mt-6 flex items-center gap-1 text-sm font-medium text-[#06B6D4]">
                  {t.legalGrid.open}
                  <ChevronRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                </span>
              </motion.a>
            )
          })}
        </motion.div>
      </div>
    </section>
  );
}

function Footer({ t }) {
  return (
    <footer className="border-t border-slate-200 bg-white px-5 py-12 dark:border-white/5 dark:bg-[#0B0F19]">
      <div className="mx-auto max-w-6xl">
        <div className="flex flex-col items-center justify-between gap-5 sm:flex-row">
          <div className="flex items-center gap-2">
            <Wallet className="h-4 w-4 text-[#06B6D4]" />
            <span className="text-sm font-medium text-slate-900 dark:text-slate-200">Splixa</span>
          </div>

          <div className="text-center sm:text-left">
            <p className="text-sm font-medium text-slate-900 dark:text-white">{t.footer.contactTitle}</p>
            <a href="mailto:splixa.support@gmail.com" className="mt-1 inline-block text-sm text-[#06B6D4] hover:underline">
              splixa.support@gmail.com
            </a>
          </div>

          <div className="flex items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400">
            <Shield className="h-3.5 w-3.5 text-[#06B6D4]" />
            {t.footer.security}
          </div>
        </div>

        <div className="mt-8 border-t border-slate-200 pt-6 text-center text-xs text-slate-500 dark:border-white/5">
          {t.footer.rights}
        </div>
      </div>
    </footer>
  );
}

// ---------------- LEGAL PAGES ---------------- //

function LegalPageTemplate({ title, content, t, navigate }) {
  return (
    <div className="min-h-screen pt-24 pb-32 px-5">
      <div className="max-w-3xl mx-auto">
        <button 
          onClick={() => {
            navigate('/');
            window.scrollTo(0, 0);
          }}
          className="mb-10 flex items-center gap-2 text-sm font-medium text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          {t.legalPages.backToHome}
        </button>
        <h1 className="text-4xl font-semibold tracking-tight text-slate-900 dark:text-white mb-4">{title}</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mb-12">{t.legalPages.lastUpdated}</p>
        <div className="prose dark:prose-invert max-w-none text-slate-700 dark:text-slate-300 leading-loose whitespace-pre-wrap">
          {content}
        </div>
      </div>
    </div>
  );
}

export default function SplixaApp() {
  const [lang, setLang] = useState("en");
  const [theme, setTheme] = useState("dark");
  const [currentPath, setCurrentPath] = useState(window.location.pathname);
  const t = translations[lang];

  // Yönlendirme (Routing) Efekti
  useEffect(() => {
    const onLocationChange = () => setCurrentPath(window.location.pathname);
    window.addEventListener("popstate", onLocationChange);
    return () => window.removeEventListener("popstate", onLocationChange);
  }, []);

  const navigate = (path) => {
    window.history.pushState({}, "", path);
    setCurrentPath(path);
    window.scrollTo(0, 0);
  };

  // KESİN ÇÖZÜM: Root HTML etiketine müdahale eden Theme Efekti
  useEffect(() => {
    const root = window.document.documentElement;
    if (theme === "dark") {
      root.classList.add("dark");
    } else {
      root.classList.remove("dark");
    }
  }, [theme]);

  // Sistem temasını algılama
  useEffect(() => {
    if (window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches) {
      setTheme("light");
    }
  }, []);

  // Hangi sayfanın render edileceği
  let Content;
  if (currentPath === "/privacy") {
    Content = <LegalPageTemplate title={t.legalPages.privacyTitle} content={t.legalPages.privacyBody} t={t} navigate={navigate} />;
  } else if (currentPath === "/terms") {
    Content = <LegalPageTemplate title={t.legalPages.termsTitle} content={t.legalPages.termsBody} t={t} navigate={navigate} />;
  } else {
    Content = (
      <>
        <Hero t={t} />
        <Features t={t} />
        <FAQ t={t} />
        <LegalGrid t={t} navigate={navigate} />
      </>
    );
  }

  // Dışarıdaki ekstra <div className={...}> sarmalayıcısı kaldırıldı
  return (
    <div
      className="min-h-screen w-full bg-white text-slate-900 transition-colors duration-300 dark:bg-[#0B0F19] dark:text-[#F8FAFC]"
      style={{ fontFamily: "'Inter', sans-serif" }}
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
        html { scroll-behavior: smooth; }
      `}</style>

      <Nav t={t} lang={lang} setLang={setLang} theme={theme} setTheme={setTheme} navigate={navigate} />
      {Content}
      <Footer t={t} />
      <Analytics />
    </div>
  );
}