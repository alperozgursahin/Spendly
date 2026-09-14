import { useCallback, useEffect, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Analytics } from "@vercel/analytics/react";
import {
  Menu,
  X,
  ArrowRight,
  Check,
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

const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=net.splixa.app";

import { translations } from "./content/translations.js";

const FEATURE_META = [
  {
    image: "/groups-ss.png",
    imageAlt: "Splixa group and Net Summary screen",
  },
  {
    image: "/analytics-ss.png",
    imageAlt: "Splixa personal budget analytics screen",
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
        animate={{
          opacity: [0.12, 0.28, 0.12],
          scale: [1, 1.1, 1],
        }}
        transition={{
          repeat: Infinity,
          duration: 5,
          ease: "easeInOut",
        }}
        className="pointer-events-none absolute -left-24 top-10 -z-10 h-72 w-72 rounded-full bg-cyan-500/20 blur-3xl"
      />

      <motion.div
        animate={{
          opacity: [0.1, 0.24, 0.1],
          scale: [1.05, 1, 1.05],
        }}
        transition={{
          repeat: Infinity,
          duration: 5,
          ease: "easeInOut",
          delay: 1,
        }}
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
        backgroundImage:
          "radial-gradient(circle, rgba(6,182,212,0.35) 1px, transparent 1px)",
        backgroundSize: "22px 22px",
        maskImage:
          "radial-gradient(ellipse 60% 50% at 50% 0%, black 40%, transparent 100%)",
        WebkitMaskImage:
          "radial-gradient(ellipse 60% 50% at 50% 0%, black 40%, transparent 100%)",
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

function AnnouncementBar({ t, onJoinWaitlist }) {
  return (
    <div className="relative z-[60] border-b border-cyan-500/20 bg-gradient-to-r from-cyan-50 via-cyan-100/80 to-cyan-50 px-5 py-2.5 text-center dark:from-cyan-950/70 dark:via-cyan-900/40 dark:to-cyan-950/70">
      <button
        type="button"
        onClick={onJoinWaitlist}
        className="text-sm font-medium text-cyan-800 transition-colors hover:text-cyan-600 dark:text-cyan-100 dark:hover:text-cyan-300"
      >
        {t.announcement}
      </button>
    </div>
  );
}

function GooglePlayIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      className="h-4 w-4 shrink-0"
    >
      <path d="M3 2.5 13.2 12 3 21.5Z" fill="#00D7FE" />
      <path d="m3 2.5 13.7 7.3-3.5 2.2Z" fill="#00F076" />
      <path d="m3 21.5 13.7-7.3-3.5-2.2Z" fill="#FFCF47" />
      <path d="m16.7 9.8 3.2 1.7c.8.4.8.6 0 1l-3.2 1.7-3.5-2.2Z" fill="#FF3A44" />
    </svg>
  );
}
function PlayStoreButton({ t }) {
  return (
    <motion.a
      href={PLAY_STORE_URL}
      target="_blank"
      rel="noopener noreferrer"
      whileHover={{ y: -3 }}
      whileTap={{ scale: 0.97 }}
      className="inline-flex items-center justify-center gap-2 rounded-xl bg-[#06B6D4] px-6 py-3.5 text-sm font-semibold text-white shadow-lg shadow-cyan-500/20 dark:text-[#0B0F19]"
    >
      <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-white shadow-sm">
        <GooglePlayIcon />
      </span>
      <span>{t.hero.ctaPrimary}</span>
      <ArrowRight className="h-4 w-4" />
    </motion.a>
  );
}

function WaitlistModal({ isOpen, onClose, t }) {
  const [email, setEmail] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSuccessful, setIsSuccessful] = useState(false);
  const [submitError, setSubmitError] = useState("");

  const handleClose = useCallback(() => {
    setEmail("");
    setIsSubmitting(false);
    setIsSuccessful(false);
    setSubmitError("");
    onClose();
  }, [onClose]);

  useEffect(() => {
    if (!isOpen) return undefined;

    const previousOverflow = document.body.style.overflow;

    const handleKeyDown = (event) => {
      if (event.key === "Escape") {
        handleClose();
      }
    };

    document.body.style.overflow = "hidden";
    document.addEventListener("keydown", handleKeyDown);

    return () => {
      document.body.style.overflow = previousOverflow;
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [handleClose, isOpen]);

  const handleSubmit = async (event) => {
    event.preventDefault();
    setIsSubmitting(true);
    setSubmitError("");

    try {
      const response = await fetch("https://formspree.io/f/maqryybk", {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          email,
          source: "Splixa landing page beta signup",
        }),
      });

      if (!response.ok) {
        throw new Error(`Formspree request failed: ${response.status}`);
      }

      setIsSuccessful(true);
      setEmail("");
    } catch (error) {
      console.error("Waitlist submission failed", error);
      setSubmitError(t.waitlist.error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onMouseDown={handleClose}
          className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-950/75 px-5 backdrop-blur-md"
          role="dialog"
          aria-modal="true"
          aria-labelledby="waitlist-modal-title"
        >
          <motion.div
            initial={{ opacity: 0, y: 24, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 16, scale: 0.97 }}
            transition={{ duration: 0.25, ease: "easeOut" }}
            onMouseDown={(event) => event.stopPropagation()}
            className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-slate-200 bg-white p-7 shadow-2xl shadow-cyan-950/30 sm:p-9 dark:border-white/10 dark:bg-[#111827]"
          >
            <div className="pointer-events-none absolute -right-20 -top-20 h-52 w-52 rounded-full bg-cyan-500/20 blur-3xl" />
            <div className="pointer-events-none absolute -bottom-28 -left-20 h-52 w-52 rounded-full bg-cyan-500/10 blur-3xl" />

            <button
              type="button"
              onClick={handleClose}
              aria-label={t.waitlist.close}
              className="absolute right-5 top-5 z-10 flex h-9 w-9 items-center justify-center rounded-full border border-slate-200 text-slate-500 transition-colors hover:border-cyan-500 hover:text-cyan-500 dark:border-white/10 dark:text-slate-400 dark:hover:border-cyan-500 dark:hover:text-cyan-400"
            >
              <X className="h-4 w-4" />
            </button>

            <div className="relative">
              <img
                src="/splixa_logo.png"
                alt="Splixa logo"
                className="mb-6 h-12 w-12 rounded-xl object-cover"
              />

              <SectionEyebrow>{t.waitlist.eyebrow}</SectionEyebrow>

              <h2
                id="waitlist-modal-title"
                className="mt-5 pr-10 text-3xl font-semibold tracking-tight text-slate-900 dark:text-white"
              >
                {t.waitlist.title}
              </h2>

              <p className="mt-4 leading-7 text-slate-600 dark:text-slate-300">
                {t.waitlist.description}
              </p>

              {isSuccessful ? (
                <motion.div
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  role="status"
                  className="mt-7 flex items-center gap-3 rounded-2xl border border-emerald-500/30 bg-emerald-500/10 p-4 font-medium text-emerald-700 dark:text-emerald-300"
                >
                  <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-emerald-500 text-white">
                    <Check className="h-4 w-4" />
                  </span>

                  {t.waitlist.success}
                </motion.div>
              ) : (
                <form
                  onSubmit={handleSubmit}
                  className="mt-7 flex flex-col gap-3 sm:flex-row sm:flex-wrap"
                >
                  <label htmlFor="waitlist-email" className="sr-only">
                    {t.waitlist.emailLabel}
                  </label>

                  <input
                    id="waitlist-email"
                    type="email"
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                    placeholder={t.waitlist.emailPlaceholder}
                    autoComplete="email"
                    autoFocus
                    required
                    disabled={isSubmitting}
                    className="min-w-0 flex-1 rounded-xl border border-slate-300 bg-white px-4 py-3.5 text-sm text-slate-900 outline-none transition focus:border-cyan-500 focus:ring-4 focus:ring-cyan-500/10 disabled:opacity-60 dark:border-slate-700 dark:bg-[#0B0F19] dark:text-white dark:placeholder:text-slate-500"
                  />

                  <motion.button
                    type="submit"
                    whileHover={!isSubmitting ? { y: -2 } : undefined}
                    whileTap={!isSubmitting ? { scale: 0.98 } : undefined}
                    disabled={isSubmitting}
                    className="inline-flex min-w-40 items-center justify-center rounded-xl bg-[#06B6D4] px-5 py-3.5 text-sm font-semibold text-white shadow-lg shadow-cyan-500/20 disabled:cursor-wait disabled:opacity-70 dark:text-[#0B0F19]"
                  >
                    {isSubmitting
                      ? t.waitlist.submitting
                      : t.waitlist.button}

                  {submitError && (
                    <p
                      role="alert"
                      className="text-sm text-rose-600 dark:text-rose-400 sm:basis-full"
                    >
                      {submitError}
                    </p>
                  )}
                  </motion.button>
                </form>
              )}
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

function LanguageToggle({ lang, setLang, className = "" }) {
  return (
    <div
      className={`inline-flex items-center rounded-full border border-slate-200 p-1 dark:border-slate-700 ${className}`}
    >
      {["en", "tr"].map((code) => (
        <button
          type="button"
          key={code}
          onClick={() => setLang(code)}
          className={`rounded-full px-3 py-1 text-xs font-semibold transition-colors ${
            lang === code
              ? "bg-[#06B6D4] text-white dark:text-[#0B0F19]"
              : "text-slate-500 hover:text-slate-900 dark:text-slate-400 dark:hover:text-white"
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
      type="button"
      onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
      className="flex h-8 w-8 items-center justify-center rounded-full border border-slate-200 text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-900 dark:border-slate-700 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-white"
      aria-label="Toggle theme"
    >
      {theme === "dark" ? (
        <Sun className="h-4 w-4" />
      ) : (
        <Moon className="h-4 w-4" />
      )}
    </button>
  );
}

function PhoneMockup({ src, alt }) {
  return (
    <div className="mx-auto w-full max-w-[320px] lg:mx-0">
      <motion.div
        animate={{ y: [0, -20, 0] }}
        transition={{
          repeat: Infinity,
          duration: 4,
          ease: "easeInOut",
        }}
        className="relative"
      >
        <motion.div
          animate={{
            opacity: [0.16, 0.34, 0.16],
            scale: [0.96, 1.05, 0.96],
          }}
          transition={{
            repeat: Infinity,
            duration: 4,
            ease: "easeInOut",
          }}
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
              <img
                src={src}
                alt={alt}
                className="h-full w-full object-contain"
              />
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

  const handleNavigate = (event, path) => {
    event.preventDefault();
    setOpen(false);
    navigate(path);
  };

  const links = [
    { label: t.nav.faq, href: "#faq" },
    {
      label: t.nav.privacy,
      href: "/privacy",
      internal: true,
    },
    {
      label: t.nav.terms,
      href: "/terms",
      internal: true,
    },
    {
      label: t.nav.support,
      href: "mailto:splixa.support@gmail.com",
    },
    {
      label: t.nav.deleteAccount,
      href: "/delete-account",
      internal: true,
    },
  ];

  return (
    <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/90 px-5 py-4 backdrop-blur-xl dark:border-white/5 dark:bg-[#0B0F19]/90">
      <div className="mx-auto flex max-w-6xl items-center justify-between">
        <a
          href="/"
          onClick={(event) => {
            event.preventDefault();

            if (window.location.pathname === "/") {
              window.scrollTo({
                top: 0,
                behavior: "smooth",
              });
            } else {
              handleNavigate(event, "/");
            }
          }}
          className="flex cursor-pointer items-center gap-2"
        >
          <img
            src="/splixa_logo.png"
            alt="Splixa logo"
            className="h-9 w-9 rounded-lg object-cover"
          />

          <span className="text-lg font-semibold tracking-tight text-slate-900 dark:text-white">
            Splixa
          </span>
          <span className="rounded-full border border-cyan-500/25 bg-cyan-500/10 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-[0.12em] text-cyan-700 dark:border-cyan-400/25 dark:bg-cyan-400/10 dark:text-cyan-300">
            Beta
          </span>
        </a>

        <nav className="hidden items-center gap-7 md:flex">
          {links.map((link) => (
            <a
              key={link.label}
              href={link.href}
              onClick={(event) => {
                if (link.internal) {
                  handleNavigate(event, link.href);
                }
              }}
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
            type="button"
            className="text-slate-600 dark:text-slate-300"
            onClick={() => setOpen((current) => !current)}
            aria-label="Toggle menu"
          >
            {open ? (
              <X className="h-6 w-6" />
            ) : (
              <Menu className="h-6 w-6" />
            )}
          </button>
        </div>
      </div>

      <AnimatePresence>
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
                  onClick={(event) => {
                    if (link.internal) {
                      handleNavigate(event, link.href);
                    } else {
                      setOpen(false);
                    }
                  }}
                  className="text-sm text-slate-700 dark:text-slate-200"
                >
                  {link.label}
                </a>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
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
          <div className="order-1">
            <MountReveal>
              <SectionEyebrow>{t.hero.eyebrow}</SectionEyebrow>
            </MountReveal>

            <MountReveal delay={0.1}>
              <h1 className="mt-6 max-w-xl text-5xl font-semibold leading-[1.05] tracking-tight text-slate-900 sm:text-6xl lg:text-7xl dark:text-white">
                {t.hero.titleLine1}
                <br />
                <span className="text-[#06B6D4]">
                  {t.hero.titleLine2}
                </span>
              </h1>
            </MountReveal>

            <MountReveal delay={0.2}>
              <p className="mt-6 max-w-md text-lg leading-relaxed text-slate-600 dark:text-slate-300">
                {t.hero.desc}
              </p>
            </MountReveal>

            <MountReveal delay={0.3}>
              <div className="mt-10 flex flex-col gap-3 sm:flex-row sm:items-center">
                <PlayStoreButton t={t} />

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

          <motion.div
            initial={{ opacity: 0, y: 28 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              duration: 0.7,
              ease: "easeOut",
              delay: 0.2,
            }}
            className="order-2 flex justify-center lg:justify-end"
          >
            <PhoneMockup
              src="/dashboard-ss.png"
              alt="Splixa dashboard screen"
            />
          </motion.div>
        </div>
      </div>
    </section>
  );
}

function ZigZagFeature({ item, meta, reverse }) {
  return (
    <div className="grid grid-cols-1 items-center gap-12 lg:grid-cols-2">
      <Reveal
        className={
          reverse
            ? "order-2 lg:order-2"
            : "order-2 lg:order-1"
        }
      >
        <SectionEyebrow>{item.eyebrow}</SectionEyebrow>

        <h3 className="mt-5 text-3xl font-semibold tracking-tight text-slate-900 sm:text-4xl lg:text-5xl dark:text-white">
          {item.title}
        </h3>

        <p className="mt-5 max-w-lg text-lg leading-relaxed text-slate-600 dark:text-slate-300">
          {item.desc}
        </p>

        <ul className="mt-7 space-y-4">
          {item.bullets.map((bullet) => (
            <li
              key={bullet}
              className="flex items-start gap-3 text-slate-700 dark:text-slate-200"
            >
              <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-cyan-500/10">
                <Check className="h-3.5 w-3.5 text-[#06B6D4]" />
              </span>

              <span className="text-base leading-relaxed">
                {bullet}
              </span>
            </li>
          ))}
        </ul>
      </Reveal>

      <Reveal
        delay={0.12}
        className={
          reverse
            ? "order-1 flex justify-center lg:order-1 lg:justify-end"
            : "order-1 flex justify-center lg:order-2 lg:justify-end"
        }
      >
        <PhoneMockup src={meta.image} alt={meta.imageAlt} />
      </Reveal>
    </div>
  );
}

function Features({ t }) {
  return (
    <section
      id="features"
      className="relative border-y border-slate-200 bg-slate-50 px-5 py-24 dark:border-white/5 dark:bg-[#111827] sm:py-32"
    >
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
            <ZigZagFeature
              key={item.title}
              item={item}
              meta={FEATURE_META[index]}
              reverse={index % 2 === 1}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

function FAQ({ t }) {
  const [openIndex, setOpenIndex] = useState(0);

  return (
    <section
      id="faq"
      className="relative px-5 py-24 sm:py-32"
    >
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
                    type="button"
                    onClick={() =>
                      setOpenIndex(isOpen ? -1 : index)
                    }
                    className="flex w-full items-center justify-between gap-4 py-6 text-left"
                  >
                    <span className="text-lg font-medium text-slate-900 dark:text-white">
                      {item.q}
                    </span>

                    <motion.span
                      animate={{
                        rotate: isOpen ? 180 : 0,
                        borderColor: isOpen
                          ? "#06B6D4"
                          : "var(--border-color)",
                      }}
                      className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-slate-300 text-slate-500 dark:border-slate-700 dark:text-slate-300"
                    >
                      <ChevronDown className="h-4 w-4" />
                    </motion.span>
                  </button>

                  <motion.div
                    initial={false}
                    animate={{
                      height: isOpen ? "auto" : 0,
                      opacity: isOpen ? 1 : 0,
                    }}
                    transition={{
                      duration: 0.28,
                      ease: "easeInOut",
                    }}
                    className="overflow-hidden"
                  >
                    <p className="max-w-2xl pb-6 text-base leading-relaxed text-slate-600 dark:text-slate-300">
                      {item.a}
                    </p>
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
  const handleNavigate = (event, path) => {
    event.preventDefault();
    navigate(path);
  };

  return (
    <section
      id="legal"
      className="border-t border-slate-200 bg-slate-50 px-5 py-24 dark:border-white/5 dark:bg-[#111827] sm:py-32"
    >
      <div className="mx-auto max-w-6xl">
        <Reveal className="max-w-2xl">
          <SectionEyebrow>
            {t.legalGrid.eyebrow}
          </SectionEyebrow>

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
          variants={{
            hidden: {},
            visible: {
              transition: {
                staggerChildren: 0.1,
              },
            },
          }}
          className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-4"
        >
          {t.legalGrid.cards.map((card, index) => {
            const Icon = ICONS[index];
            const isInternal = card.href.startsWith("/");

            return (
              <motion.a
                key={card.title}
                href={card.href}
                onClick={(event) => {
                  if (isInternal) {
                    handleNavigate(event, card.href);
                  }
                }}
                variants={{
                  hidden: { opacity: 0, y: 24 },
                  visible: { opacity: 1, y: 0 },
                }}
                transition={{
                  duration: 0.5,
                  ease: "easeOut",
                }}
                whileHover={{
                  y: -8,
                  borderColor: "#06B6D4",
                  boxShadow:
                    "0 0 30px rgba(6,182,212,0.24)",
                }}
                className="group rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-[#1E293B] dark:shadow-none"
              >
                <Icon className="h-6 w-6 text-[#06B6D4]" />

                <h3 className="mt-8 text-lg font-semibold text-slate-900 dark:text-white">
                  {card.title}
                </h3>

                <p className="mt-3 text-sm leading-6 text-slate-600 dark:text-slate-300">
                  {card.description}
                </p>

                <span className="mt-6 flex items-center gap-1 text-sm font-medium text-[#06B6D4]">
                  {t.legalGrid.open}

                  <ChevronRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                </span>
              </motion.a>
            );
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
            <img
              src="/splixa_logo.png"
              alt="Splixa logo"
              className="h-9 w-9 rounded-lg object-cover"
            />

            <span className="text-sm font-medium text-slate-900 dark:text-slate-200">
              Splixa
            </span>
          </div>

          <div className="text-center sm:text-left">
            <p className="text-sm font-medium text-slate-900 dark:text-white">
              {t.footer.contactTitle}
            </p>

            <a
              href="mailto:splixa.support@gmail.com"
              className="mt-1 inline-block text-sm text-[#06B6D4] hover:underline"
            >
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

function DeleteAccountPage({ t, navigate }) {
  const page = t.deleteAccountPage;
  const emailHref = `mailto:splixa.support@gmail.com?subject=${encodeURIComponent(page.emailSubject)}`;

  return (
    <div className="min-h-screen px-5 pb-32 pt-24">
      <div className="mx-auto max-w-4xl">
        <button
          type="button"
          onClick={() => {
            navigate("/");
            window.scrollTo(0, 0);
          }}
          className="mb-10 flex items-center gap-2 text-sm font-medium text-slate-500 transition-colors hover:text-slate-900 dark:text-slate-400 dark:hover:text-white"
        >
          <ArrowLeft className="h-4 w-4" />
          {t.legalPages.backToHome}
        </button>

        <MountReveal>
          <SectionEyebrow>{page.eyebrow}</SectionEyebrow>
          <h1 className="mt-5 text-4xl font-semibold tracking-tight text-slate-900 sm:text-5xl dark:text-white">
            {page.title}
          </h1>
          <p className="mt-5 max-w-3xl text-lg leading-8 text-slate-600 dark:text-slate-300">
            {page.intro}
          </p>
          <p className="mt-4 text-sm text-slate-500 dark:text-slate-400">
            {t.legalPages.lastUpdated}
          </p>
        </MountReveal>

        <div className="mt-12 grid gap-6 lg:grid-cols-2">
          <MountReveal className="h-full" delay={0.08}>
            <section className="h-full rounded-3xl border border-slate-200 bg-white p-7 shadow-sm dark:border-slate-700 dark:bg-[#1E293B] dark:shadow-none sm:p-8">
              <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-cyan-500/10 text-cyan-500">
                <Trash2 className="h-5 w-5" />
              </div>
              <h2 className="mt-6 text-2xl font-semibold text-slate-900 dark:text-white">
                {page.inAppTitle}
              </h2>
              <p className="mt-3 leading-7 text-slate-600 dark:text-slate-300">
                {page.inAppDescription}
              </p>
              <ol className="mt-7 space-y-4">
                {page.steps.map((step, index) => (
                  <li key={step} className="flex gap-3 text-sm leading-6 text-slate-700 dark:text-slate-200">
                    <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-cyan-500 text-xs font-bold text-white">
                      {index + 1}
                    </span>
                    <span>{step}</span>
                  </li>
                ))}
              </ol>
            </section>
          </MountReveal>

          <MountReveal className="h-full" delay={0.16}>
            <section className="h-full rounded-3xl border border-slate-200 bg-white p-7 shadow-sm dark:border-slate-700 dark:bg-[#1E293B] dark:shadow-none sm:p-8">
              <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-cyan-500/10 text-cyan-500">
                <LifeBuoy className="h-5 w-5" />
              </div>
              <h2 className="mt-6 text-2xl font-semibold text-slate-900 dark:text-white">
                {page.alternativeTitle}
              </h2>
              <p className="mt-3 leading-7 text-slate-600 dark:text-slate-300">
                {page.alternativeDescription}
              </p>
              <div className="mt-7 rounded-2xl bg-slate-50 p-4 dark:bg-slate-950/40">
                <p className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                  {page.supportLabel}
                </p>
                <a
                  href="mailto:splixa.support@gmail.com"
                  className="mt-1 inline-block break-all font-medium text-cyan-600 hover:underline dark:text-cyan-400"
                >
                  splixa.support@gmail.com
                </a>
              </div>
              <a
                href={emailHref}
                className="mt-6 inline-flex items-center gap-2 rounded-xl bg-cyan-500 px-5 py-3 text-sm font-semibold text-white shadow-lg shadow-cyan-500/20 transition hover:bg-cyan-400"
              >
                {page.emailButton}
                <ArrowRight className="h-4 w-4" />
              </a>
            </section>
          </MountReveal>
        </div>

        <MountReveal delay={0.24}>
          <section className="mt-6 rounded-3xl border border-cyan-500/20 bg-cyan-500/5 p-7 sm:p-8">
            <div className="flex gap-4">
              <ShieldCheck className="mt-1 h-6 w-6 shrink-0 text-cyan-500" />
              <div>
                <h2 className="text-xl font-semibold text-slate-900 dark:text-white">
                  {page.afterTitle}
                </h2>
                <p className="mt-3 leading-7 text-slate-600 dark:text-slate-300">
                  {page.afterDescription}
                </p>
              </div>
            </div>
          </section>
        </MountReveal>
      </div>
    </div>
  );
}

function LegalPageTemplate({ title, content, t, navigate }) {
  return (
    <div className="min-h-screen px-5 pb-32 pt-24">
      <div className="mx-auto max-w-3xl">
        <button
          type="button"
          onClick={() => {
            navigate("/");
            window.scrollTo(0, 0);
          }}
          className="mb-10 flex items-center gap-2 text-sm font-medium text-slate-500 transition-colors hover:text-slate-900 dark:text-slate-400 dark:hover:text-white"
        >
          <ArrowLeft className="h-4 w-4" />
          {t.legalPages.backToHome}
        </button>

        <h1 className="mb-4 text-4xl font-semibold tracking-tight text-slate-900 dark:text-white">
          {title}
        </h1>

        <p className="mb-12 text-sm text-slate-500 dark:text-slate-400">
          {t.legalPages.lastUpdated}
        </p>

        <div className="prose max-w-none whitespace-pre-wrap leading-loose text-slate-700 dark:prose-invert dark:text-slate-300">
          {content}
        </div>
      </div>
    </div>
  );
}

export default function SplixaApp() {
  const [lang, setLang] = useState("en");
  const [theme, setTheme] = useState(() =>
    window.matchMedia?.("(prefers-color-scheme: light)").matches
      ? "light"
      : "dark",
  );
  const [currentPath, setCurrentPath] = useState(
    window.location.pathname,
  );
  const [isModalOpen, setIsModalOpen] = useState(true);

  const t = translations[lang];

  const closeWaitlist = useCallback(() => {
    setIsModalOpen(false);
  }, []);

  const openWaitlist = useCallback(() => {
    setIsModalOpen(true);
  }, []);

  useEffect(() => {
    const onLocationChange = () => {
      setCurrentPath(window.location.pathname);
    };

    window.addEventListener("popstate", onLocationChange);

    return () => {
      window.removeEventListener(
        "popstate",
        onLocationChange,
      );
    };
  }, []);

  const navigate = (path) => {
    window.history.pushState({}, "", path);
    setCurrentPath(path);
    window.scrollTo(0, 0);
  };

  useEffect(() => {
    const root = window.document.documentElement;

    if (theme === "dark") {
      root.classList.add("dark");
    } else {
      root.classList.remove("dark");
    }
  }, [theme]);


  let content;

  if (currentPath === "/privacy") {
    content = (
      <LegalPageTemplate
        title={t.legalPages.privacyTitle}
        content={t.legalPages.privacyBody}
        t={t}
        navigate={navigate}
      />
    );
  } else if (currentPath === "/terms") {
    content = (
      <LegalPageTemplate
        title={t.legalPages.termsTitle}
        content={t.legalPages.termsBody}
        t={t}
        navigate={navigate}
      />
    );
  } else if (currentPath === "/delete-account") {
    content = <DeleteAccountPage t={t} navigate={navigate} />;
  } else {
    content = (
      <>
        <Hero t={t} />
        <Features t={t} />
        <FAQ t={t} />
        <LegalGrid t={t} navigate={navigate} />
      </>
    );
  }

  return (
    <div
      className="min-h-screen w-full bg-white text-slate-900 transition-colors duration-300 dark:bg-[#0B0F19] dark:text-[#F8FAFC]"
      style={{ fontFamily: "'Inter', sans-serif" }}
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
        html { scroll-behavior: smooth; }
      `}</style>

      <AnnouncementBar
        t={t}
        onJoinWaitlist={openWaitlist}
      />

      <Nav
        t={t}
        lang={lang}
        setLang={setLang}
        theme={theme}
        setTheme={setTheme}
        navigate={navigate}
      />

      {content}

      <Footer t={t} />

      {currentPath === "/" && (
        <WaitlistModal
          t={t}
          isOpen={isModalOpen}
          onClose={closeWaitlist}
        />
      )}

      <Analytics />
    </div>
  );
}