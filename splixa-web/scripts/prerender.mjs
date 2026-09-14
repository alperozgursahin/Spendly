/**
 * Build sonrası prerender.
 *
 * Vite tek bir dist/index.html üretir; bu script onu her React rotası için
 * kendi <title>, meta description, canonical, OpenGraph ve statik gövdesiyle
 * ayrı bir HTML dosyasına dönüştürür. Böylece /privacy artık "ben ana
 * sayfayım" demeyi bırakır ve JavaScript çalıştırmayan tarayıcılar her
 * rotada o rotanın gerçek metnini okur.
 *
 * Metin tek kaynaktan gelir: src/content/translations.js
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { translations } from "../src/content/translations.js";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DIST = join(ROOT, "dist");
const ORIGIN = "https://splixa.net";
const en = translations.en;

const esc = (s) =>
  String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

/** Düz metni (1. Başlık / paragraf) semantik HTML'e çevirir. */
function textToHtml(raw) {
  return String(raw)
    .trim()
    .split(/\n\s*\n/)
    .map((b) => b.trim())
    .filter(Boolean)
    .map((b) =>
      /^\d+\.\s+\S/.test(b) && !b.includes("\n")
        ? `<h2>${esc(b)}</h2>`
        : `<p>${esc(b).replace(/\n/g, " ")}</p>`,
    )
    .join("\n          ");
}

const d = en.deleteAccountPage;

const ROUTES = [
  {
    path: "/privacy",
    title: "Privacy Policy — Splixa",
    description:
      "How Splixa collects, uses and protects your data. Splixa never asks for banking credentials and does not connect to bank accounts.",
    body: `<h1>${esc(en.legalPages.privacyTitle)}</h1>
          ${textToHtml(en.legalPages.privacyBody)}`,
  },
  {
    path: "/terms",
    title: "Terms of Service — Splixa",
    description:
      "The terms that apply when you download and use the Splixa bill splitting and budget tracking app.",
    body: `<h1>${esc(en.legalPages.termsTitle)}</h1>
          ${textToHtml(en.legalPages.termsBody)}`,
  },
  {
    path: "/delete-account",
    title: "Delete Your Splixa Account",
    description:
      "Delete your Splixa account and all associated data permanently, from inside the app or by email request.",
    body: `<h1>${esc(d.title)}</h1>
          <p>${esc(d.intro)}</p>
          <h2>${esc(d.inAppTitle)}</h2>
          <p>${esc(d.inAppDescription)}</p>
          <ol>${d.steps.map((s) => `<li>${esc(s)}</li>`).join("")}</ol>
          <h2>${esc(d.alternativeTitle)}</h2>
          <p>${esc(d.alternativeDescription)}</p>
          <h2>${esc(d.afterTitle)}</h2>
          <p>${esc(d.afterDescription)}</p>`,
  },
];

/** index.html şablonunda tek bir etiketin içeriğini değiştirir. */
function swap(html, pattern, replacement, label) {
  if (!pattern.test(html)) throw new Error(`prerender: ${label} bulunamadı`);
  return html.replace(pattern, replacement);
}

const template = readFileSync(join(DIST, "index.html"), "utf8");

for (const r of ROUTES) {
  const url = `${ORIGIN}${r.path}`;
  let html = template;

  html = swap(html, /<title>[\s\S]*?<\/title>/, `<title>${esc(r.title)}</title>`, "title");
  html = swap(
    html,
    /<meta\s+name="description"[\s\S]*?\/>/,
    `<meta name="description" content="${esc(r.description)}" />`,
    "description",
  );
  html = swap(
    html,
    /<link rel="canonical"[^>]*>/,
    `<link rel="canonical" href="${url}" />`,
    "canonical",
  );
  html = swap(
    html,
    /<meta\s+property="og:title"[\s\S]*?\/>/,
    `<meta property="og:title" content="${esc(r.title)}" />`,
    "og:title",
  );
  html = swap(
    html,
    /<meta\s+property="og:description"[\s\S]*?\/>/,
    `<meta property="og:description" content="${esc(r.description)}" />`,
    "og:description",
  );
  html = swap(
    html,
    /<meta property="og:url"[^>]*>/,
    `<meta property="og:url" content="${url}" />`,
    "og:url",
  );

  // Alt sayfalar arama sonuçlarında ana sayfayla yarışmasın.
  html = html.replace(
    /<meta\s+name="robots"[\s\S]*?\/>/,
    `<meta name="robots" content="noindex, follow" />`,
  );

  // Ana sayfanın FAQ/SoftwareApplication şeması yalnızca ana sayfaya ait.
  html = html.replace(
    /<script type="application\/ld\+json">[\s\S]*?<\/script>/,
    `<script type="application/ld+json">
      {
        "@context": "https://schema.org",
        "@type": "WebPage",
        "@id": "${url}",
        "url": "${url}",
        "name": ${JSON.stringify(r.title)},
        "description": ${JSON.stringify(r.description)},
        "inLanguage": "en",
        "isPartOf": { "@id": "${ORIGIN}/#website" },
        "publisher": { "@id": "${ORIGIN}/#organization" }
      }
    </script>`,
  );

  // Statik bot gövdesini bu rotanın gerçek içeriğiyle değiştir.
  html = swap(
    html,
    /<div id="root">[\s\S]*?<\/div>\s*(?=\n\s*<!--|\n\s*<script)/,
    `<div id="root">
      <main>
          ${r.body}
      </main>
      <footer>
        <p><a href="/">Splixa</a> &middot; <a href="/privacy">Privacy</a> &middot; <a href="/terms">Terms</a> &middot; <a href="/delete-account">Delete Account</a></p>
        <p>&copy; 2026 Splixa Labs</p>
      </footer>
    </div>\n\n    `,
    "#root fallback",
  );

  const out = join(DIST, r.path.slice(1), "index.html");
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, html, "utf8");
  console.log(`prerender  ${r.path.padEnd(18)} -> dist${r.path}/index.html`);
}

console.log(`prerender  ${ROUTES.length} rota yazildi`);

/* ------------------------------------------------------------------ *
 * Statik içerik sayfaları (React'siz, tamamen kendi kendine yeten)
 * ------------------------------------------------------------------ */
import { contentPages, PLAY } from "./content-pages.mjs";

const SHELL_CSS = `
:root{--bg:#fbfdfd;--fg:#13202b;--muted:#5b7180;--line:#dde7eb;--surface:#fff;--accent:#0b7e96;--accent-bg:#e4f4f8;--note:#fbf3e3;--note-line:#d9ad5a}
@media(prefers-color-scheme:dark){:root{--bg:#080c13;--fg:#e2ebf0;--muted:#8ca3b1;--line:#22303d;--surface:#0e151e;--accent:#3fd5ec;--accent-bg:#0b2730;--note:#1d1708;--note-line:#7a5f1c}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.65 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased}
.wrap{max-width:760px;margin:0 auto;padding:0 20px 80px}
a{color:var(--accent)}
header.site{border-bottom:1px solid var(--line);margin-bottom:40px}
header.site .wrap{padding-block:18px;display:flex;flex-wrap:wrap;gap:8px 22px;align-items:center;padding-bottom:18px}
header.site a{text-decoration:none;color:var(--muted);font-size:14px}
header.site a.brand{color:var(--fg);font-weight:700;font-size:18px;letter-spacing:-.02em;margin-right:6px}
header.site a:hover{color:var(--accent)}
h1{font-size:clamp(28px,5vw,40px);line-height:1.12;letter-spacing:-.025em;margin:0 0 16px;text-wrap:balance}
h2{font-size:clamp(19px,3vw,23px);line-height:1.25;letter-spacing:-.015em;margin:40px 0 12px;text-wrap:balance}
p{margin:0 0 16px}
.lede{font-size:18px;color:var(--muted);margin-bottom:8px}
.meta{font-size:13px;color:var(--muted);margin:0 0 32px;padding-bottom:20px;border-bottom:1px solid var(--line)}
ul,ol{margin:0 0 16px;padding-left:22px}
li{margin-bottom:8px}
.note{background:var(--note);border-left:3px solid var(--note-line);padding:14px 16px;border-radius:0 5px 5px 0;font-size:14.5px;margin:0 0 22px}
.tw{overflow-x:auto;border:1px solid var(--line);border-radius:7px;margin:0 0 22px;background:var(--surface)}
table{border-collapse:collapse;width:100%;min-width:560px;font-size:14px}
th{text-align:left;font-size:12px;letter-spacing:.04em;text-transform:uppercase;color:var(--muted);padding:10px 13px;border-bottom:1px solid var(--line);white-space:nowrap}
td{padding:10px 13px;border-bottom:1px solid var(--line);vertical-align:top}
tbody tr:last-child td{border-bottom:none}
tbody td:first-child{font-weight:600}
.faq{border-top:1px solid var(--line)}
.faq>div{border-bottom:1px solid var(--line);padding:16px 0}
.faq h3{margin:0 0 6px;font-size:16px;line-height:1.35}
.faq p{margin:0;color:var(--muted);font-size:15px}
.cta{display:inline-block;margin-top:14px;background:var(--accent-bg);border:1px solid var(--accent);color:var(--accent);
  padding:11px 20px;border-radius:7px;text-decoration:none;font-weight:600;font-size:15px}
footer.site{margin-top:56px;padding-top:22px;border-top:1px solid var(--line);font-size:13.5px;color:var(--muted)}
footer.site a{color:var(--muted)}
`.trim();

function renderBlocks(blocks) {
  const out = [];
  for (const b of blocks) {
    if (b.h2) out.push(`<h2>${esc(b.h2)}</h2>`);
    else if (b.p) out.push(`<p>${b.p}</p>`);
    else if (b.note) out.push(`<p class="note">${b.note}</p>`);
    else if (b.ul) out.push(`<ul>${b.ul.map((x) => `<li>${x}</li>`).join("")}</ul>`);
    else if (b.ol) out.push(`<ol>${b.ol.map((x) => `<li>${x}</li>`).join("")}</ol>`);
    else if (b.table) {
      const { head, rows } = b.table;
      out.push(
        `<div class="tw"><table><thead><tr>${head
          .map((h) => `<th>${esc(h)}</th>`)
          .join("")}</tr></thead><tbody>${rows
          .map((r) => `<tr>${r.map((c) => `<td>${esc(c)}</td>`).join("")}</tr>`)
          .join("")}</tbody></table></div>`,
      );
    } else if (b.faq) {
      out.push(
        `<div class="faq">${b.faq
          .map(([q, a]) => `<div><h3>${esc(q)}</h3><p>${esc(a)}</p></div>`)
          .join("")}</div>`,
      );
    }
  }
  return out.join("\n        ");
}

function pageSchema(page) {
  const url = `${ORIGIN}${page.path}`;
  const nodes = [
    {
      "@type": page.path.startsWith("/blog/") ? "Article" : "WebPage",
      "@id": url,
      url,
      name: page.title,
      headline: page.title,
      description: page.description,
      inLanguage: "en",
      datePublished: page.updated,
      dateModified: page.updated,
      isPartOf: { "@id": `${ORIGIN}/#website` },
      publisher: { "@id": `${ORIGIN}/#organization` },
      author: { "@id": `${ORIGIN}/#organization` },
      about: { "@id": `${ORIGIN}/#app` },
    },
  ];
  const faq = page.blocks.find((b) => b.faq);
  if (faq) {
    nodes.push({
      "@type": "FAQPage",
      "@id": `${url}#faq`,
      isPartOf: { "@id": url },
      mainEntity: faq.faq.map(([q, a]) => ({
        "@type": "Question",
        name: q,
        acceptedAnswer: { "@type": "Answer", text: a },
      })),
    });
  }
  return JSON.stringify({ "@context": "https://schema.org", "@graph": nodes }, null, 2);
}

for (const page of contentPages) {
  const url = `${ORIGIN}${page.path}`;
  const html = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="icon" type="image/png" href="/splixa_logo.png?v=2" />
    <title>${esc(page.title)}</title>
    <meta name="description" content="${esc(page.description)}" />
    <link rel="canonical" href="${url}" />
    <meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large" />
    <meta property="og:site_name" content="Splixa" />
    <meta property="og:title" content="${esc(page.title)}" />
    <meta property="og:description" content="${esc(page.description)}" />
    <meta property="og:type" content="${page.path.startsWith("/blog/") ? "article" : "website"}" />
    <meta property="og:url" content="${url}" />
    <meta property="og:image" content="${ORIGIN}/og-cover.png" />
    <meta property="og:image:width" content="1200" />
    <meta property="og:image:height" content="630" />
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="${esc(page.title)}" />
    <meta name="twitter:description" content="${esc(page.description)}" />
    <meta name="twitter:image" content="${ORIGIN}/og-cover.png" />
    <style>${SHELL_CSS}</style>
    <script type="application/ld+json">
${pageSchema(page)}
    </script>
  </head>
  <body>
    <header class="site">
      <div class="wrap">
        <a class="brand" href="/">Splixa</a>
        <a href="/pricing">Pricing</a>
        <a href="/alternatives/splitwise">vs Splitwise</a>
        <a href="/blog/best-splitwise-alternatives">Alternatives</a>
        <a href="${PLAY}" rel="noopener">Get the app</a>
      </div>
    </header>
    <div class="wrap">
      <main>
        <h1>${esc(page.h1)}</h1>
        <p class="lede">${esc(page.lede)}</p>
        <p class="meta">Last updated: ${esc(page.updated)} &middot; Splixa Labs</p>
        ${renderBlocks(page.blocks)}
        <p><a class="cta" href="${PLAY}" rel="noopener">Get Splixa free on Google Play</a></p>
      </main>
      <footer class="site">
        <p><a href="/">Splixa</a> &middot; <a href="/pricing">Pricing</a> &middot;
           <a href="/privacy">Privacy</a> &middot; <a href="/terms">Terms</a> &middot;
           <a href="/delete-account">Delete account</a></p>
        <p>&copy; 2026 Splixa Labs &middot; splixa.support@gmail.com</p>
      </footer>
    </div>
  </body>
</html>
`;
  const out = join(DIST, page.path.slice(1), "index.html");
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, html, "utf8");
  console.log(`content    ${page.path.padEnd(38)} -> dist${page.path}/index.html`);
}

console.log(`content    ${contentPages.length} statik sayfa yazildi`);
