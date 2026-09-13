// GENERATED-STYLE LOCALE CATALOG — edit by hand, keep keys in sync.
//
// Key order mirrors lib/core/l10n/strings_en.dart, the source locale.
// Every key present in `enStrings` must exist here; `localization_catalog_test`
// fails the build otherwise. Placeholders such as {name} must be preserved
// verbatim — only the surrounding words are translated.

// Launch locale — machine-assisted translation, pending native review.
const Map<String, String> deStrings = {
  // --- Common / shared ---
  'language_selector_label': 'App-Sprache',
  'common_all': 'Alle',
  'common_reset': 'Zurücksetzen',
  'common_filter': 'Filtern',
  'common_save': 'Speichern',
  'common_cancel': 'Abbrechen',
  'common_delete': 'Löschen',
  'common_edit': 'Bearbeiten',
  'common_add': 'Hinzufügen',
  'common_close': 'Schließen',
  'common_send': 'Senden',
  'common_you': 'Du',
  'common_user': 'Nutzer',
  'common_loading': 'Wird geladen...',
  'common_retry': 'Erneut versuchen',
  'common_error_generic': 'Etwas ist schiefgelaufen. Bitte versuche es erneut.',
  'common_date': 'Datum',
  'common_category': 'Kategorie',
  'common_expense': 'Ausgabe',
  'common_income': 'Einnahme',
  'common_currency': 'Währung',
  'exchange_rate_unavailable':
      'Der aktuelle Wechselkurs konnte nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.',
  // --- Category names (shared across dashboard, statistics, add-expense) ---
  'category_market': 'Lebensmittel',
  'category_food': 'Essen',
  'category_transport': 'Transport',
  'category_entertainment': 'Freizeit',
  'category_salary': 'Gehalt',
  'category_dues': 'Beiträge',
  'category_bill': 'Rechnung',
  'category_other': 'Sonstiges',
  // --- Month abbreviations ---
  'month_jan': 'Jan',
  'month_feb': 'Feb',
  'month_mar': 'Mär',
  'month_apr': 'Apr',
  'month_may': 'Mai',
  'month_jun': 'Jun',
  'month_jul': 'Jul',
  'month_aug': 'Aug',
  'month_sep': 'Sep',
  'month_oct': 'Okt',
  'month_nov': 'Nov',
  'month_dec': 'Dez',
  // --- Dashboard ---
  'dashboard_title': 'Übersicht',
  'dashboard_statistics': 'Statistiken',
  'dashboard_notifications': 'Benachrichtigungen',
  'dashboard_activity_feed': 'Aktivitäten',
  'dashboard_recent_transactions': 'Letzte Buchungen',
  'dashboard_no_activity': 'Noch keine Aktivität.',
  'dashboard_no_transactions':
      'Noch keine Buchungen. Tippe auf +, um die erste hinzuzufügen!',
  'dashboard_net_balance': 'Nettosaldo',
  'dashboard_amount_hint': 'Betrag',
  'dashboard_custom_category_hint': 'Eigene Kategorie eingeben...',
  'dashboard_pick_date': 'Datum wählen',
  'dashboard_transaction_added': 'Buchung hinzugefügt!',
  'home_welcome': 'Willkommen, {name}',
  'home_default_name': 'schön, dass du da bist',
  'home_subtitle': 'Bringen wir heute Ordnung in deine Finanzen.',
  'home_new_group': 'Neu',
  'home_group_name_hint': 'z. B. Sommerreise',
  'home_groups_empty': 'Noch keine Gruppen. Tippe auf + Neu, um loszulegen!',
  'home_members_loading': 'Mitglieder werden geladen…',
  'home_members_count': '{count} Mitglieder',
  'home_quick_add': 'Buchung hinzufügen',
  'home_switch_to_light': 'Zum hellen Design wechseln',
  'home_switch_to_dark': 'Zum dunklen Design wechseln',
  'home_switch_language': 'Sprache wechseln',
  'home_minimize_title': 'Zahlungen minimieren',
  'home_minimize_description':
      'Splixa vereinfacht Gruppensalden, damit alle mit möglichst wenigen Zahlungen ausgleichen können.',
  'minimize_without_title': 'Ohne minimierte Zahlungen',
  'minimize_without_description':
      'Es sind zwei getrennte Zahlungen nötig. Person B bekommt Geld nur, um denselben Betrag an Person C weiterzugeben.',
  'minimize_with_title': 'Mit minimierten Zahlungen',
  'minimize_with_description':
      'Splixa spart den Zwischenschritt. Person A zahlt direkt an Person C und gleicht dieselben Salden mit einer Zahlung aus.',
  'minimize_person_a': 'Person A',
  'minimize_person_b': 'Person B',
  'minimize_person_c': 'Person C',
  'minimize_pays_100': 'Zahlt 100',
  'minimize_one_fewer': '1 Zahlung weniger',
  // --- Statistics ---
  'statistics_title': 'Statistiken',
  'statistics_category_distribution': 'Kategorien (dieser Monat)',
  'statistics_no_expenses_this_month':
      'Du hast in diesem Monat keine Ausgaben.',
  'statistics_heatmap_title': 'Aktivitäts-Heatmap',
  'statistics_heatmap_activity_count': 'Aktivitäten',
  // --- Auth: login ---
  'login_title': 'Bei Splixa anmelden',
  'login_username_required': 'Gib deinen Nutzernamen ein.',
  'login_password_required': 'Gib dein Passwort ein.',
  'login_username_label': 'Nutzername (@nutzername)',
  'login_password_label': 'Passwort',
  'login_forgot_password': 'Passwort vergessen?',
  'login_submit': 'Anmelden',
  'login_or': 'oder',
  'login_google_continue': 'Mit Google fortfahren',
  'login_no_account': 'Noch kein Konto? Registrieren',
  'login_welcome': 'Willkommen bei Splixa',
  'login_identifier_subtitle':
      'Melde dich mit deiner E-Mail-Adresse oder deinem Nutzernamen und deinem Passwort an.',
  'login_identifier_label': 'E-Mail oder Nutzername',
  'login_identifier_hint': 'du@beispiel.com oder @nutzername',
  'login_identifier_required':
      'Gib deine E-Mail-Adresse oder deinen Nutzernamen ein.',
  // --- Auth: register ---
  'register_title': 'Bei Splixa registrieren',
  'register_username_too_short':
      'Der Nutzername muss mindestens 3 Zeichen haben.',
  'register_email_invalid': 'Gib eine gültige E-Mail-Adresse ein.',
  'register_password_too_short':
      'Das Passwort muss mindestens 6 Zeichen haben.',
  'register_success': 'Registrierung erfolgreich! Bitte melde dich an.',
  'register_email_label': 'E-Mail',
  'register_submit': 'Registrieren',
  'register_have_account': 'Schon ein Konto? Anmelden',
  // --- Auth: Google profile completion ---
  'profile_setup_title': 'Wie sollen wir dich nennen?',
  'profile_setup_subtitle':
      'Wähle einen eindeutigen Nutzernamen, damit Freunde dich bei Splixa finden.',
  'profile_setup_username_label': 'Nutzername',
  'profile_setup_username_hint': 'dein_nutzername',
  'profile_setup_username_helper':
      '3–30 Zeichen; nur Buchstaben, Zahlen und Unterstrich.',
  'profile_setup_continue': 'Weiter zu Splixa',
  'profile_setup_use_other_account': 'Anderes Konto verwenden',
  'profile_setup_username_taken':
      'Dieser Nutzername ist vergeben. Probiere einen anderen.',
  'profile_setup_session_expired':
      'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.',
  'profile_setup_timeout':
      'Die Anfrage hat zu lange gedauert. Bitte versuche es erneut.',
  'profile_setup_failed':
      'Dein Nutzername konnte nicht gespeichert werden. Bitte versuche es erneut.',
  // --- Auth: forgot / update password ---
  'forgot_password_title': 'Passwort vergessen',
  'forgot_password_email_invalid': 'Gib eine gültige E-Mail-Adresse ein.',
  'forgot_password_sent_message':
      'Wir haben einen 8-stelligen Wiederherstellungscode an deine E-Mail-Adresse geschickt.',
  'forgot_password_back_to_login': 'Zurück zur Anmeldung',
  'forgot_password_prompt':
      'Gib die E-Mail-Adresse deines Kontos ein und wir senden dir einen 8-stelligen Wiederherstellungscode.',
  'forgot_password_email_label': 'E-Mail',
  'forgot_password_send_link': 'Wiederherstellungscode senden',
  'forgot_password_send_code': 'Wiederherstellungscode senden',
  'login_verification_title': 'Bestätigung in zwei Schritten',
  'login_verification_prompt':
      'Gib den 8-stelligen Bestätigungscode ein, der an {email} gesendet wurde.',
  'login_verification_submit': 'Bestätigen und anmelden',
  'auth_code_label': '8-stelliger Code',
  'auth_code_eight_digits_required': 'Der Code muss 8 Stellen haben.',
  'auth_code_resend': 'Code erneut senden',
  'auth_code_resending': 'Wird gesendet...',
  'auth_code_resent':
      'Ein neuer Bestätigungscode wurde an deine E-Mail-Adresse gesendet.',
  'auth_code_invalid_or_expired': 'Der Code ist ungültig oder abgelaufen.',
  'reset_password_code_title': 'Passwort zurücksetzen',
  'reset_password_code_prompt':
      'Gib den an {email} gesendeten Wiederherstellungscode und dein neues Passwort ein.',
  'reset_password_code_submit': 'Code bestätigen und Passwort ändern',
  'update_password_title': 'Neues Passwort festlegen',
  'update_password_too_short': 'Das Passwort muss mindestens 6 Zeichen haben.',
  'update_password_success': 'Dein Passwort wurde erfolgreich aktualisiert!',
  'update_password_prompt':
      'Lege bitte ein neues Passwort für dein Konto fest.',
  'update_password_new_label': 'Neues Passwort',
  'update_password_submit': 'Passwort aktualisieren',
  // --- Groups: list ---
  'groups_title': 'Gruppen',
  'groups_empty_title': 'Du bist noch in keiner Gruppe.',
  'groups_empty_subtitle':
      'Tippe unten rechts auf +, um deine erste Gruppe zu erstellen.',
  'groups_tap_for_details': 'Für Gruppendetails tippen',
  'groups_create_new_group': 'Neue Gruppe erstellen',
  'groups_name_label': 'Gruppenname',
  'groups_create_button': 'Erstellen',
  // --- Groups: detail screen ---
  'groups_participants_suffix': 'Teilnehmende',
  'groups_participants_load_error': 'Teilnehmende konnten nicht geladen werden',
  'groups_chat_tooltip': 'Gruppenchat',
  'groups_invite_friend_tooltip': 'Freund einladen',
  'groups_paid_verb': 'hat gezahlt',
  'groups_tab_pending': 'Offen',
  'groups_tab_active': 'Aktiv',
  'groups_tab_archived': 'Archiv',
  'groups_no_transactions':
      'Noch keine Buchungen. Füge die erste Ausgabe hinzu.',
  'groups_empty_pending': 'Keine Ausgaben warten auf Freigabe.',
  'groups_empty_active': 'Keine aktiven Ausgaben.',
  'groups_empty_archived': 'Keine archivierten Ausgaben.',
  'groups_add_expense': 'Ausgabe hinzufügen',
  'groups_archive_all_button': 'Alle archivieren',
  'groups_action_failed':
      'Die Aktion konnte nicht abgeschlossen werden. Bitte versuche es erneut.',
  'groups_archive_failed':
      'Die Ausgabe konnte nicht archiviert werden. Bitte versuche es erneut.',
  'groups_status_payer': 'Zahler',
  'groups_status_pending': 'Warte auf Freigabe',
  'groups_status_approved_self': 'Freigegeben',
  'groups_status_active_debt': 'Offene Schuld',
  'groups_status_payment_pending_payer': 'Warte auf Zahlungsbestätigung',
  'groups_status_payment_reported': 'Zahlung gemeldet',
  'groups_status_settled': 'Bezahlt',
  'groups_status_rejected': 'Abgelehnt',
  'groups_action_approve': 'Freigeben',
  'groups_action_mark_paid': 'Als bezahlt markieren',
  'groups_action_confirm_payment': 'Zahlung bestätigen',
  'groups_balance_title': 'Gruppensaldo',
  'groups_no_active_debt': 'Keine offenen Schulden.',
  'groups_creditor_label': 'Bekommt',
  'groups_debtor_label': 'Schuldet',
  'groups_filter_payer_label': 'Bezahlt von',
  // --- Groups: info screen ---
  'group_info_change_picture': 'Gruppenbild ändern',
  'group_info_group_picture': 'Gruppenbild',
  'group_info_admin': 'Admin',
  'group_info_remove_member': 'Mitglied entfernen',
  'group_info_this_member': 'dieses Mitglied',
  'group_info_remove_member_title': 'Mitglied entfernen?',
  'group_info_remove_member_body':
      '{member} verliert den Zugriff auf diese Gruppe und ihren Chat.',
  'group_info_remove': 'Entfernen',
  'group_info_title': 'Gruppeninfo',
  'group_info_leave_button': 'Gruppe verlassen',
  'group_info_delete_button': 'Gruppe löschen',
  'group_info_leave_confirm':
      'Möchtest du "%s" wirklich verlassen? Deine bisherigen Ausgaben bleiben in der Gruppe.',
  'group_info_leave_confirm_button': 'Verlassen',
  'group_info_delete_confirm':
      'Möchtest du "%s" mit allen Ausgaben- und Mitgliedsdaten wirklich dauerhaft löschen? Das lässt sich nicht rückgängig machen.',
  // --- Groups: chat ---
  'groups_chat_title': 'Chat von {group}',
  'groups_chat_suffix': 'Chat',
  'groups_chat_empty': 'Noch keine Nachrichten. Schreib die erste!',
  'groups_chat_input_hint': 'Nachricht schreiben...',
  // --- Groups: add expense sheet ---
  'groups_scan_receipt': 'Beleg scannen',
  'groups_custom_exchange_rate': 'Eigener Wechselkurs',
  'groups_pro_tool_coming_soon': 'Dieses Pro-Werkzeug kommt bald.',
  'dashboard_custom_rate_coming_soon':
      'Der Editor für eigene Wechselkurse kommt bald.',
  'groups_expense_desc_label': 'Wofür?',
  'groups_total_amount_label': 'Gesamtbetrag',
  'groups_split_equal': 'Gleich (=)',
  'groups_split_percentage': 'Prozent (%)',
  'groups_split_exact': 'Betrag',
  'groups_split_for_whom': 'Für wen ist diese Ausgabe?',
  'groups_auto_badge': 'auto',
  'groups_expense_validation_generic':
      'Bitte gib gültige Angaben ein und wähle mindestens 1 Person.',
  'groups_percentage_validation':
      'Höchstens 1 Person darf ohne Prozentangabe bleiben, und die Summe muss 100 ergeben.',
  'groups_percentage_total_validation':
      'Die Prozentwerte müssen zusammen 100 ergeben.',
  'groups_exact_validation':
      'Höchstens 1 Person darf ohne Betrag bleiben, und die Summe muss dem Ausgabenbetrag entsprechen.',
  // --- Groups: invite friend modal ---
  'groups_invited_snackbar': 'Eingeladen!',
  'groups_invite_modal_title': 'Freund in die Gruppe einladen',
  'groups_invite_search_hint': 'Deine Freunde durchsuchen',
  'groups_no_friends_to_invite': 'Du hast niemanden zum Einladen.',
  'groups_no_friends_hint': 'Füge zuerst im Tab „Social“ Freunde hinzu.',
  'groups_no_search_match': 'Keine Freunde passen zu deiner Suche.',
  // --- Debts ---
  'debts_back_tooltip': 'Zurück',
  'debts_title': 'Schulden',
  'debts_tab_mine': 'Meine Schulden',
  'debts_tab_owed_to_me': 'Mir geschuldet',
  'debts_tab_approvals': 'Freigaben',
  'debts_tab_summary': 'Übersicht',
  'debts_user_info_unavailable':
      'Die Nutzerdaten konnten nicht geladen werden.',
  'debts_not_in_any_group': 'Du bist noch in keiner Gruppe.',
  'debts_owed_by_prefix': 'Geschuldet an',
  'debts_owed_to_me_prefix': 'Schuldet uns',
  'debts_no_active_debt': 'Du hast keine offenen Schulden.',
  'debts_no_active_credit': 'Dir schuldet gerade niemand etwas.',
  'debts_total_debt_label': 'Gesamtschuld',
  'debts_total_credit_label': 'Gesamtguthaben',
  'debts_awaiting_my_approval': 'Wartet auf deine Freigabe',
  'debts_no_awaiting_my_approval': 'Keine Schulden warten auf deine Freigabe.',
  'debts_awaiting_other_approval': 'Wartet auf Freigabe der Gegenseite',
  'debts_no_awaiting_other_approval':
      'Keine Schulden warten auf die Freigabe der Gegenseite.',
  'debts_reject_tooltip': 'Ablehnen',
  'debts_no_settlement': 'Keine Schuld auszugleichen.',
  'debts_settled_debt_subtitle': 'Ausgeglichene Schuld',
  'debts_total_prefix': 'Gesamt',
  'debts_filter_group_label': 'Gruppe',
  'debts_clear_filters_tooltip': 'Filter zurücksetzen',
  // --- Notifications ---
  'notifications_login_required':
      'Melde dich an, um deine Benachrichtigungen zu sehen.',
  'notifications_empty_title': 'Du hast noch keine Benachrichtigungen.',
  'notifications_empty_subtitle':
      'Neuigkeiten zu Ausgaben und Freigaben aus deinen Gruppen erscheinen hier.',
  // --- Notifications: dynamically built messages ---
  'notif_new_expense_title': 'Neue Ausgabe',
  'notif_new_expense_message':
      '{sender} hat dich in der Gruppe {group} zur Ausgabe "{desc}" hinzugefügt. Betrag: {amount}. Wartet auf deine Freigabe.',
  'notif_payment_confirmation_title': 'Zahlung gemeldet',
  'notif_payment_confirmation_message':
      '{sender} hat eine Zahlung für "{desc}" in der Gruppe {group} gemeldet.',
  'notif_debt_approved_title': 'Schuld freigegeben',
  'notif_debt_approved_message':
      '{sender} hat die Schuld für "{desc}" in der Gruppe {group} freigegeben.',
  'notif_debt_rejected_title': 'Schuld abgelehnt',
  'notif_debt_rejected_message':
      '{sender} hat die Schuld für "{desc}" in der Gruppe {group} abgelehnt.',
  'notif_debt_settled_title': 'Zahlung bestätigt',
  'notif_debt_settled_message':
      '{sender} hat deine Zahlung für "{desc}" in der Gruppe {group} bestätigt. Die Schuld ist ausgeglichen.',
  'notif_default_group': 'Eine Gruppe',
  'notif_default_user': 'Ein Nutzer',
  'notif_default_expense_desc': 'Ausgabe',
  // --- Profile ---
  'profile_title': 'Profil',
  'profile_email_missing': 'Keine E-Mail hinterlegt',
  'profile_user_fallback': 'Splixa-Nutzer',
  'profile_manage_subscription': 'Abo verwalten',
  'profile_upgrade_pro': 'Auf Pro upgraden',
  'profile_settings': 'Einstellungen',
  'profile_invite_friends': 'Freunde einladen',
  'profile_download_monthly_report': 'Monatsbericht herunterladen',
  'profile_download_monthly_report_pro': 'Monatsbericht herunterladen · Pro',
  'profile_contact_us': 'Kontakt',
  'profile_support_placeholder':
      'Der Support-Kontakt wird hier verfügbar sein.',
  'profile_terms': 'Nutzungsbedingungen',
  'profile_privacy': 'Datenschutz',
  'profile_choose_picture': 'Profilbild wählen',
  'profile_tap_choose_photo': 'Tippen, um ein Foto zu wählen',
  'profile_username_label': 'Nutzername',
  'profile_email_label': 'E-Mail',
  'profile_dark_mode': 'Dunkles Design',
  'profile_link_failed': 'Diese Seite konnte nicht geöffnet werden.',
  'profile_delete_dialog_title': 'Konto und Daten löschen?',
  'profile_delete_dialog_body':
      'Das ist endgültig. Dein Profil, deine persönlichen Buchungen, Nachrichten und sozialen Verbindungen werden gelöscht. Geteilte Finanzhistorie bleibt anonymisiert erhalten, damit die Salden der anderen Mitglieder korrekt bleiben.',
  'profile_delete_group_warning':
      'Wenn du eine Gruppe mit anderen Mitgliedern verwaltest, musst du sie zuerst löschen oder die Verwaltung übertragen.',
  'profile_delete_type_confirm': 'Tippe DELETE zur Bestätigung:',
  'profile_delete_transfer_first':
      'Lösche oder übertrage zuerst die von dir verwalteten Gruppen:',
  'profile_delete_failed':
      'Das Konto konnte nicht gelöscht werden. Bitte versuche es erneut.',
  'profile_delete_invalid_response':
      'Der Löschdienst hat eine ungültige Antwort zurückgegeben.',
  'profile_deleting': 'Wird gelöscht…',
  'profile_delete_permanently': 'Endgültig löschen',
  'profile_membership_pro': 'PRO',
  'profile_membership_standard': 'STANDARD',
  'profile_unknown_username': '@unbekannt',
  'profile_edit_tile': 'Profil bearbeiten',
  'profile_currency_tile': 'Währung',
  'profile_change_password_tile': 'Passwort ändern',
  'profile_download_report_tile': 'Monatsbericht herunterladen (PDF)',
  'profile_pdf_error': 'PDF konnte nicht erstellt werden: %s',
  'profile_logout': 'Abmelden',
  'profile_danger_zone': 'Gefahrenbereich',
  'profile_delete_account_data': 'Konto und Daten löschen',
  'profile_delete_account_title': 'Konto löschen',
  'profile_delete_account_confirm':
      'Möchtest du dein Konto und alle Daten wirklich dauerhaft löschen? Das lässt sich nicht rückgängig machen.',
  'profile_avatar_url_label': 'Avatar-URL (optional)',
  'profile_update_success': 'Profil erfolgreich aktualisiert.',
  'profile_bio_label': 'Über mich',
  'profile_bio_hint': 'Erzähl anderen etwas über dich...',
  'profile_bio_empty': 'Noch keine Angaben hinzugefügt.',
  // --- Profile: PDF export ---
  'pdf_title': 'Monatsbericht - %s',
  'pdf_total_income': 'Einnahmen gesamt',
  'pdf_total_expense': 'Ausgaben gesamt',
  'pdf_net_balance': 'Nettosaldo',
  'pdf_transaction_details': 'Buchungsdetails',
  'pdf_no_transactions': 'Keine Buchungen in diesem Monat.',
  'pdf_header_type': 'Art',
  // --- Social ---
  'social_title': 'Social',
  'social_request_sent_snackbar': 'Anfrage gesendet!',
  'social_user_not_found': 'Nutzer nicht gefunden.',
  'social_search_results_header': 'Suchergebnisse',
  'social_add_friend_tooltip': 'Freund hinzufügen',
  'social_search_hint': 'Nutzer nach @nutzername suchen',
  'social_search_tooltip': 'Nutzer suchen',
  'social_no_friends_title': 'Du hast noch keine Freunde.',
  'social_no_friends_subtitle':
      'Suche oben nach einem Nutzernamen und sende eine Freundschaftsanfrage.',
  'social_request_sent_prefix': 'Anfrage gesendet: %s',
  'social_pending_status': 'Ausstehend...',
  'social_incoming_request_prefix': 'Anfrage an dich: %s',
  'social_friend_prefix': 'Freund: %s',
  'social_default_chat_title': 'Freund',
  // --- Social: other user profile ---
  'other_profile_title': 'Nutzerprofil',
  'other_profile_unknown': 'Unbekannt',
  'other_profile_no_shared_groups': 'Keine gemeinsamen Gruppen',
  'other_profile_shared_groups_count': 'Ihr habt %s gemeinsame Gruppen',
  'other_profile_send_message': 'Nachricht senden',
  // --- Subscriptions: paywall ---
  'paywall_title': 'Auf Splixa Pro upgraden',
  'paywall_subtitle':
      'Erstelle unbegrenzt Gruppen, nutze alle Statistiken und genieße deine finanzielle Freiheit!',
  'paywall_no_packages': 'Derzeit sind keine Pakete verfügbar.',
  'paywall_restore_purchases': 'Käufe wiederherstellen',
  'paywall_restore_success': 'Käufe wiederhergestellt!',
  'paywall_processing_purchase': 'Kauf wird verarbeitet...',
  'paywall_welcome_pro': 'Willkommen bei Splixa Pro!',
  'paywall_purchase_failed':
      'Der Vorgang wurde abgebrochen oder ist fehlgeschlagen.',
  'paywall_benefit_unlimited_groups': 'Unbegrenzt Gruppen erstellen',
  'paywall_benefit_statistics': 'Alle Statistiken und Berichte nutzen',
  'paywall_benefit_freedom': 'Genieße deine finanzielle Freiheit',
  'paywall_no_packages_hint': 'Die Pakete erscheinen hier in Kürze.',
  'paywall_footer_note': 'Du kannst dein Abo jederzeit kündigen.',
  // --- Friendly error messages ---
  'error_generic_short': 'Etwas ist schiefgelaufen. Bitte versuche es erneut.',
  'error_auth_generic':
      'Es ist ein Problem aufgetreten. Bitte versuche es erneut.',
  'error_google_cancelled':
      'Die Google-Anmeldung wurde abgebrochen oder das Gerät konnte nicht verifiziert werden. Versuche es erneut.',
  'error_google_configuration':
      'Die Google-Anmeldung ist nicht korrekt konfiguriert.',
  'error_google_unavailable':
      'Die Google-Anmeldung ist auf diesem Gerät nicht verfügbar.',
  'error_google_timeout':
      'Die Google-Anmeldung hat zu lange gedauert. Bitte versuche es erneut.',
  'error_google_failed':
      'Die Google-Anmeldung konnte nicht abgeschlossen werden. Versuche es erneut.',
  'error_invalid_credentials': 'Nutzername oder Passwort ist falsch.',
  'error_email_not_confirmed':
      'Deine E-Mail-Adresse wurde noch nicht bestätigt.',
  'error_email_already_registered':
      'Mit dieser E-Mail-Adresse gibt es bereits ein Konto.',
  'error_password_too_short':
      'Das Passwort ist zu kurz. Bitte wähle ein längeres.',
  'error_rate_limited':
      'Zu viele Versuche. Bitte versuche es gleich noch einmal.',
  'error_duplicate_record': 'Dieser Eintrag existiert bereits.',
  'error_forbidden': 'Dazu hast du keine Berechtigung.',
  'error_not_found': 'Eintrag nicht gefunden.',
  'error_server_generic':
      'Bei der Verbindung zum Server gab es ein Problem. Bitte versuche es erneut.',
  // --- Main scaffold (bottom nav) ---
  'nav_dashboard': 'Übersicht',
  'nav_debts': 'Schulden',
  'nav_groups': 'Gruppen',
  'nav_social': 'Social',
  'nav_profile': 'Profil',
  // --- Router fallback titles (used when navigation `extra` is absent) ---
  'route_fallback_group_detail': 'Gruppendetails',
  'route_fallback_group_info': 'Gruppeninfo',
  'route_fallback_group': 'Gruppe',
  'route_fallback_chat': 'Chat',
  // --- Activity feed descriptions ---
  'activity_someone': 'Jemand',
  'activity_a_group': 'Eine Gruppe',
  'activity_became_friends': 'Du bist jetzt mit {name} befreundet.',
  'activity_added_expense':
      'Du hast in {group} eine Ausgabe über {amount} hinzugefügt.',

  // --- Onboarding ---
  'onboarding_skip': 'Überspringen',
  'onboarding_continue': 'Weiter',
  'onboarding_start_free': 'Kostenlos starten',
  'onboarding_no_card':
      'Keine Karte nötig. Upgrade nur, wenn Pro dir Zeit spart.',
  'onboarding_persistence_error':
      'Deine Auswahl konnte nicht gespeichert werden. Bitte versuche es erneut.',
  'onboarding_p1_eyebrow': 'PRIVAT + GEMEINSAM',
  'onboarding_p1_title': 'Allein erfassen. Gemeinsam teilen.',
  'onboarding_p1_description':
      'Dein Budget und alle gemeinsamen Ausgaben an einem Ort.',
  'onboarding_p1_proof_1': 'Eigenes Budget',
  'onboarding_p1_proof_2': 'Gruppenausgaben',
  'onboarding_p2_eyebrow': 'KEIN UNANGENEHMES RECHNEN',
  'onboarding_p2_title': 'Fair teilen. Klar abrechnen.',
  'onboarding_p2_description':
      'Gleich, prozentual oder exakt — alle kennen den nächsten Schritt.',
  'onboarding_p2_proof_1': 'Flexible Aufteilung',
  'onboarding_p2_proof_2': 'Klare Freigaben',
  'onboarding_p3_eyebrow': 'ZAHLEN, DIE AUFGEHEN',
  'onboarding_p3_title': 'Frei reisen. Jeden Kurs behalten.',
  'onboarding_p3_description':
      'Originalbeträge und feste Kurse halten den gestrigen Saldo verlässlich.',
  'onboarding_p3_proof_1': 'Feste Kurse',
  'onboarding_p3_proof_2': 'Verlässliche Historie',
  'onboarding_p4_eyebrow': 'KOSTENLOS STARTEN',
  'onboarding_p4_title': 'Gratis starten. Pro nutzen, wenn es sich lohnt.',
  'onboarding_p4_description':
      'Schalte schnelle Erfassung, tiefere Einblicke und erweiterte Berichte frei, wenn du sie brauchst.',
  'onboarding_p4_proof_1': 'Keine Zwangstestphase',
  'onboarding_p4_proof_2': 'Jederzeit kündbar',

  // --- Subscriptions: paywall copy ---
  'paywall_appbar_title': 'Splixa Pro',
  'paywall_close': 'Schließen',
  'paywall_hero_title': 'Mach aus Geldverwaltung eine Zwei-Minuten-Aufgabe',
  'paywall_hero_subtitle':
      'Der Kern von Splixa bleibt kostenlos. Hol dir Pro, wenn Automatisierung, Kontrolle und tiefere Antworten mehr wert sind als die Zeit, die sie sparen.',
  'paywall_benefits_title': 'Das schaltet Pro frei',
  'paywall_benefit_1_title': 'Unbegrenzt Gruppen',
  'paywall_benefit_1_body':
      'Halte jede Reise, jeden Haushalt und jedes Projekt aktiv – ganz ohne Gruppenlimit.',
  'paywall_benefit_2_title': 'Erkenne die Muster hinter deinen Ausgaben',
  'paywall_benefit_2_body':
      'Sieh dir Kategorienverteilung und Aktivitätsmuster auf einen Blick an.',
  'paywall_benefit_3_title': 'Saubere Monatsberichte exportieren',
  'paywall_benefit_3_body':
      'Mach aus deinen persönlichen Daten mit einem Tipp ein teilbares PDF.',
  'paywall_benefit_4_title': 'Roadmap-Vorschau: weniger tippen, mehr Kontrolle',
  'paywall_benefit_4_body':
      'Belegscan und eigene Wechselkurse kommen als Nächstes.',
  'paywall_choose_plan': 'Wähle deinen Tarif',
  'paywall_best_value': 'BESTES ANGEBOT',
  'paywall_continue_free': 'Jetzt nicht – kostenlos weiter',
  'paywall_restore': 'Käufe wiederherstellen',
  'paywall_restore_restored': 'Dein Pro-Zugang wurde wiederhergestellt.',
  'paywall_restore_none':
      'Für dieses Store-Konto wurde kein aktiver Pro-Kauf gefunden.',
  'paywall_welcome_message': 'Willkommen bei Splixa Pro.',
  'paywall_purchase_failed_message':
      'Der Kauf wurde abgebrochen oder konnte nicht abgeschlossen werden.',
  'paywall_no_packages_available':
      'Die Tarife sind vorübergehend nicht verfügbar. Bitte versuche es erneut.',
  'paywall_retry': 'Erneut versuchen',
  'paywall_terms_link': 'Nutzungsbedingungen',
  'paywall_privacy_link': 'Datenschutzerklärung',
  'paywall_store_disclosure':
      'Die Zahlung wird über dein Store-Konto abgerechnet. Verwalte oder kündige das Abo in den Abo-Einstellungen im App Store oder bei Google Play.',
  'paywall_link_failed': 'Die Seite konnte nicht geöffnet werden.',
  'paywall_plan_annual': 'Pro jährlich',
  'paywall_plan_monthly': 'Pro monatlich',
  'paywall_period_annual': '/ Jahr',
  'paywall_period_monthly': '/ Monat',
  'paywall_monthly_equivalent': '{price} pro Monat gerechnet',
  'paywall_continue_with_plan': 'Mit {plan} fortfahren',
  'paywall_renewal_annual':
      '{price} wird jetzt abgebucht. Das Abo verlängert sich jährlich, bis du kündigst.',
  'paywall_renewal_monthly':
      '{price} wird jetzt abgebucht. Das Abo verlängert sich monatlich, bis du kündigst.',

  // --- Relative time (activity feed, chat, notifications) ---
  'time_just_now': 'Gerade eben',
  'time_minutes_ago': 'vor {count} Min.',
  'time_hours_ago': 'vor {count} Std.',
  'time_days_ago': 'vor {count} T.',

  // --- Profile sections & language picker ---
  'profile_section_account': 'Konto',
  'profile_section_subscription': 'Abo',
  'profile_section_preferences': 'Einstellungen',
  'profile_section_support': 'Support',
  'profile_section_legal': 'Rechtliches',
  'language_picker_title': 'Sprache wählen',
};
