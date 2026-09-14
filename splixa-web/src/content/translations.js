// Tek kaynak: hem React uygulaması (App.jsx) hem de build script'i
// (scripts/prerender.mjs) bu dosyayı okur. React bağımlılığı yoktur,
// bu yüzden Node doğrudan import edebilir. Metni SADECE burada değiştirin.

export const translations = {
  en: {
    announcement:
      "Splixa is now in beta — join the beta and help shape what comes next.",
    waitlist: {
      eyebrow: "BETA ACCESS",
      title: "Join the Splixa Beta.",
      description:
        "Join our beta community for early access, product updates and a chance to help shape the future of Splixa.",
      emailPlaceholder: "Enter your email address",
      button: "Join the Beta",
      submitting: "Joining the beta...",
      success: "Welcome to the Splixa Beta!",
      error: "We couldn't add you right now. Please try again.",
      close: "Close beta signup modal",
      emailLabel: "Email address",
    },
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
      desc: "Splixa tracks shared expenses for trips, roommates and squads while helping you manage your personal budget in one simple app.",
      ctaPrimary: "Download from Play Store",
      ctaSecondary: "Explore features",
      stats: [
        ["No", "Bank linking"],
        ["Zero", "Hidden fees"],
        ["100%", "Data control"],
      ],
    },
    features: {
      eyebrow: "THE SELLING POINTS",
      title: "Everything money should feel like",
      subtitle:
        "Built for shared expenses and personal budgets. Not spreadsheets.",
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
          eyebrow: "PERSONAL BUDGET & ANALYTICS",
          title: "See your money, not just your statements",
          desc: "Track your personal budget and use monthly category distribution charts to turn a wall of transactions into a picture you understand at a glance.",
          bullets: [
            "Track your personal income, expenses and budget",
            "Monthly category breakdowns show exactly where money goes",
            "Use interactive charts to discover spending patterns",
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
          a: "Splixa never asks for your banking credentials and does not connect to your bank account, so there are no bank logins to store. You enter expenses yourself or scan them from a receipt. Data is encrypted in transit with TLS and stored with row-level security policies, so only you and the people in your groups can read it. You can delete your account and all of its data at any time.",
        },
        {
          q: "How does group splitting work?",
          a: "Create a group, add the people involved and log an expense. Splixa automatically calculates a Net Summary showing exactly who owes whom.",
        },
        {
          q: "Can I track my personal budget?",
          a: "Yes. Splixa is not only a group expense splitter. You can also track your personal expenses, understand your spending categories and manage your budget.",
        },
        {
          q: "Is Splixa free to use?",
          a: "Yes. Core splitting, personal budget tracking, the dashboard and basic analytics are free.",
        },
      ],
    },
    legalGrid: {
      eyebrow: "HELP & LEGAL",
      title: "Everything you need, clearly available.",
      desc: "Your privacy and control matter. Find policies, support and account options in one place.",
      open: "Open",
      cards: [
        {
          title: "Privacy Policy",
          description:
            "Learn how Splixa collects, protects and handles your data.",
          href: "/privacy",
        },
        {
          title: "Terms of Service",
          description:
            "The straightforward terms for using Splixa services.",
          href: "/terms",
        },
        {
          title: "Support",
          description:
            "Get answers, report an issue or ask our team for help.",
          href: "mailto:splixa.support@gmail.com",
        },
        {
          title: "Delete Account",
          description:
            "Request deletion of your Splixa account and data.",
          href: "/delete-account",
        },
      ],
    },
    legalPages: {
      backToHome: "Back to Home",
      lastUpdated: "Last updated: July 2026",
      privacyTitle: "Privacy Policy",
      privacyBody: `
At Splixa Labs, we take your privacy seriously. This Privacy Policy explains how we collect, use and protect your information when you use the Splixa mobile application.

1. Information We Collect

We only collect information necessary to provide our services. This includes your name, email address and the expense data you voluntarily enter into the app, such as group names and transaction amounts.

2. Data Security

Splixa does not ask for, process or store your bank account or credit card credentials, and never connects to your bank. Traffic between the app and our servers is encrypted in transit using TLS. Your records are stored in a managed PostgreSQL database protected by row-level security policies, so each account can read only its own data and the groups it belongs to, and the database is encrypted at rest by our hosting provider.

3. Account Deletion (Right to be Forgotten)

You have complete control over your data. You can request permanent deletion of your account and all associated financial records at any time by emailing splixa.support@gmail.com with the subject "Delete my Splixa account".

4. Third-Party Sharing

We do not sell your personal data to advertisers.
      `,
      termsTitle: "Terms of Service",
      termsBody: `
By downloading or using the Splixa application, these terms will automatically apply to you. You should therefore read them carefully before using the app.

1. Use of the App

Splixa is designed to help individuals manage personal budgets and help friends and groups track shared expenses. While we strive for mathematical accuracy, Splixa Labs is not legally responsible for real-world financial disputes between users.

2. User Conduct

You agree not to use the app in any way that is illegal or harmful. You must not attempt to extract the source code of the app or create derivative versions without our explicit permission.

3. Limitations of Liability

Splixa Labs will not be liable for any direct, indirect or consequential loss or damage arising under these terms or in connection with our application.

If you have any questions about these Terms, please contact us at splixa.support@gmail.com.
      `,
    },
    deleteAccountPage: {
      eyebrow: "ACCOUNT & DATA CONTROL",
      title: "Delete your Splixa account",
      intro:
        "You can permanently delete your Splixa account and associated data at any time. Choose the method that works for you below.",
      inAppTitle: "Delete directly in the app",
      inAppDescription:
        "If you can access your account, deletion can be completed immediately from the Splixa mobile app.",
      steps: [
        "Open Splixa and sign in to your account.",
        "Go to Profile and open Settings.",
        "Select Delete Account / Delete Account Data.",
        "Review the warning and confirm permanent deletion.",
      ],
      alternativeTitle: "Can’t access the app?",
      alternativeDescription:
        "Send a deletion request from your registered email address. Include your registered username and email address so we can securely identify the correct account.",
      emailButton: "Email a deletion request",
      emailSubject: "Delete my Splixa account",
      afterTitle: "What happens after your request",
      afterDescription:
        "After confirming account ownership, your account and associated personal data will be permanently deleted within a reasonable period. Limited records may be retained only when required by law, security, fraud prevention, or financial compliance obligations.",
      supportLabel: "Deletion request email",
    },
    footer: {
      contactTitle: "Contact",
      security: "No bank linking",
      rights: "© 2026 Splixa Labs",
    },
  },

  tr: {
    announcement:
      "Splixa şimdi beta sürümünde — betaya katıl ve gelişimine yön ver.",
    waitlist: {
      eyebrow: "BETA ERİŞİMİ",
      title: "Splixa Beta'ya katıl.",
      description:
        "Erken erişim, ürün güncellemeleri ve Splixa'nın geleceğine yön verme fırsatı için beta topluluğumuza katıl.",
      emailPlaceholder: "E-posta adresini gir",
      button: "Beta Programına Katıl",
      submitting: "Betaya katılınıyor...",
      success: "Splixa Beta'ya hoş geldin!",
      error: "\u015eu anda kayd\u0131n\u0131 olu\u015fturamad\u0131k. L\u00fctfen tekrar dene.",
      close: "Beta katılım penceresini kapat",
      emailLabel: "E-posta adresi",
    },
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
      desc: "Splixa; gezilerde, ev arkadaşlarında ve gruplarda ortak harcamaları takip ederken kişisel bütçeni de tek bir uygulamada yönetmene yardımcı olur.",
      ctaPrimary: "Google Play'den indir",
      ctaSecondary: "Özellikleri keşfet",
      stats: [
        ["Yok", "Banka bağlantısı"],
        ["Sıfır", "Gizli Ücret"],
        ["%100", "Veri Kontrolü"],
      ],
    },
    features: {
      eyebrow: "ÖNE ÇIKAN ÖZELLİKLER",
      title: "Para yönetimi böyle hissettirmeli",
      subtitle:
        "Ortak harcamalar ve kişisel bütçeler için tasarlandı. Excel tabloları için değil.",
      items: [
        {
          eyebrow: "GRUP BÖLÜŞÜMÜ",
          title: "Arkadaş ekle. Adil böl. Bitti.",
          desc: "Herhangi bir gezi ya da ev için grup oluştur, ortak harcama gir ve kimin dahil olduğunu seç. Splixa hesabı anında yapar.",
          bullets: [
            "Herhangi bir gezi ya da ev için saniyeler içinde grup oluştur",
            "Ortak harcamaları ekle, kimin dahil olacağını seç",
            "Kimin kime ne kadar borçlu olduğunu gösteren Net Özet al",
          ],
        },
        {
          eyebrow: "KİŞİSEL BÜTÇE VE ANALİZ",
          title: "Sadece ekstreni değil, paranı gör",
          desc: "Kişisel bütçeni takip et ve aylık kategori grafikleriyle harcamalarını tek bakışta anlayabileceğin bir görünüme dönüştür.",
          bullets: [
            "Kişisel gelirlerini, giderlerini ve bütçeni takip et",
            "Aylık kategori dağılımları paranın nereye gittiğini gösterir",
            "Etkileşimli grafiklerle harcama alışkanlıklarını keşfet",
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
          a: "Splixa banka giriş bilgilerinizi istemez ve banka hesabınıza bağlanmaz — saklanacak bir banka girişi yoktur. Harcamaları siz girersiniz ya da fişten taratırsınız. Veriler aktarım sırasında TLS ile şifrelenir ve satır düzeyi güvenlik politikalarıyla saklanır; yalnızca siz ve gruplarınızdaki kişiler okuyabilir. Hesabınızı ve tüm verilerinizi dilediğiniz an silebilirsiniz.",
        },
        {
          q: "Grup bölüşümü nasıl çalışır?",
          a: "Bir grup oluştur, dahil olan kişileri ekle ve bir harcama gir. Splixa kimin kime ne kadar borçlu olduğunu otomatik olarak hesaplar.",
        },
        {
          q: "Kişisel bütçemi takip edebilir miyim?",
          a: "Evet. Splixa yalnızca bir grup harcaması bölüştürme uygulaması değildir. Kişisel harcamalarını takip edebilir, harcama kategorilerini inceleyebilir ve bütçeni yönetebilirsin.",
        },
        {
          q: "Splixa ücretsiz mi?",
          a: "Evet. Temel bölüşüm, kişisel bütçe takibi, kontrol paneli ve temel analizler ücretsizdir.",
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
          description:
            "Splixa'nın verilerini nasıl topladığını ve koruduğunu öğren.",
          href: "/privacy",
        },
        {
          title: "Kullanım Koşulları",
          description:
            "Splixa hizmetlerini kullanmanın anlaşılır kuralları.",
          href: "/terms",
        },
        {
          title: "Destek",
          description:
            "Cevap bul, sorun bildir veya ekibimizden yardım iste.",
          href: "mailto:splixa.support@gmail.com",
        },
        {
          title: "Hesabı Sil",
          description:
            "Splixa hesabının ve verilerinin silinmesini talep et.",
          href: "/delete-account",
        },
      ],
    },
    legalPages: {
      backToHome: "Ana Sayfaya Dön",
      lastUpdated: "Son güncelleme: Temmuz 2026",
      privacyTitle: "Gizlilik Politikası",
      privacyBody: `
Splixa Labs olarak gizliliğinize büyük önem veriyoruz. Bu Gizlilik Politikası, Splixa mobil uygulamasını kullandığınızda bilgilerinizi nasıl topladığımızı, kullandığımızı ve koruduğumuzu açıklar.

1. Topladığımız Bilgiler

Yalnızca hizmetlerimizi sağlamak için gerekli olan bilgileri toplarız. Bunlar arasında adınız, e-posta adresiniz ve uygulamaya kendi isteğinizle girdiğiniz grup adları ve işlem tutarları gibi harcama verileri bulunur.

2. Veri Güvenliği

Splixa banka hesabı veya kredi kartı bilgilerinizi istemez, işlemez ve saklamaz; bankanıza hiçbir şekilde bağlanmaz. Uygulama ile sunucularımız arasındaki tüm trafik TLS ile şifrelenir. Kayıtlarınız, satır düzeyi güvenlik politikalarıyla korunan yönetilen bir PostgreSQL veritabanında tutulur; böylece her hesap yalnızca kendi verisini ve üyesi olduğu grupları okuyabilir. Veritabanı, barındırma sağlayıcımız tarafından bekleyen veride şifrelenir.

3. Hesap Silme (Unutulma Hakkı)

Verileriniz üzerinde tam kontrole sahipsiniz. Hesabınızın ve ilgili tüm finansal kayıtlarınızın kalıcı olarak silinmesini istediğiniz zaman "Delete my Splixa account" konu başlığıyla splixa.support@gmail.com adresine e-posta gönderebilirsiniz.

4. Üçüncü Taraflarla Paylaşım

Kişisel verilerinizi reklamverenlere veya üçüncü taraflara satmıyoruz.
      `,
      termsTitle: "Kullanım Koşulları",
      termsBody: `
Splixa uygulamasını indirerek veya kullanarak bu koşulları otomatik olarak kabul etmiş olursunuz. Bu nedenle uygulamayı kullanmadan önce lütfen bu koşulları dikkatlice okuyun.

1. Uygulamanın Kullanımı

Splixa, kişilerin bütçelerini yönetmelerine ve arkadaşlar ile grupların ortak harcamalarını takip etmelerine yardımcı olmak için tasarlanmıştır. Matematiksel doğruluk sağlamaya çalışsak da Splixa Labs, kullanıcılar arasındaki gerçek dünyadaki finansal anlaşmazlıklardan yasal olarak sorumlu tutulamaz.

2. Kullanıcı Davranışları

Uygulamayı yasa dışı veya zararlı bir şekilde kullanmamayı kabul edersiniz. Açık iznimiz olmadan uygulamanın kaynak kodunu çıkarmaya çalışmamalı veya türev sürümlerini oluşturmamalısınız.

3. Sorumluluğun Sınırlandırılması

Splixa Labs, bu koşullar veya uygulamamızla bağlantılı olarak ortaya çıkan doğrudan, dolaylı veya sonuç olarak ortaya çıkan kayıp ya da hasarlardan sorumlu olmayacaktır.

Bu koşullarla ilgili sorularınız için splixa.support@gmail.com adresinden bizimle iletişime geçebilirsiniz.
      `,
    },
    deleteAccountPage: {
      eyebrow: "HESAP VE VERİ KONTROLÜ",
      title: "Splixa hesabınızı silin",
      intro:
        "Splixa hesabınızı ve hesabınızla ilişkili verileri istediğiniz zaman kalıcı olarak silebilirsiniz. Size uygun yöntemi aşağıdan seçebilirsiniz.",
      inAppTitle: "Uygulama içinden doğrudan silme",
      inAppDescription:
        "Hesabınıza erişebiliyorsanız silme işlemini Splixa mobil uygulamasından anında tamamlayabilirsiniz.",
      steps: [
        "Splixa’yı açın ve hesabınıza giriş yapın.",
        "Profil bölümüne gidin ve Ayarlar’ı açın.",
        "Hesabı Sil / Hesap Verilerini Sil seçeneğini seçin.",
        "Uyarıyı inceleyin ve kalıcı silme işlemini onaylayın.",
      ],
      alternativeTitle: "Uygulamaya erişemiyor musunuz?",
      alternativeDescription:
        "Kayıtlı e-posta adresinizden bir silme talebi gönderin. Doğru hesabı güvenli biçimde belirleyebilmemiz için kayıtlı kullanıcı adınızı ve e-posta adresinizi mesaja ekleyin.",
      emailButton: "Silme talebi gönder",
      emailSubject: "Splixa hesabımı silin",
      afterTitle: "Talebinizden sonra ne olur?",
      afterDescription:
        "Hesap sahipliği doğrulandıktan sonra hesabınız ve ilişkili kişisel verileriniz makul bir süre içinde kalıcı olarak silinir. Yalnızca yasal, güvenlik, dolandırıcılığı önleme veya finansal uyumluluk yükümlülükleri gerektiriyorsa sınırlı kayıtlar tutulabilir.",
      supportLabel: "Silme talebi e-postası",
    },
    footer: {
      contactTitle: "İletişim",
      security: "Banka bağlantısı yok",
      rights: "© 2026 Splixa Labs",
    },
  },
};
