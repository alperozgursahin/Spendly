// GENERATED-STYLE LOCALE CATALOG — edit by hand, keep keys in sync.
//
// Key order mirrors lib/core/l10n/strings_en.dart, the source locale.
// Every key present in `enStrings` must exist here; `localization_catalog_test`
// fails the build otherwise. Placeholders such as {name} must be preserved
// verbatim — only the surrounding words are translated.

// Launch locale — machine-assisted translation, pending native review.
const Map<String, String> itStrings = {
  // --- Common / shared ---
  'language_selector_label': 'Lingua dell’app',
  'common_all': 'Tutto',
  'common_reset': 'Reimposta',
  'common_filter': 'Filtra',
  'common_save': 'Salva',
  'common_cancel': 'Annulla',
  'common_delete': 'Elimina',
  'common_edit': 'Modifica',
  'common_add': 'Aggiungi',
  'common_close': 'Chiudi',
  'common_send': 'Invia',
  'common_you': 'Tu',
  'common_user': 'Utente',
  'common_loading': 'Caricamento...',
  'common_retry': 'Riprova',
  'common_error_generic': 'Qualcosa è andato storto. Riprova.',
  'common_date': 'Data',
  'common_category': 'Categoria',
  'common_expense': 'Spesa',
  'common_income': 'Entrata',
  'common_currency': 'Valuta',
  'exchange_rate_unavailable':
      'Non è stato possibile caricare il tasso di cambio aggiornato. Controlla la connessione e riprova.',
  // --- Category names (shared across dashboard, statistics, add-expense) ---
  'category_market': 'Spesa',
  'category_food': 'Cibo',
  'category_transport': 'Trasporti',
  'category_entertainment': 'Svago',
  'category_salary': 'Stipendio',
  'category_dues': 'Quote',
  'category_bill': 'Bolletta',
  'category_other': 'Altro',
  // --- Month abbreviations ---
  'month_jan': 'Gen',
  'month_feb': 'Feb',
  'month_mar': 'Mar',
  'month_apr': 'Apr',
  'month_may': 'Mag',
  'month_jun': 'Giu',
  'month_jul': 'Lug',
  'month_aug': 'Ago',
  'month_sep': 'Set',
  'month_oct': 'Ott',
  'month_nov': 'Nov',
  'month_dec': 'Dic',
  // --- Dashboard ---
  'dashboard_title': 'Dashboard',
  'dashboard_statistics': 'Statistiche',
  'dashboard_notifications': 'Notifiche',
  'dashboard_activity_feed': 'Attività',
  'dashboard_recent_transactions': 'Movimenti recenti',
  'dashboard_no_activity': 'Ancora nessuna attività.',
  'dashboard_no_transactions':
      'Ancora nessun movimento. Tocca + per aggiungere il primo!',
  'dashboard_net_balance': 'Saldo netto',
  'dashboard_amount_hint': 'Importo',
  'dashboard_custom_category_hint': 'Scrivi una categoria personalizzata...',
  'dashboard_pick_date': 'Scegli la data',
  'dashboard_transaction_added': 'Movimento aggiunto!',
  'home_welcome': 'Ciao, {name}',
  'home_default_name': 'a te',
  'home_subtitle': 'Mettiamo in ordine le tue finanze oggi.',
  'home_new_group': 'Nuovo',
  'home_group_name_hint': 'es. Viaggio estivo',
  'home_groups_empty':
      'Ancora nessun gruppo. Tocca + Nuovo per iniziare a dividere!',
  'home_members_loading': 'Caricamento partecipanti…',
  'home_members_count': '{count} partecipanti',
  'home_quick_add': 'Aggiungi movimento',
  'home_switch_to_light': 'Passa al tema chiaro',
  'home_switch_to_dark': 'Passa al tema scuro',
  'home_switch_language': 'Cambia lingua',
  'home_minimize_title': 'Ridurre le transazioni',
  'home_minimize_description':
      'Splixa semplifica i saldi del gruppo così tutti pareggiano i conti con il minor numero possibile di pagamenti.',
  'minimize_without_title': 'Senza ridurre le transazioni',
  'minimize_without_description':
      'Servono due pagamenti separati. La persona B riceve denaro solo per girare lo stesso importo alla persona C.',
  'minimize_with_title': 'Con le transazioni ridotte',
  'minimize_with_description':
      'Splixa elimina l’intermediario. La persona A paga direttamente la persona C e chiude gli stessi saldi con un solo pagamento.',
  'minimize_person_a': 'Persona A',
  'minimize_person_b': 'Persona B',
  'minimize_person_c': 'Persona C',
  'minimize_pays_100': 'Paga 100',
  'minimize_one_fewer': '1 transazione in meno',
  // --- Statistics ---
  'statistics_title': 'Statistiche',
  'statistics_category_distribution':
      'Ripartizione per categoria (questo mese)',
  'statistics_no_expenses_this_month': 'Questo mese non hai spese.',
  'statistics_heatmap_title': 'Mappa delle attività',
  'statistics_heatmap_activity_count': 'attività',
  // --- Auth: login ---
  'login_title': 'Accedi a Splixa',
  'login_username_required': 'Inserisci il tuo nome utente.',
  'login_password_required': 'Inserisci la tua password.',
  'login_username_label': 'Nome utente (@nomeutente)',
  'login_password_label': 'Password',
  'login_forgot_password': 'Password dimenticata?',
  'login_submit': 'Accedi',
  'login_or': 'oppure',
  'login_google_continue': 'Continua con Google',
  'login_no_account': 'Non hai un account? Registrati',
  'login_welcome': 'Ti diamo il benvenuto su Splixa',
  'login_identifier_subtitle':
      'Accedi con la tua email o il tuo nome utente e la password.',
  'login_identifier_label': 'Email o nome utente',
  'login_identifier_hint': 'tu@esempio.com oppure @nomeutente',
  'login_identifier_required': 'Inserisci la tua email o il tuo nome utente.',
  // --- Auth: register ---
  'register_title': 'Registrati su Splixa',
  'register_username_too_short':
      'Il nome utente deve avere almeno 3 caratteri.',
  'register_email_invalid': 'Inserisci un indirizzo email valido.',
  'register_password_too_short': 'La password deve avere almeno 6 caratteri.',
  'register_success': 'Registrazione completata! Ora puoi accedere.',
  'register_email_label': 'Email',
  'register_submit': 'Registrati',
  'register_have_account': 'Hai già un account? Accedi',
  // --- Auth: Google profile completion ---
  'profile_setup_title': 'Come vuoi che ti chiamiamo?',
  'profile_setup_subtitle':
      'Scegli un nome utente unico così i tuoi amici potranno trovarti su Splixa.',
  'profile_setup_username_label': 'Nome utente',
  'profile_setup_username_hint': 'tuo_nomeutente',
  'profile_setup_username_helper':
      'Da 3 a 30 caratteri; solo lettere, numeri e trattino basso.',
  'profile_setup_continue': 'Continua su Splixa',
  'profile_setup_use_other_account': 'Usa un altro account',
  'profile_setup_username_taken':
      'Questo nome utente è già in uso. Provane un altro.',
  'profile_setup_session_expired':
      'La tua sessione è scaduta. Accedi di nuovo.',
  'profile_setup_timeout': 'La richiesta è scaduta. Riprova.',
  'profile_setup_failed':
      'Non è stato possibile salvare il tuo nome utente. Riprova.',
  // --- Auth: forgot / update password ---
  'forgot_password_title': 'Password dimenticata',
  'forgot_password_email_invalid': 'Inserisci un indirizzo email valido.',
  'forgot_password_sent_message':
      'Abbiamo inviato un codice di recupero di 8 cifre alla tua email.',
  'forgot_password_back_to_login': 'Torna all’accesso',
  'forgot_password_prompt':
      'Inserisci l’email del tuo account e ti invieremo un codice di recupero di 8 cifre.',
  'forgot_password_email_label': 'Email',
  'forgot_password_send_link': 'Invia il codice di recupero',
  'forgot_password_send_code': 'Invia il codice di recupero',
  'login_verification_title': 'Verifica in due passaggi',
  'login_verification_prompt':
      'Inserisci il codice di verifica di 8 cifre inviato a {email}.',
  'login_verification_submit': 'Verifica e accedi',
  'auth_code_label': 'Codice di 8 cifre',
  'auth_code_eight_digits_required': 'Il codice deve avere 8 cifre.',
  'auth_code_resend': 'Invia di nuovo il codice',
  'auth_code_resending': 'Invio in corso...',
  'auth_code_resent':
      'Abbiamo inviato un nuovo codice di verifica alla tua email.',
  'auth_code_invalid_or_expired': 'Il codice non è valido o è scaduto.',
  'reset_password_code_title': 'Reimposta la password',
  'reset_password_code_prompt':
      'Inserisci il codice di recupero inviato a {email} e la tua nuova password.',
  'reset_password_code_submit': 'Verifica il codice e aggiorna la password',
  'update_password_title': 'Imposta una nuova password',
  'update_password_too_short': 'La password deve avere almeno 6 caratteri.',
  'update_password_success': 'La tua password è stata aggiornata!',
  'update_password_prompt': 'Imposta una nuova password per il tuo account.',
  'update_password_new_label': 'Nuova password',
  'update_password_submit': 'Aggiorna la password',
  // --- Groups: list ---
  'groups_title': 'Gruppi',
  'groups_empty_title': 'Non fai ancora parte di nessun gruppo.',
  'groups_empty_subtitle':
      'Tocca il pulsante + in basso a destra per creare il tuo primo gruppo.',
  'groups_tap_for_details': 'Tocca per i dettagli del gruppo',
  'groups_create_new_group': 'Crea un gruppo',
  'groups_name_label': 'Nome del gruppo',
  'groups_create_button': 'Crea',
  // --- Groups: detail screen ---
  'groups_participants_suffix': 'partecipanti',
  'groups_participants_load_error':
      'Non è stato possibile caricare i partecipanti',
  'groups_chat_tooltip': 'Chat del gruppo',
  'groups_invite_friend_tooltip': 'Invita un amico',
  'groups_paid_verb': 'ha pagato',
  'groups_tab_pending': 'In attesa',
  'groups_tab_active': 'Attive',
  'groups_tab_archived': 'Archivio',
  'groups_no_transactions': 'Ancora nessun movimento. Aggiungi la prima spesa.',
  'groups_empty_pending': 'Nessuna spesa in attesa di approvazione.',
  'groups_empty_active': 'Nessuna spesa attiva.',
  'groups_empty_archived': 'Nessuna spesa archiviata.',
  'groups_add_expense': 'Aggiungi spesa',
  'groups_archive_all_button': 'Archivia tutto',
  'groups_action_failed': 'Non è stato possibile completare l’azione. Riprova.',
  'groups_archive_failed':
      'Non è stato possibile archiviare la spesa. Riprova.',
  'groups_status_payer': 'Chi ha pagato',
  'groups_status_pending': 'In attesa di approvazione',
  'groups_status_approved_self': 'Approvata',
  'groups_status_active_debt': 'Debito attivo',
  'groups_status_payment_pending_payer': 'In attesa di conferma del pagamento',
  'groups_status_payment_reported': 'Pagamento segnalato',
  'groups_status_settled': 'Pagata',
  'groups_status_rejected': 'Rifiutata',
  'groups_action_approve': 'Approva',
  'groups_action_mark_paid': 'Segna come pagata',
  'groups_action_confirm_payment': 'Conferma il pagamento',
  'groups_balance_title': 'Saldo del gruppo',
  'groups_no_active_debt': 'Nessun debito attivo.',
  'groups_creditor_label': 'Deve ricevere',
  'groups_debtor_label': 'Deve',
  'groups_filter_payer_label': 'Pagata da',
  // --- Groups: info screen ---
  'group_info_change_picture': 'Cambia la foto del gruppo',
  'group_info_group_picture': 'Foto del gruppo',
  'group_info_admin': 'Amministratore',
  'group_info_remove_member': 'Rimuovi partecipante',
  'group_info_this_member': 'questo partecipante',
  'group_info_remove_member_title': 'Rimuovere il partecipante?',
  'group_info_remove_member_body':
      '{member} perderà l’accesso a questo gruppo e alla sua chat.',
  'group_info_remove': 'Rimuovi',
  'group_info_title': 'Info del gruppo',
  'group_info_leave_button': 'Esci dal gruppo',
  'group_info_delete_button': 'Elimina il gruppo',
  'group_info_leave_confirm':
      'Vuoi davvero uscire da "%s"? Le tue spese precedenti resteranno nel gruppo.',
  'group_info_leave_confirm_button': 'Esci',
  'group_info_delete_confirm':
      'Vuoi davvero eliminare definitivamente "%s" e tutti i dati di spese e partecipanti? L’azione non può essere annullata.',
  // --- Groups: chat ---
  'groups_chat_title': 'Chat di {group}',
  'groups_chat_suffix': 'Chat',
  'groups_chat_empty': 'Ancora nessun messaggio. Scrivi il primo!',
  'groups_chat_input_hint': 'Scrivi un messaggio...',
  // --- Groups: add expense sheet ---
  'groups_scan_receipt': 'Scansiona lo scontrino',
  'groups_custom_exchange_rate': 'Tasso di cambio personalizzato',
  'groups_pro_tool_coming_soon': 'Questo strumento Pro arriverà presto.',
  'dashboard_custom_rate_coming_soon':
      'L’editor del tasso personalizzato arriverà presto.',
  'groups_expense_desc_label': 'Per cosa?',
  'groups_total_amount_label': 'Importo totale',
  'groups_split_equal': 'Equa (=)',
  'groups_split_percentage': 'Percentuale (%)',
  'groups_split_exact': 'Importo',
  'groups_split_for_whom': 'Per chi è questa spesa?',
  'groups_auto_badge': 'auto',
  'groups_expense_validation_generic':
      'Inserisci dati validi e seleziona almeno 1 persona.',
  'groups_percentage_validation':
      'Al massimo 1 persona può restare senza percentuale e il totale deve fare 100.',
  'groups_percentage_total_validation': 'Le percentuali devono sommare a 100.',
  'groups_exact_validation':
      'Al massimo 1 persona può restare senza importo e il totale deve corrispondere all’importo della spesa.',
  // --- Groups: invite friend modal ---
  'groups_invited_snackbar': 'Invito inviato!',
  'groups_invite_modal_title': 'Invita un amico nel gruppo',
  'groups_invite_search_hint': 'Cerca tra i tuoi amici',
  'groups_no_friends_to_invite': 'Non hai amici da invitare.',
  'groups_no_friends_hint': 'Aggiungi prima degli amici dalla scheda Social.',
  'groups_no_search_match': 'Nessun amico corrisponde alla ricerca.',
  // --- Debts ---
  'debts_back_tooltip': 'Indietro',
  'debts_title': 'Debiti',
  'debts_tab_mine': 'I miei debiti',
  'debts_tab_owed_to_me': 'Mi devono',
  'debts_tab_approvals': 'Approvazioni',
  'debts_tab_summary': 'Riepilogo',
  'debts_user_info_unavailable':
      'Non è stato possibile recuperare le informazioni dell’utente.',
  'debts_not_in_any_group': 'Non fai ancora parte di nessun gruppo.',
  'debts_owed_by_prefix': 'Dovuto a',
  'debts_owed_to_me_prefix': 'Ci deve',
  'debts_no_active_debt': 'Non hai debiti attivi.',
  'debts_no_active_credit': 'Al momento nessuno ti deve nulla.',
  'debts_total_debt_label': 'Debito totale',
  'debts_total_credit_label': 'Credito totale',
  'debts_awaiting_my_approval': 'In attesa della tua approvazione',
  'debts_no_awaiting_my_approval':
      'Nessun debito in attesa della tua approvazione.',
  'debts_awaiting_other_approval':
      'In attesa dell’approvazione dell’altra parte',
  'debts_no_awaiting_other_approval':
      'Nessun debito in attesa dell’approvazione dell’altra parte.',
  'debts_reject_tooltip': 'Rifiuta',
  'debts_no_settlement': 'Nessun debito da saldare.',
  'debts_settled_debt_subtitle': 'Debito saldato',
  'debts_total_prefix': 'Totale',
  'debts_filter_group_label': 'Gruppo',
  'debts_clear_filters_tooltip': 'Cancella i filtri',
  // --- Notifications ---
  'notifications_login_required': 'Accedi per vedere le tue notifiche.',
  'notifications_empty_title': 'Non hai ancora notifiche.',
  'notifications_empty_subtitle':
      'Qui compariranno gli aggiornamenti su spese e approvazioni dei tuoi gruppi.',
  // --- Notifications: dynamically built messages ---
  'notif_new_expense_title': 'Nuova spesa',
  'notif_new_expense_message':
      '{sender} ti ha aggiunto alla spesa "{desc}" nel gruppo {group}. Importo: {amount}. In attesa della tua approvazione.',
  'notif_payment_confirmation_title': 'Pagamento segnalato',
  'notif_payment_confirmation_message':
      '{sender} ha segnalato un pagamento per "{desc}" nel gruppo {group}.',
  'notif_debt_approved_title': 'Debito approvato',
  'notif_debt_approved_message':
      '{sender} ha approvato il debito per "{desc}" nel gruppo {group}.',
  'notif_debt_rejected_title': 'Debito rifiutato',
  'notif_debt_rejected_message':
      '{sender} ha rifiutato il debito per "{desc}" nel gruppo {group}.',
  'notif_debt_settled_title': 'Pagamento confermato',
  'notif_debt_settled_message':
      '{sender} ha confermato il tuo pagamento per "{desc}" nel gruppo {group}. Il debito è saldato.',
  'notif_default_group': 'Un gruppo',
  'notif_default_user': 'Un utente',
  'notif_default_expense_desc': 'spesa',
  // --- Profile ---
  'profile_title': 'Profilo',
  'profile_email_missing': 'Email non inserita',
  'profile_user_fallback': 'Utente Splixa',
  'profile_manage_subscription': 'Gestisci l’abbonamento',
  'profile_upgrade_pro': 'Passa a Pro',
  'profile_settings': 'Impostazioni',
  'profile_invite_friends': 'Invita amici',
  'profile_download_monthly_report': 'Scarica il report mensile',
  'profile_download_monthly_report_pro': 'Scarica il report mensile · Pro',
  'profile_contact_us': 'Contattaci',
  'profile_support_placeholder':
      'Il contatto dell’assistenza sarà disponibile qui.',
  'profile_terms': 'Termini',
  'profile_privacy': 'Privacy',
  'profile_choose_picture': 'Scegli la foto profilo',
  'profile_tap_choose_photo': 'Tocca per scegliere una foto',
  'profile_username_label': 'Nome utente',
  'profile_email_label': 'Email',
  'profile_dark_mode': 'Modalità scura',
  'profile_link_failed': 'Non è stato possibile aprire questa pagina.',
  'profile_delete_dialog_title': 'Eliminare account e dati?',
  'profile_delete_dialog_body':
      'L’operazione è definitiva. Il tuo profilo, i movimenti personali, i messaggi e i collegamenti social verranno eliminati. Lo storico finanziario condiviso viene conservato in forma anonima affinché i saldi degli altri partecipanti restino corretti.',
  'profile_delete_group_warning':
      'Se amministri un gruppo con altri partecipanti, devi prima eliminarlo o trasferirne la proprietà.',
  'profile_delete_type_confirm': 'Scrivi DELETE per confermare:',
  'profile_delete_transfer_first':
      'Elimina o trasferisci prima i gruppi che amministri:',
  'profile_delete_failed': 'Eliminazione dell’account non riuscita. Riprova.',
  'profile_delete_invalid_response':
      'Il servizio di eliminazione ha restituito una risposta non valida.',
  'profile_deleting': 'Eliminazione…',
  'profile_delete_permanently': 'Elimina definitivamente',
  'profile_membership_pro': 'PRO',
  'profile_membership_standard': 'STANDARD',
  'profile_unknown_username': '@sconosciuto',
  'profile_edit_tile': 'Modifica profilo',
  'profile_currency_tile': 'Valuta',
  'profile_change_password_tile': 'Cambia password',
  'profile_download_report_tile': 'Scarica il report mensile (PDF)',
  'profile_pdf_error': 'Non è stato possibile generare il PDF: %s',
  'profile_logout': 'Esci',
  'profile_danger_zone': 'Zona a rischio',
  'profile_delete_account_data': 'Elimina account e dati',
  'profile_delete_account_title': 'Elimina account',
  'profile_delete_account_confirm':
      'Vuoi davvero eliminare definitivamente il tuo account e tutti i suoi dati? L’azione non può essere annullata.',
  'profile_avatar_url_label': 'URL dell’avatar (facoltativo)',
  'profile_update_success': 'Profilo aggiornato correttamente.',
  'profile_bio_label': 'Bio',
  'profile_bio_hint': 'Racconta qualcosa di te...',
  'profile_bio_empty': 'Non hai ancora aggiunto una bio.',
  // --- Profile: PDF export ---
  'pdf_title': 'Report mensile - %s',
  'pdf_total_income': 'Entrate totali',
  'pdf_total_expense': 'Spese totali',
  'pdf_net_balance': 'Saldo netto',
  'pdf_transaction_details': 'Dettaglio dei movimenti',
  'pdf_no_transactions': 'Nessun movimento in questo mese.',
  'pdf_header_type': 'Tipo',
  // --- Social ---
  'social_title': 'Social',
  'social_request_sent_snackbar': 'Richiesta inviata!',
  'social_user_not_found': 'Utente non trovato.',
  'social_search_results_header': 'Risultati della ricerca',
  'social_add_friend_tooltip': 'Aggiungi amico',
  'social_search_hint': 'Cerca utenti per @nomeutente',
  'social_search_tooltip': 'Cerca utenti',
  'social_no_friends_title': 'Non hai ancora amici.',
  'social_no_friends_subtitle':
      'Usa la ricerca qui sopra per trovare un nome utente e inviare una richiesta di amicizia.',
  'social_request_sent_prefix': 'Richiesta inviata: %s',
  'social_pending_status': 'In attesa...',
  'social_incoming_request_prefix': 'Richiesta per te: %s',
  'social_friend_prefix': 'Amico: %s',
  'social_default_chat_title': 'Amico',
  // --- Social: other user profile ---
  'other_profile_title': 'Profilo utente',
  'other_profile_unknown': 'Sconosciuto',
  'other_profile_no_shared_groups': 'Nessun gruppo in comune',
  'other_profile_shared_groups_count': 'Avete %s gruppi in comune',
  'other_profile_send_message': 'Invia messaggio',
  // --- Subscriptions: paywall ---
  'paywall_title': 'Passa a Splixa Pro',
  'paywall_subtitle':
      'Crea gruppi illimitati, accedi a tutte le statistiche e goditi la tua libertà finanziaria!',
  'paywall_no_packages': 'Al momento non ci sono pacchetti disponibili.',
  'paywall_restore_purchases': 'Ripristina gli acquisti',
  'paywall_restore_success': 'Acquisti ripristinati!',
  'paywall_processing_purchase': 'Elaborazione dell’acquisto...',
  'paywall_welcome_pro': 'Benvenuto su Splixa Pro!',
  'paywall_purchase_failed': 'L’operazione è stata annullata o non è riuscita.',
  'paywall_benefit_unlimited_groups': 'Crea gruppi illimitati',
  'paywall_benefit_statistics': 'Accedi a tutte le statistiche e ai report',
  'paywall_benefit_freedom': 'Goditi la tua libertà finanziaria',
  'paywall_no_packages_hint': 'I pacchetti compariranno qui a breve.',
  'paywall_footer_note': 'Puoi annullare l’abbonamento quando vuoi.',
  // --- Friendly error messages ---
  'error_generic_short': 'Qualcosa è andato storto. Riprova.',
  'error_auth_generic': 'Si è verificato un problema. Riprova.',
  'error_google_cancelled':
      'L’accesso con Google è stato annullato o il dispositivo non è stato verificato. Riprova.',
  'error_google_configuration':
      'L’accesso con Google non è configurato correttamente.',
  'error_google_unavailable':
      'L’accesso con Google non è disponibile su questo dispositivo.',
  'error_google_timeout': 'L’accesso con Google è scaduto. Riprova.',
  'error_google_failed':
      'Non è stato possibile completare l’accesso con Google. Riprova.',
  'error_invalid_credentials': 'Nome utente o password non corretti.',
  'error_email_not_confirmed':
      'Il tuo indirizzo email non è ancora stato verificato.',
  'error_email_already_registered': 'Esiste già un account con questa email.',
  'error_password_too_short':
      'La password è troppo corta. Scegline una più lunga.',
  'error_rate_limited': 'Troppi tentativi. Riprova tra poco.',
  'error_duplicate_record': 'Questo record esiste già.',
  'error_forbidden': 'Non hai i permessi per farlo.',
  'error_not_found': 'Record non trovato.',
  'error_server_generic':
      'Si è verificato un problema di comunicazione con il server. Riprova.',
  // --- Main scaffold (bottom nav) ---
  'nav_dashboard': 'Dashboard',
  'nav_debts': 'Debiti',
  'nav_groups': 'Gruppi',
  'nav_social': 'Social',
  'nav_profile': 'Profilo',
  // --- Router fallback titles (used when navigation `extra` is absent) ---
  'route_fallback_group_detail': 'Dettaglio del gruppo',
  'route_fallback_group_info': 'Info del gruppo',
  'route_fallback_group': 'Gruppo',
  'route_fallback_chat': 'Chat',
  // --- Activity feed descriptions ---
  'activity_someone': 'Qualcuno',
  'activity_a_group': 'Un gruppo',
  'activity_became_friends': 'Ora sei amico di {name}.',
  'activity_added_expense': 'Hai aggiunto una spesa di {amount} in {group}.',

  // --- Onboarding ---
  'onboarding_skip': 'Salta',
  'onboarding_continue': 'Continua',
  'onboarding_start_free': 'Inizia gratis',
  'onboarding_no_card':
      'Nessuna carta richiesta. Passa a Pro solo quando ti fa risparmiare tempo.',
  'onboarding_persistence_error':
      'Non siamo riusciti a salvare la tua scelta. Riprova.',
  'onboarding_p1_eyebrow': 'PERSONALE + CONDIVISO',
  'onboarding_p1_title': 'Tieni il tuo conto. Dividi insieme.',
  'onboarding_p1_description':
      'Il tuo budget e tutte le spese condivise, in un solo posto.',
  'onboarding_p1_proof_1': 'Budget personale',
  'onboarding_p1_proof_2': 'Spese di gruppo',
  'onboarding_p2_eyebrow': 'NIENTE CONTI IMBARAZZANTI',
  'onboarding_p2_title': 'Dividi con equità. Salda con chiarezza.',
  'onboarding_p2_description':
      'Quote uguali, percentuali o esatte: tutti sanno cosa viene dopo.',
  'onboarding_p2_proof_1': 'Divisioni flessibili',
  'onboarding_p2_proof_2': 'Approvazioni chiare',
  'onboarding_p3_eyebrow': 'CONTI CHE TORNANO',
  'onboarding_p3_title': 'Viaggia libero. Conserva ogni tasso.',
  'onboarding_p3_description':
      'Importi originali e tassi bloccati mantengono corretto il saldo di ieri.',
  'onboarding_p3_proof_1': 'Tassi bloccati',
  'onboarding_p3_proof_2': 'Storico affidabile',
  'onboarding_p4_eyebrow': 'INIZIARE È GRATIS',
  'onboarding_p4_title': 'Inizia gratis. Passa a Pro quando conviene.',
  'onboarding_p4_description':
      'Sblocca inserimento rapido, analisi profonde e report avanzati quando servono.',
  'onboarding_p4_proof_1': 'Nessuna prova obbligatoria',
  'onboarding_p4_proof_2': 'Disdici quando vuoi',

  // --- Subscriptions: paywall copy ---
  'paywall_appbar_title': 'Splixa Pro',
  'paywall_close': 'Chiudi',
  'paywall_hero_title':
      'Trasforma la gestione dei soldi in un’attività da due minuti',
  'paywall_hero_subtitle':
      'Il cuore di Splixa resta gratuito. Passa a Pro quando automazione, controllo e risposte più profonde valgono più del tempo che fanno risparmiare.',
  'paywall_benefits_title': 'Cosa sblocca Pro',
  'paywall_benefit_1_title': 'Gruppi illimitati',
  'paywall_benefit_1_body':
      'Tieni attivi ogni viaggio, casa e progetto senza limiti di gruppo.',
  'paywall_benefit_2_title': 'Scopri gli schemi dietro le tue spese',
  'paywall_benefit_2_body':
      'Esplora a colpo d’occhio la distribuzione per categoria e le tue abitudini.',
  'paywall_benefit_3_title': 'Esporta report mensili curati',
  'paywall_benefit_3_body':
      'Trasforma i tuoi dati personali in un PDF condivisibile con un tocco.',
  'paywall_benefit_4_title':
      'Anteprima della roadmap: meno digitazione, più controllo',
  'paywall_benefit_4_body':
      'La scansione degli scontrini e i tassi di cambio personalizzati arriveranno a breve.',
  'paywall_choose_plan': 'Scegli il tuo piano',
  'paywall_best_value': 'PIÙ CONVENIENTE',
  'paywall_continue_free': 'Non ora — continua con la versione gratuita',
  'paywall_restore': 'Ripristina gli acquisti',
  'paywall_restore_restored': 'Il tuo accesso Pro è stato ripristinato.',
  'paywall_restore_none':
      'Nessun acquisto Pro attivo trovato per questo account dello store.',
  'paywall_welcome_message': 'Ti diamo il benvenuto su Splixa Pro.',
  'paywall_purchase_failed_message':
      'L’acquisto è stato annullato o non è andato a buon fine.',
  'paywall_no_packages_available':
      'I piani non sono temporaneamente disponibili. Riprova.',
  'paywall_retry': 'Riprova',
  'paywall_terms_link': 'Condizioni d’uso',
  'paywall_privacy_link': 'Informativa sulla privacy',
  'paywall_store_disclosure':
      'Il pagamento viene addebitato sul tuo account dello store. Gestisci o annulla l’abbonamento dalle impostazioni di App Store o Google Play.',
  'paywall_link_failed': 'Non è stato possibile aprire la pagina.',
  'paywall_plan_annual': 'Pro annuale',
  'paywall_plan_monthly': 'Pro mensile',
  'paywall_period_annual': '/ anno',
  'paywall_period_monthly': '/ mese',
  'paywall_monthly_equivalent': 'equivalente a {price} al mese',
  'paywall_continue_with_plan': 'Continua con {plan}',
  'paywall_renewal_annual':
      'Ora vengono addebitati {price}. L’abbonamento si rinnova ogni anno fino alla disdetta.',
  'paywall_renewal_monthly':
      'Ora vengono addebitati {price}. L’abbonamento si rinnova ogni mese fino alla disdetta.',

  // --- Relative time (activity feed, chat, notifications) ---
  'time_just_now': 'Adesso',
  'time_minutes_ago': '{count} min fa',
  'time_hours_ago': '{count} h fa',
  'time_days_ago': '{count} g fa',

  // --- Profile sections & language picker ---
  'profile_section_account': 'Account',
  'profile_section_subscription': 'Abbonamento',
  'profile_section_preferences': 'Preferenze',
  'profile_section_support': 'Assistenza',
  'profile_section_legal': 'Note legali',
  'language_picker_title': 'Scegli la tua lingua',
  'error_free_group_limit':
      'Il piano gratuito include fino a 2 gruppi. Passa a Pro per gruppi illimitati.',
  'error_free_personal_expense_limit':
      'Hai raggiunto 50 spese personali questo mese. Passa a Pro per continuare.',
  'error_not_authenticated': 'Accedi di nuovo per continuare.',
  'pro_tools_title': 'Strumenti Pro',
  'pro_tools_locked': 'Sblocca tutti gli strumenti avanzati con Splixa Pro.',
  'pro_server_verified': 'Accesso Pro verificato in modo sicuro',
  'pro_sync_pending': 'Sincronizzazione accesso Pro',
  'pro_biometric_lock': 'Blocco biometrico',
  'pro_biometric_lock_body':
      'Richiedi Face ID, impronta o sicurezza dispositivo al ritorno in Splixa.',
  'pro_biometric_unavailable': 'Autenticazione biometrica non disponibile.',
  'pro_app_lock_reason': 'Autenticati per aprire le tue finanze Splixa',
  'pro_app_locked_title': 'Splixa è bloccata',
  'pro_app_locked_body': 'Autenticati per proteggere i tuoi dati finanziari.',
  'pro_unlock': 'Sblocca',
  'pro_home_widget': 'Widget Aggiunta rapida',
  'pro_home_widget_body':
      'Registra una spesa direttamente dalla schermata Home.',
  'pro_home_widget_manual':
      'Aggiungi il widget Splixa dalla galleria dei widget.',
  'pro_custom_categories': 'Categorie personalizzate',
  'pro_category_add': 'Aggiungi categoria',
  'pro_category_name': 'Nome categoria',
  'pro_category_emoji': 'Emoji',
  'pro_categories_empty': 'Crea categorie riutilizzabili con emoji e colore.',
  'pro_recurring_expenses': 'Spese ricorrenti',
  'pro_recurring_add': 'Aggiungi spesa ricorrente',
  'pro_recurring_name': 'Nome spesa',
  'pro_recurring_empty':
      'Automatizza affitto, abbonamenti e altri costi periodici.',
  'pro_frequency_weekly': 'Settimanale',
  'pro_frequency_monthly': 'Mensile',
  'pro_export_csv': 'Esporta CSV completo',
  'pro_advanced_analytics': 'Analisi avanzate e intervalli di date',
  'pro_custom_rate_title': 'Blocca un cambio personalizzato',
  'pro_custom_rate_label': 'TRY per 1 {currency}',
  'pro_custom_rate_helper':
      'Questo cambio viene salvato con la spesa e non cambia nello storico.',
  'pro_custom_rate_try_identity': 'TRY usa già un cambio fisso 1:1.',
  'pro_receipt_camera': 'Scansiona con fotocamera',
  'pro_receipt_gallery': 'Scegli dalla galleria',
  'pro_receipt_ready': 'Ricevuta pronta · controlla i campi',
  'pro_receipt_view': 'Vedi ricevuta',
  'pro_receipt_review_required':
      'I suggerimenti OCR sono stati inseriti. Controllali prima di salvare.',
  'pro_receipt_upload_failed':
      'La spesa è salvata, ma la ricevuta non è stata allegata.',
  'pro_receipt_invalid_image': 'Impossibile leggere questa immagine.',
  'pro_ocr_mobile_only':
      'La scansione ricevute è disponibile su Android e iOS.',
  'pro_send_reminder': 'Ricorda',
  'pro_reminder_sent': 'È stato inviato un promemoria gentile.',
  'pro_trip_summary': 'Riepilogo viaggio condivisibile',
  'pro_trip_privacy_note':
      'L’immagine contiene solo totali, non saldi privati.',
  'pro_trip_share': 'Condividi riepilogo',
  'statistics_current_month': 'Mese corrente',
  'paywall_free_trial': '7 GIORNI GRATIS',
  'paywall_plan_lifetime': 'Pro a vita',
  'paywall_period_once': 'una tantum',
  'paywall_lifetime_disclosure':
      '{price} viene addebitato una sola volta. Non è un abbonamento e non si rinnova.',
};
