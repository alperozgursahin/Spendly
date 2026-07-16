import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_provider.dart';

/// Looks up [key] in [AppStrings.values] for the language currently held by
/// [appLanguageProvider]. Every screen in this app is a Consumer/ConsumerState,
/// so a [WidgetRef] is always available where this is called.
String tr(WidgetRef ref, String key) {
  final language = ref.watch(appLanguageProvider);
  return AppStrings.of(key, language);
}

/// Predefined category values are stored/compared in their canonical Turkish
/// form (see the `predefinedCategories` lists in dashboard/add-expense
/// screens); this only translates the label shown to the user. Custom
/// (user-typed) categories pass through unchanged.
const _categoryKeysByCategory = {
  'Market': 'category_market',
  'Yemek': 'category_food',
  'Ulaşım': 'category_transport',
  'Eğlence': 'category_entertainment',
  'Maaş': 'category_salary',
  'Aidat': 'category_dues',
  'Fatura': 'category_bill',
  'Diğer': 'category_other',
};

String categoryLabel(WidgetRef ref, String category) {
  final key = _categoryKeysByCategory[category];
  return key == null ? category : tr(ref, key);
}

/// Same as [categoryLabel] but for call sites (e.g. the PDF export service)
/// that only have an [AppLanguage] on hand rather than a [WidgetRef].
String categoryLabelForLanguage(AppLanguage language, String category) {
  final key = _categoryKeysByCategory[category];
  return key == null ? category : AppStrings.of(key, language);
}

class AppStrings {
  static String of(String key, AppLanguage language) {
    final entry = values[key];
    if (entry == null) return key;
    return entry[language] ?? entry[AppLanguage.tr] ?? key;
  }

  // Keys are grouped by feature area. Add new UI text here first, then
  // reference it via `tr(ref, 'key')` at the call site.
  static const Map<String, Map<AppLanguage, String>> values = {
    // --- Common / shared ---
    'common_all': {AppLanguage.tr: 'Tümü', AppLanguage.en: 'All'},
    'common_reset': {AppLanguage.tr: 'Sıfırla', AppLanguage.en: 'Reset'},
    'common_filter': {AppLanguage.tr: 'Filtrele', AppLanguage.en: 'Filter'},
    'common_save': {AppLanguage.tr: 'Kaydet', AppLanguage.en: 'Save'},
    'common_cancel': {AppLanguage.tr: 'İptal', AppLanguage.en: 'Cancel'},
    'common_delete': {AppLanguage.tr: 'Sil', AppLanguage.en: 'Delete'},
    'common_edit': {AppLanguage.tr: 'Düzenle', AppLanguage.en: 'Edit'},
    'common_add': {AppLanguage.tr: 'Ekle', AppLanguage.en: 'Add'},
    'common_close': {AppLanguage.tr: 'Kapat', AppLanguage.en: 'Close'},
    'common_send': {AppLanguage.tr: 'Gönder', AppLanguage.en: 'Send'},
    'common_you': {AppLanguage.tr: 'Sen', AppLanguage.en: 'You'},
    'common_user': {AppLanguage.tr: 'Kullanıcı', AppLanguage.en: 'User'},
    'common_loading': {AppLanguage.tr: 'Yükleniyor...', AppLanguage.en: 'Loading...'},
    'common_error_generic': {
      AppLanguage.tr: 'Bir şeyler ters gitti. Lütfen tekrar deneyin.',
      AppLanguage.en: 'Something went wrong. Please try again.',
    },
    'common_date': {AppLanguage.tr: 'Tarih', AppLanguage.en: 'Date'},
    'common_category': {AppLanguage.tr: 'Kategori', AppLanguage.en: 'Category'},
    'common_expense': {AppLanguage.tr: 'Gider', AppLanguage.en: 'Expense'},
    'common_income': {AppLanguage.tr: 'Gelir', AppLanguage.en: 'Income'},

    // --- Category names (shared across dashboard, statistics, add-expense) ---
    'category_market': {AppLanguage.tr: 'Market', AppLanguage.en: 'Groceries'},
    'category_food': {AppLanguage.tr: 'Yemek', AppLanguage.en: 'Food'},
    'category_transport': {AppLanguage.tr: 'Ulaşım', AppLanguage.en: 'Transport'},
    'category_entertainment': {
      AppLanguage.tr: 'Eğlence',
      AppLanguage.en: 'Entertainment',
    },
    'category_salary': {AppLanguage.tr: 'Maaş', AppLanguage.en: 'Salary'},
    'category_dues': {AppLanguage.tr: 'Aidat', AppLanguage.en: 'Dues'},
    'category_bill': {AppLanguage.tr: 'Fatura', AppLanguage.en: 'Bill'},
    'category_other': {AppLanguage.tr: 'Diğer', AppLanguage.en: 'Other'},

    // --- Month abbreviations ---
    'month_jan': {AppLanguage.tr: 'Oca', AppLanguage.en: 'Jan'},
    'month_feb': {AppLanguage.tr: 'Şub', AppLanguage.en: 'Feb'},
    'month_mar': {AppLanguage.tr: 'Mar', AppLanguage.en: 'Mar'},
    'month_apr': {AppLanguage.tr: 'Nis', AppLanguage.en: 'Apr'},
    'month_may': {AppLanguage.tr: 'May', AppLanguage.en: 'May'},
    'month_jun': {AppLanguage.tr: 'Haz', AppLanguage.en: 'Jun'},
    'month_jul': {AppLanguage.tr: 'Tem', AppLanguage.en: 'Jul'},
    'month_aug': {AppLanguage.tr: 'Ağu', AppLanguage.en: 'Aug'},
    'month_sep': {AppLanguage.tr: 'Eyl', AppLanguage.en: 'Sep'},
    'month_oct': {AppLanguage.tr: 'Eki', AppLanguage.en: 'Oct'},
    'month_nov': {AppLanguage.tr: 'Kas', AppLanguage.en: 'Nov'},
    'month_dec': {AppLanguage.tr: 'Ara', AppLanguage.en: 'Dec'},

    // --- Dashboard ---
    'dashboard_title': {AppLanguage.tr: 'Dashboard', AppLanguage.en: 'Dashboard'},
    'dashboard_statistics': {
      AppLanguage.tr: 'İstatistikler',
      AppLanguage.en: 'Statistics',
    },
    'dashboard_notifications': {
      AppLanguage.tr: 'Bildirimler',
      AppLanguage.en: 'Notifications',
    },
    'dashboard_activity_feed': {
      AppLanguage.tr: 'Aktivite Akışı',
      AppLanguage.en: 'Activity Feed',
    },
    'dashboard_recent_transactions': {
      AppLanguage.tr: 'Son İşlemler',
      AppLanguage.en: 'Recent Transactions',
    },
    'dashboard_no_activity': {
      AppLanguage.tr: 'Henüz sosyal aktivite yok.',
      AppLanguage.en: 'No social activity yet.',
    },
    'dashboard_no_transactions': {
      AppLanguage.tr: 'Henüz işlem bulunmuyor.',
      AppLanguage.en: 'No transactions yet.',
    },
    'dashboard_net_balance': {
      AppLanguage.tr: 'Net Bakiye',
      AppLanguage.en: 'Net Balance',
    },
    'dashboard_amount_hint': {AppLanguage.tr: 'Tutar', AppLanguage.en: 'Amount'},
    'dashboard_custom_category_hint': {
      AppLanguage.tr: 'Özel kategori girin...',
      AppLanguage.en: 'Enter custom category...',
    },
    'dashboard_pick_date': {AppLanguage.tr: 'Tarih seç', AppLanguage.en: 'Pick date'},
    'dashboard_transaction_added': {
      AppLanguage.tr: 'İşlem eklendi!',
      AppLanguage.en: 'Transaction added!',
    },

    // --- Statistics ---
    'statistics_title': {
      AppLanguage.tr: 'İstatistikler',
      AppLanguage.en: 'Statistics',
    },
    'statistics_category_distribution': {
      AppLanguage.tr: 'Kategori Dağılımı (Bu Ay)',
      AppLanguage.en: 'Category Breakdown (This Month)',
    },
    'statistics_no_expenses_this_month': {
      AppLanguage.tr: 'Bu ay hiç harcamanız yok.',
      AppLanguage.en: 'You have no expenses this month.',
    },
    'statistics_heatmap_title': {
      AppLanguage.tr: 'Aktivasyon Isı Haritası',
      AppLanguage.en: 'Activity Heatmap',
    },
    'statistics_heatmap_activity_count': {
      AppLanguage.tr: 'aktivite',
      AppLanguage.en: 'activities',
    },

    // --- Auth: login ---
    'login_title': {AppLanguage.tr: 'Spendly Giriş', AppLanguage.en: 'Spendly Login'},
    'login_username_required': {
      AppLanguage.tr: 'Kullanıcı adınızı girin.',
      AppLanguage.en: 'Enter your username.',
    },
    'login_password_required': {
      AppLanguage.tr: 'Şifrenizi girin.',
      AppLanguage.en: 'Enter your password.',
    },
    'login_username_label': {
      AppLanguage.tr: 'Kullanıcı Adı (@username)',
      AppLanguage.en: 'Username (@username)',
    },
    'login_password_label': {AppLanguage.tr: 'Şifre', AppLanguage.en: 'Password'},
    'login_forgot_password': {
      AppLanguage.tr: 'Şifremi Unuttum?',
      AppLanguage.en: 'Forgot password?',
    },
    'login_submit': {AppLanguage.tr: 'Giriş Yap', AppLanguage.en: 'Log in'},
    'login_no_account': {
      AppLanguage.tr: 'Hesabın yok mu? Kayıt Ol',
      AppLanguage.en: "Don't have an account? Sign up",
    },

    // --- Auth: register ---
    'register_title': {
      AppLanguage.tr: 'Spendly Kayıt Ol',
      AppLanguage.en: 'Spendly Sign Up',
    },
    'register_username_too_short': {
      AppLanguage.tr: 'Kullanıcı adı en az 3 karakter olmalı.',
      AppLanguage.en: 'Username must be at least 3 characters.',
    },
    'register_email_invalid': {
      AppLanguage.tr: 'Geçerli bir e-posta adresi girin.',
      AppLanguage.en: 'Enter a valid email address.',
    },
    'register_password_too_short': {
      AppLanguage.tr: 'Şifre en az 6 karakter olmalı.',
      AppLanguage.en: 'Password must be at least 6 characters.',
    },
    'register_success': {
      AppLanguage.tr: 'Kayıt başarılı! Lütfen giriş yapın.',
      AppLanguage.en: 'Registration successful! Please log in.',
    },
    'register_email_label': {AppLanguage.tr: 'Email', AppLanguage.en: 'Email'},
    'register_submit': {AppLanguage.tr: 'Kayıt Ol', AppLanguage.en: 'Sign up'},
    'register_have_account': {
      AppLanguage.tr: 'Zaten hesabın var mı? Giriş Yap',
      AppLanguage.en: 'Already have an account? Log in',
    },

    // --- Auth: forgot / update password ---
    'forgot_password_title': {
      AppLanguage.tr: 'Şifremi Unuttum',
      AppLanguage.en: 'Forgot Password',
    },
    'forgot_password_email_invalid': {
      AppLanguage.tr: 'Geçerli bir e-posta adresi girin.',
      AppLanguage.en: 'Enter a valid email address.',
    },
    'forgot_password_sent_message': {
      AppLanguage.tr:
          'Şifre sıfırlama linki e-postanıza gönderildi. Gelen kutunuzu kontrol edin.',
      AppLanguage.en:
          'A password reset link has been sent to your email. Check your inbox.',
    },
    'forgot_password_back_to_login': {
      AppLanguage.tr: 'Girişe Dön',
      AppLanguage.en: 'Back to login',
    },
    'forgot_password_prompt': {
      AppLanguage.tr:
          'Hesabınıza kayıtlı e-posta adresini girin, size bir şifre sıfırlama linki gönderelim.',
      AppLanguage.en:
          "Enter your account's email address and we'll send you a password reset link.",
    },
    'forgot_password_email_label': {
      AppLanguage.tr: 'E-posta',
      AppLanguage.en: 'Email',
    },
    'forgot_password_send_link': {
      AppLanguage.tr: 'Sıfırlama Linki Gönder',
      AppLanguage.en: 'Send reset link',
    },
    'update_password_title': {
      AppLanguage.tr: 'Yeni Şifre Belirle',
      AppLanguage.en: 'Set New Password',
    },
    'update_password_too_short': {
      AppLanguage.tr: 'Şifre en az 6 karakter olmalıdır.',
      AppLanguage.en: 'Password must be at least 6 characters.',
    },
    'update_password_success': {
      AppLanguage.tr: 'Şifreniz başarıyla güncellendi!',
      AppLanguage.en: 'Your password has been updated successfully!',
    },
    'update_password_prompt': {
      AppLanguage.tr: 'Lütfen hesabınız için yeni bir şifre belirleyin.',
      AppLanguage.en: 'Please set a new password for your account.',
    },
    'update_password_new_label': {
      AppLanguage.tr: 'Yeni Şifre',
      AppLanguage.en: 'New password',
    },
    'update_password_submit': {
      AppLanguage.tr: 'Şifreyi Güncelle',
      AppLanguage.en: 'Update password',
    },

    // --- Groups: list ---
    'groups_title': {AppLanguage.tr: 'Gruplar', AppLanguage.en: 'Groups'},
    'groups_empty_title': {
      AppLanguage.tr: 'Henüz bir gruba dahil değilsiniz.',
      AppLanguage.en: "You're not part of any group yet.",
    },
    'groups_empty_subtitle': {
      AppLanguage.tr:
          'Sağ alttaki + butonuna dokunarak ilk grubunu oluşturabilirsin.',
      AppLanguage.en:
          'Tap the + button in the bottom right to create your first group.',
    },
    'groups_tap_for_details': {
      AppLanguage.tr: 'Grup Detayları için tıklayın',
      AppLanguage.en: 'Tap for group details',
    },
    'groups_create_new_group': {
      AppLanguage.tr: 'Yeni Grup Oluştur',
      AppLanguage.en: 'Create New Group',
    },
    'groups_name_label': {AppLanguage.tr: 'Grup Adı', AppLanguage.en: 'Group Name'},
    'groups_create_button': {AppLanguage.tr: 'Oluştur', AppLanguage.en: 'Create'},

    // --- Groups: detail screen ---
    'groups_participants_suffix': {
      AppLanguage.tr: 'katılımcı',
      AppLanguage.en: 'participants',
    },
    'groups_participants_load_error': {
      AppLanguage.tr: 'Katılımcılar yüklenemedi',
      AppLanguage.en: 'Participants could not be loaded',
    },
    'groups_chat_tooltip': {
      AppLanguage.tr: 'Grup sohbeti',
      AppLanguage.en: 'Group chat',
    },
    'groups_invite_friend_tooltip': {
      AppLanguage.tr: 'Arkadaş davet et',
      AppLanguage.en: 'Invite friend',
    },
    'groups_paid_verb': {AppLanguage.tr: 'ödedi', AppLanguage.en: 'paid'},
    'groups_tab_pending': {AppLanguage.tr: 'Bekleyen', AppLanguage.en: 'Pending'},
    'groups_tab_active': {AppLanguage.tr: 'Aktif', AppLanguage.en: 'Active'},
    'groups_tab_archived': {AppLanguage.tr: 'Arşiv', AppLanguage.en: 'Archive'},
    'groups_no_transactions': {
      AppLanguage.tr: 'Henüz işlem yok. İlk harcamayı ekleyin.',
      AppLanguage.en: 'No transactions yet. Add the first expense.',
    },
    'groups_empty_pending': {
      AppLanguage.tr: 'Onay bekleyen harcama yok.',
      AppLanguage.en: 'No expenses awaiting approval.',
    },
    'groups_empty_active': {
      AppLanguage.tr: 'Aktif harcama yok.',
      AppLanguage.en: 'No active expenses.',
    },
    'groups_empty_archived': {
      AppLanguage.tr: 'Arşivlenmiş harcama yok.',
      AppLanguage.en: 'No archived expenses.',
    },
    'groups_add_expense': {
      AppLanguage.tr: 'Harcama Ekle',
      AppLanguage.en: 'Add Expense',
    },
    'groups_archive_all_button': {
      AppLanguage.tr: 'Tümünü Arşivle',
      AppLanguage.en: 'Archive All',
    },
    'groups_action_failed': {
      AppLanguage.tr: 'İşlem gerçekleştirilemedi. Lütfen tekrar deneyin.',
      AppLanguage.en: 'The action could not be completed. Please try again.',
    },
    'groups_archive_failed': {
      AppLanguage.tr: 'Harcama arşivlenemedi. Lütfen tekrar deneyin.',
      AppLanguage.en: 'The expense could not be archived. Please try again.',
    },
    'groups_status_payer': {AppLanguage.tr: 'Ödeyen', AppLanguage.en: 'Payer'},
    'groups_status_pending': {
      AppLanguage.tr: 'Onay bekliyor',
      AppLanguage.en: 'Awaiting approval',
    },
    'groups_status_approved_self': {
      AppLanguage.tr: 'Onaylandı',
      AppLanguage.en: 'Approved',
    },
    'groups_status_active_debt': {
      AppLanguage.tr: 'Aktif borç',
      AppLanguage.en: 'Active debt',
    },
    'groups_status_payment_pending_payer': {
      AppLanguage.tr: 'Ödeme onayı bekleniyor',
      AppLanguage.en: 'Awaiting payment confirmation',
    },
    'groups_status_payment_reported': {
      AppLanguage.tr: 'Ödeme bildirildi',
      AppLanguage.en: 'Payment reported',
    },
    'groups_status_settled': {AppLanguage.tr: 'Ödendi', AppLanguage.en: 'Paid'},
    'groups_status_rejected': {
      AppLanguage.tr: 'Reddedildi',
      AppLanguage.en: 'Rejected',
    },
    'groups_action_approve': {AppLanguage.tr: 'Onayla', AppLanguage.en: 'Approve'},
    'groups_action_mark_paid': {
      AppLanguage.tr: 'Ödendi Olarak İşaretle',
      AppLanguage.en: 'Mark as Paid',
    },
    'groups_action_confirm_payment': {
      AppLanguage.tr: 'Ödemeyi Onayla',
      AppLanguage.en: 'Confirm Payment',
    },
    'groups_balance_title': {
      AppLanguage.tr: 'Grup Bakiyesi',
      AppLanguage.en: 'Group Balance',
    },
    'groups_no_active_debt': {
      AppLanguage.tr: 'Aktif borç bulunmuyor.',
      AppLanguage.en: 'No active debt.',
    },
    'groups_creditor_label': {
      AppLanguage.tr: 'Alacaklı',
      AppLanguage.en: 'Owed',
    },
    'groups_debtor_label': {AppLanguage.tr: 'Borçlu', AppLanguage.en: 'Owes'},
    'groups_filter_payer_label': {
      AppLanguage.tr: 'Ödeyen kişi',
      AppLanguage.en: 'Paid by',
    },

    // --- Groups: info screen ---
    'group_info_title': {
      AppLanguage.tr: 'Grup Bilgisi',
      AppLanguage.en: 'Group Info',
    },
    'group_info_leave_button': {
      AppLanguage.tr: 'Gruptan Ayrıl',
      AppLanguage.en: 'Leave Group',
    },
    'group_info_delete_button': {
      AppLanguage.tr: 'Grubu Sil',
      AppLanguage.en: 'Delete Group',
    },
    'group_info_leave_confirm': {
      AppLanguage.tr:
          '"%s" grubundan ayrılmak istediğinize emin misiniz? Geçmiş harcamalarınız grupta kalır.',
      AppLanguage.en:
          'Are you sure you want to leave "%s"? Your past expenses will remain in the group.',
    },
    'group_info_leave_confirm_button': {
      AppLanguage.tr: 'Ayrıl',
      AppLanguage.en: 'Leave',
    },
    'group_info_delete_confirm': {
      AppLanguage.tr:
          '"%s" grubunu ve tüm harcama/üyelik verilerini kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
      AppLanguage.en:
          'Are you sure you want to permanently delete "%s" and all its expense/membership data? This action cannot be undone.',
    },

    // --- Groups: chat ---
    'groups_chat_suffix': {AppLanguage.tr: 'Sohbeti', AppLanguage.en: 'Chat'},
    'groups_chat_empty': {
      AppLanguage.tr: 'Henüz mesaj yok. İlk mesajı sen yaz!',
      AppLanguage.en: 'No messages yet. Write the first one!',
    },
    'groups_chat_input_hint': {
      AppLanguage.tr: 'Mesaj yaz...',
      AppLanguage.en: 'Write a message...',
    },

    // --- Groups: add expense sheet ---
    'groups_expense_desc_label': {
      AppLanguage.tr: 'Ne için?',
      AppLanguage.en: 'What for?',
    },
    'groups_total_amount_label': {
      AppLanguage.tr: 'Toplam Tutar',
      AppLanguage.en: 'Total Amount',
    },
    'groups_split_equal': {AppLanguage.tr: 'Eşit (=)', AppLanguage.en: 'Equal (=)'},
    'groups_split_percentage': {
      AppLanguage.tr: 'Yüzde (%)',
      AppLanguage.en: 'Percentage (%)',
    },
    'groups_split_exact': {AppLanguage.tr: 'Tutar', AppLanguage.en: 'Amount'},
    'groups_split_for_whom': {
      AppLanguage.tr: 'Kimin için harcandı?',
      AppLanguage.en: 'Who is this expense for?',
    },
    'groups_auto_badge': {AppLanguage.tr: 'otomatik', AppLanguage.en: 'auto'},
    'groups_expense_validation_generic': {
      AppLanguage.tr: 'Lütfen geçerli bilgiler girin ve en az 1 kişi seçin.',
      AppLanguage.en: 'Please enter valid information and select at least 1 person.',
    },
    'groups_percentage_validation': {
      AppLanguage.tr:
          'Yüzde alanlarında en fazla 1 kişi boş kalabilir ve toplam 100 olmalıdır.',
      AppLanguage.en:
          'At most 1 person can be left blank in the percentage fields, and the total must equal 100.',
    },
    'groups_percentage_total_validation': {
      AppLanguage.tr: 'Yüzdelerin toplamı 100 olmalıdır.',
      AppLanguage.en: 'The percentages must add up to 100.',
    },
    'groups_exact_validation': {
      AppLanguage.tr:
          'Tutar alanlarında en fazla 1 kişi boş kalabilir ve toplam harcamaya eşit olmalıdır.',
      AppLanguage.en:
          'At most 1 person can be left blank in the amount fields, and the total must equal the expense amount.',
    },

    // --- Groups: invite friend modal ---
    'groups_invited_snackbar': {
      AppLanguage.tr: 'Davet edildi!',
      AppLanguage.en: 'Invited!',
    },
    'groups_invite_modal_title': {
      AppLanguage.tr: 'Gruba Arkadaş Davet Et',
      AppLanguage.en: 'Invite Friend to Group',
    },
    'groups_invite_search_hint': {
      AppLanguage.tr: 'Arkadaşlarında ara',
      AppLanguage.en: 'Search your friends',
    },
    'groups_no_friends_to_invite': {
      AppLanguage.tr: 'Davet edebilecek arkadaşın yok.',
      AppLanguage.en: 'You have no friends to invite.',
    },
    'groups_no_friends_hint': {
      AppLanguage.tr: 'Önce Sosyal sekmesinden arkadaş ekle.',
      AppLanguage.en: 'Add friends first from the Social tab.',
    },
    'groups_no_search_match': {
      AppLanguage.tr: 'Aramanla eşleşen arkadaş bulunamadı.',
      AppLanguage.en: 'No friends match your search.',
    },

    // --- Debts ---
    'debts_back_tooltip': {AppLanguage.tr: 'Geri', AppLanguage.en: 'Back'},
    'debts_title': {AppLanguage.tr: 'Borçlar', AppLanguage.en: 'Debts'},
    'debts_tab_mine': {AppLanguage.tr: 'Borçlarım', AppLanguage.en: 'My Debts'},
    'debts_tab_owed_to_me': {
      AppLanguage.tr: 'Alacaklarım',
      AppLanguage.en: 'Owed to Me',
    },
    'debts_tab_approvals': {
      AppLanguage.tr: 'Onaylar',
      AppLanguage.en: 'Approvals',
    },
    'debts_tab_summary': {AppLanguage.tr: 'Özet', AppLanguage.en: 'Summary'},
    'debts_user_info_unavailable': {
      AppLanguage.tr: 'Kullanıcı bilgisi alınamadı.',
      AppLanguage.en: 'User information could not be retrieved.',
    },
    'debts_not_in_any_group': {
      AppLanguage.tr: 'Henüz herhangi bir gruba dahil değilsiniz.',
      AppLanguage.en: "You're not part of any group yet.",
    },
    'debts_owed_by_prefix': {
      AppLanguage.tr: 'Borçlu olunan kişi',
      AppLanguage.en: 'Owed to',
    },
    'debts_owed_to_me_prefix': {
      AppLanguage.tr: 'Bize borçlu',
      AppLanguage.en: 'Owes us',
    },
    'debts_no_active_debt': {
      AppLanguage.tr: 'Aktif borcunuz bulunmuyor.',
      AppLanguage.en: 'You have no active debt.',
    },
    'debts_no_active_credit': {
      AppLanguage.tr: 'Size olan aktif borç bulunmuyor.',
      AppLanguage.en: 'No one owes you actively.',
    },
    'debts_total_debt_label': {
      AppLanguage.tr: 'Toplam Borç',
      AppLanguage.en: 'Total Debt',
    },
    'debts_total_credit_label': {
      AppLanguage.tr: 'Toplam Alacak',
      AppLanguage.en: 'Total Credit',
    },
    'debts_awaiting_my_approval': {
      AppLanguage.tr: 'Onayınızı Bekleyenler',
      AppLanguage.en: 'Awaiting Your Approval',
    },
    'debts_no_awaiting_my_approval': {
      AppLanguage.tr: 'Onayınızı bekleyen borç bulunmuyor.',
      AppLanguage.en: 'No debts awaiting your approval.',
    },
    'debts_awaiting_other_approval': {
      AppLanguage.tr: 'Karşı Tarafın Onayını Bekleyenler',
      AppLanguage.en: "Awaiting the Other Party's Approval",
    },
    'debts_no_awaiting_other_approval': {
      AppLanguage.tr: 'Karşı tarafın onayını bekleyen borç bulunmuyor.',
      AppLanguage.en: "No debts awaiting the other party's approval.",
    },
    'debts_reject_tooltip': {AppLanguage.tr: 'Reddet', AppLanguage.en: 'Reject'},
    'debts_no_settlement': {
      AppLanguage.tr: 'Netleştirilecek borç bulunmuyor.',
      AppLanguage.en: 'No debt to settle.',
    },
    'debts_settled_debt_subtitle': {
      AppLanguage.tr: 'Netleştirilmiş borç',
      AppLanguage.en: 'Settled debt',
    },
    'debts_total_prefix': {AppLanguage.tr: 'Toplam', AppLanguage.en: 'Total'},
    'debts_filter_group_label': {
      AppLanguage.tr: 'Grup',
      AppLanguage.en: 'Group',
    },
    'debts_clear_filters_tooltip': {
      AppLanguage.tr: 'Filtreleri temizle',
      AppLanguage.en: 'Clear filters',
    },

    // --- Notifications ---
    'notifications_login_required': {
      AppLanguage.tr: 'Bildirimleri görmek için giriş yapın.',
      AppLanguage.en: 'Log in to view your notifications.',
    },
    'notifications_empty_title': {
      AppLanguage.tr: 'Henüz bildiriminiz yok.',
      AppLanguage.en: 'You have no notifications yet.',
    },
    'notifications_empty_subtitle': {
      AppLanguage.tr:
          'Gruplarınızdaki harcama ve onay güncellemeleri burada görünecek.',
      AppLanguage.en:
          'Expense and approval updates from your groups will appear here.',
    },

    // --- Notifications: dynamically built messages ---
    'notif_new_expense_title': {
      AppLanguage.tr: 'Yeni harcama',
      AppLanguage.en: 'New expense',
    },
    'notif_new_expense_message': {
      AppLanguage.tr:
          '{sender} sizi {group} grubundaki "{desc}" harcamasına ekledi. '
          'Tutar: {amount} TL. Onayınızı bekliyor.',
      AppLanguage.en:
          '{sender} added you to the expense "{desc}" in the {group} group. '
          'Amount: {amount} TL. Awaiting your approval.',
    },
    'notif_payment_confirmation_title': {
      AppLanguage.tr: 'Ödeme bildirildi',
      AppLanguage.en: 'Payment reported',
    },
    'notif_payment_confirmation_message': {
      AppLanguage.tr:
          '{sender}, {group} grubundaki "{desc}" için ödeme bildirimi gönderdi.',
      AppLanguage.en:
          '{sender} reported a payment for "{desc}" in the {group} group.',
    },
    'notif_debt_approved_title': {
      AppLanguage.tr: 'Borç onaylandı',
      AppLanguage.en: 'Debt approved',
    },
    'notif_debt_approved_message': {
      AppLanguage.tr:
          '{sender}, {group} grubundaki "{desc}" borcunu onayladı.',
      AppLanguage.en:
          '{sender} approved the debt for "{desc}" in the {group} group.',
    },
    'notif_debt_rejected_title': {
      AppLanguage.tr: 'Borç reddedildi',
      AppLanguage.en: 'Debt rejected',
    },
    'notif_debt_rejected_message': {
      AppLanguage.tr:
          '{sender}, {group} grubundaki "{desc}" borcunu reddetti.',
      AppLanguage.en:
          '{sender} rejected the debt for "{desc}" in the {group} group.',
    },
    'notif_debt_settled_title': {
      AppLanguage.tr: 'Ödeme onaylandı',
      AppLanguage.en: 'Payment confirmed',
    },
    'notif_debt_settled_message': {
      AppLanguage.tr:
          '{sender}, {group} grubundaki "{desc}" için ödemenizi onayladı. '
          'Borç kapandı.',
      AppLanguage.en:
          '{sender} confirmed your payment for "{desc}" in the {group} group. '
          'The debt is settled.',
    },
    'notif_default_group': {
      AppLanguage.tr: 'Bir grup',
      AppLanguage.en: 'A group',
    },
    'notif_default_user': {
      AppLanguage.tr: 'Bir kullanıcı',
      AppLanguage.en: 'A user',
    },
    'notif_default_expense_desc': {
      AppLanguage.tr: 'harcama',
      AppLanguage.en: 'expense',
    },

    // --- Profile ---
    'profile_title': {AppLanguage.tr: 'Profil', AppLanguage.en: 'Profile'},
    'profile_unknown_username': {
      AppLanguage.tr: '@bilinmiyor',
      AppLanguage.en: '@unknown',
    },
    'profile_edit_tile': {
      AppLanguage.tr: 'Profili Düzenle',
      AppLanguage.en: 'Edit Profile',
    },
    'profile_currency_tile': {
      AppLanguage.tr: 'Para Birimi',
      AppLanguage.en: 'Currency',
    },
    'profile_change_password_tile': {
      AppLanguage.tr: 'Şifre Değiştir',
      AppLanguage.en: 'Change Password',
    },
    'profile_download_report_tile': {
      AppLanguage.tr: 'Aylık Raporu İndir (PDF)',
      AppLanguage.en: 'Download Monthly Report (PDF)',
    },
    'profile_pdf_error': {
      AppLanguage.tr: 'PDF Oluşturulamadı: %s',
      AppLanguage.en: 'Could not generate PDF: %s',
    },
    'profile_logout': {AppLanguage.tr: 'Çıkış Yap', AppLanguage.en: 'Log out'},
    'profile_danger_zone': {
      AppLanguage.tr: 'Tehlikeli bölge',
      AppLanguage.en: 'Danger zone',
    },
    'profile_delete_account_data': {
      AppLanguage.tr: 'Hesabı ve Verileri Sil',
      AppLanguage.en: 'Delete Account and Data',
    },
    'profile_delete_account_title': {
      AppLanguage.tr: 'Hesabı Sil',
      AppLanguage.en: 'Delete Account',
    },
    'profile_delete_account_confirm': {
      AppLanguage.tr:
          'Hesabınızı ve tüm verilerini kalıcı olarak silmek istediğinize '
          'emin misiniz? Bu işlem geri alınamaz.',
      AppLanguage.en:
          'Are you sure you want to permanently delete your account and all '
          'its data? This action cannot be undone.',
    },
    'profile_avatar_url_label': {
      AppLanguage.tr: 'Avatar URL (Opsiyonel)',
      AppLanguage.en: 'Avatar URL (Optional)',
    },
    'profile_update_success': {
      AppLanguage.tr: 'Profil başarıyla güncellendi.',
      AppLanguage.en: 'Profile updated successfully.',
    },

    // --- Profile: PDF export ---
    'pdf_title': {
      AppLanguage.tr: 'Aylık Rapor - %s',
      AppLanguage.en: 'Monthly Report - %s',
    },
    'pdf_total_income': {
      AppLanguage.tr: 'Toplam Gelir',
      AppLanguage.en: 'Total Income',
    },
    'pdf_total_expense': {
      AppLanguage.tr: 'Toplam Gider',
      AppLanguage.en: 'Total Expense',
    },
    'pdf_net_balance': {
      AppLanguage.tr: 'Net Bakiye',
      AppLanguage.en: 'Net Balance',
    },
    'pdf_transaction_details': {
      AppLanguage.tr: 'İşlem Detayları',
      AppLanguage.en: 'Transaction Details',
    },
    'pdf_no_transactions': {
      AppLanguage.tr: 'Bu ay için işlem bulunmuyor.',
      AppLanguage.en: 'No transactions for this month.',
    },
    'pdf_header_type': {AppLanguage.tr: 'Tür', AppLanguage.en: 'Type'},

    // --- Social ---
    'social_title': {AppLanguage.tr: 'Sosyal', AppLanguage.en: 'Social'},
    'social_request_sent_snackbar': {
      AppLanguage.tr: 'İstek gönderildi!',
      AppLanguage.en: 'Request sent!',
    },
    'social_user_not_found': {
      AppLanguage.tr: 'Kullanıcı bulunamadı.',
      AppLanguage.en: 'User not found.',
    },
    'social_search_results_header': {
      AppLanguage.tr: 'Arama Sonuçları',
      AppLanguage.en: 'Search Results',
    },
    'social_add_friend_tooltip': {
      AppLanguage.tr: 'Arkadaş ekle',
      AppLanguage.en: 'Add friend',
    },
    'social_search_hint': {
      AppLanguage.tr: '@username ile kullanıcı ara',
      AppLanguage.en: 'Search users by @username',
    },
    'social_search_tooltip': {
      AppLanguage.tr: 'Kullanıcı ara',
      AppLanguage.en: 'Search users',
    },
    'social_no_friends_title': {
      AppLanguage.tr: 'Henüz arkadaşın yok.',
      AppLanguage.en: 'You have no friends yet.',
    },
    'social_no_friends_subtitle': {
      AppLanguage.tr:
          'Yukarıdaki arama kutusuyla kullanıcı adı arayıp arkadaşlık isteği '
          'gönderebilirsin.',
      AppLanguage.en:
          'Use the search box above to look up a username and send a friend '
          'request.',
    },
    'social_request_sent_prefix': {
      AppLanguage.tr: 'İstek gönderildi: %s',
      AppLanguage.en: 'Request sent: %s',
    },
    'social_pending_status': {
      AppLanguage.tr: 'Bekleniyor...',
      AppLanguage.en: 'Pending...',
    },
    'social_incoming_request_prefix': {
      AppLanguage.tr: 'Sana istek: %s',
      AppLanguage.en: 'Request to you: %s',
    },
    'social_friend_prefix': {
      AppLanguage.tr: 'Arkadaş: %s',
      AppLanguage.en: 'Friend: %s',
    },
    'social_default_chat_title': {
      AppLanguage.tr: 'Arkadaş',
      AppLanguage.en: 'Friend',
    },

    // --- Social: other user profile ---
    'other_profile_title': {
      AppLanguage.tr: 'Kullanıcı Profili',
      AppLanguage.en: 'User Profile',
    },
    'other_profile_unknown': {
      AppLanguage.tr: 'Bilinmiyor',
      AppLanguage.en: 'Unknown',
    },
    'other_profile_no_shared_groups': {
      AppLanguage.tr: 'Ortak grubunuz yok',
      AppLanguage.en: 'No shared groups',
    },
    'other_profile_shared_groups_count': {
      AppLanguage.tr: 'Ortak %s grubunuz var',
      AppLanguage.en: 'You share %s groups',
    },
    'other_profile_send_message': {
      AppLanguage.tr: 'Mesaj Gönder',
      AppLanguage.en: 'Send Message',
    },

    // --- Subscriptions: paywall ---
    'paywall_title': {
      AppLanguage.tr: "Spendly Pro'ya Geç",
      AppLanguage.en: 'Upgrade to Spendly Pro',
    },
    'paywall_subtitle': {
      AppLanguage.tr:
          'Limitsiz grup oluşturun, tüm istatistiklere erişin ve finansal '
          'özgürlüğün tadını çıkarın!',
      AppLanguage.en:
          'Create unlimited groups, access all statistics, and enjoy '
          'financial freedom!',
    },
    'paywall_no_packages': {
      AppLanguage.tr: 'Şu an paket bulunmuyor.',
      AppLanguage.en: 'No packages available right now.',
    },
    'paywall_restore_purchases': {
      AppLanguage.tr: 'Satın Alımları Geri Yükle',
      AppLanguage.en: 'Restore Purchases',
    },
    'paywall_restore_success': {
      AppLanguage.tr: 'Satın alımlar geri yüklendi!',
      AppLanguage.en: 'Purchases restored!',
    },
    'paywall_processing_purchase': {
      AppLanguage.tr: 'Satın alma işleniyor...',
      AppLanguage.en: 'Processing purchase...',
    },
    'paywall_welcome_pro': {
      AppLanguage.tr: "Spendly Pro'ya hoş geldiniz!",
      AppLanguage.en: 'Welcome to Spendly Pro!',
    },
    'paywall_purchase_failed': {
      AppLanguage.tr: 'İşlem iptal edildi veya başarısız oldu.',
      AppLanguage.en: 'The transaction was cancelled or failed.',
    },
    'paywall_benefit_unlimited_groups': {
      AppLanguage.tr: 'Limitsiz grup oluşturun',
      AppLanguage.en: 'Create unlimited groups',
    },
    'paywall_benefit_statistics': {
      AppLanguage.tr: 'Tüm istatistiklere ve raporlara erişin',
      AppLanguage.en: 'Access all statistics and reports',
    },
    'paywall_benefit_freedom': {
      AppLanguage.tr: 'Finansal özgürlüğün tadını çıkarın',
      AppLanguage.en: 'Enjoy your financial freedom',
    },
    'paywall_no_packages_hint': {
      AppLanguage.tr: 'Paketler yakında burada görünecek.',
      AppLanguage.en: 'Packages will appear here soon.',
    },
    'paywall_footer_note': {
      AppLanguage.tr: 'Aboneliğiniz istediğiniz zaman iptal edilebilir.',
      AppLanguage.en: 'Your subscription can be cancelled anytime.',
    },

    // --- Friendly error messages ---
    'error_generic_short': {
      AppLanguage.tr: 'Bir şeyler ters gitti. Lütfen tekrar deneyin.',
      AppLanguage.en: 'Something went wrong. Please try again.',
    },
    'error_auth_generic': {
      AppLanguage.tr: 'Bir sorun oluştu. Lütfen tekrar deneyin.',
      AppLanguage.en: 'A problem occurred. Please try again.',
    },
    'error_invalid_credentials': {
      AppLanguage.tr: 'Kullanıcı adı veya şifre hatalı.',
      AppLanguage.en: 'Incorrect username or password.',
    },
    'error_email_not_confirmed': {
      AppLanguage.tr: 'E-posta adresiniz henüz doğrulanmamış.',
      AppLanguage.en: 'Your email address has not been verified yet.',
    },
    'error_email_already_registered': {
      AppLanguage.tr: 'Bu e-posta adresiyle zaten bir hesap var.',
      AppLanguage.en: 'An account with this email already exists.',
    },
    'error_password_too_short': {
      AppLanguage.tr: 'Şifre çok kısa. Lütfen daha uzun bir şifre seçin.',
      AppLanguage.en: 'Password is too short. Please choose a longer one.',
    },
    'error_rate_limited': {
      AppLanguage.tr: 'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin.',
      AppLanguage.en: 'Too many attempts. Please try again in a bit.',
    },
    'error_duplicate_record': {
      AppLanguage.tr: 'Bu kayıt zaten mevcut.',
      AppLanguage.en: 'This record already exists.',
    },
    'error_forbidden': {
      AppLanguage.tr: 'Bu işlemi yapma yetkiniz yok.',
      AppLanguage.en: 'You do not have permission to do this.',
    },
    'error_not_found': {
      AppLanguage.tr: 'Kayıt bulunamadı.',
      AppLanguage.en: 'Record not found.',
    },
    'error_server_generic': {
      AppLanguage.tr: 'Sunucuyla iletişimde bir sorun oluştu. Lütfen tekrar deneyin.',
      AppLanguage.en: 'There was a problem communicating with the server. Please try again.',
    },

    // --- Main scaffold (bottom nav) ---
    'nav_dashboard': {AppLanguage.tr: 'Dashboard', AppLanguage.en: 'Dashboard'},
    'nav_debts': {AppLanguage.tr: 'Borçlar', AppLanguage.en: 'Debts'},
    'nav_groups': {AppLanguage.tr: 'Gruplar', AppLanguage.en: 'Groups'},
    'nav_social': {AppLanguage.tr: 'Sosyal', AppLanguage.en: 'Social'},
    'nav_profile': {AppLanguage.tr: 'Profil', AppLanguage.en: 'Profile'},

    // --- Router fallback titles (used when navigation `extra` is absent) ---
    'route_fallback_group_detail': {
      AppLanguage.tr: 'Grup Detayı',
      AppLanguage.en: 'Group Detail',
    },
    'route_fallback_group_info': {
      AppLanguage.tr: 'Grup Bilgisi',
      AppLanguage.en: 'Group Info',
    },
    'route_fallback_group': {AppLanguage.tr: 'Grup', AppLanguage.en: 'Group'},
    'route_fallback_chat': {AppLanguage.tr: 'Sohbet', AppLanguage.en: 'Chat'},

    // --- Activity feed descriptions ---
    'activity_someone': {AppLanguage.tr: 'Biri', AppLanguage.en: 'Someone'},
    'activity_a_group': {AppLanguage.tr: 'Bir grup', AppLanguage.en: 'A group'},
    'activity_became_friends': {
      AppLanguage.tr: '{name} ile arkadaş oldun.',
      AppLanguage.en: 'You became friends with {name}.',
    },
    'activity_added_expense': {
      AppLanguage.tr: '{group} grubunda {amount}₺ harcama ekledin.',
      AppLanguage.en: 'You added a {amount}₺ expense in {group}.',
    },
  };
}
