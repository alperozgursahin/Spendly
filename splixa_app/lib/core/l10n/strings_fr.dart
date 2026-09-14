// GENERATED-STYLE LOCALE CATALOG — edit by hand, keep keys in sync.
//
// Key order mirrors lib/core/l10n/strings_en.dart, the source locale.
// Every key present in `enStrings` must exist here; `localization_catalog_test`
// fails the build otherwise. Placeholders such as {name} must be preserved
// verbatim — only the surrounding words are translated.

// Launch locale — machine-assisted translation, pending native review.
const Map<String, String> frStrings = {
  // --- Common / shared ---
  'language_selector_label': 'Langue de l’application',
  'common_all': 'Tout',
  'common_reset': 'Réinitialiser',
  'common_filter': 'Filtrer',
  'common_save': 'Enregistrer',
  'common_cancel': 'Annuler',
  'common_delete': 'Supprimer',
  'common_edit': 'Modifier',
  'common_add': 'Ajouter',
  'common_close': 'Fermer',
  'common_send': 'Envoyer',
  'common_you': 'Toi',
  'common_user': 'Utilisateur',
  'common_loading': 'Chargement...',
  'common_retry': 'Réessayer',
  'common_error_generic': 'Une erreur est survenue. Réessaie.',
  'common_date': 'Date',
  'common_category': 'Catégorie',
  'common_expense': 'Dépense',
  'common_income': 'Revenu',
  'common_currency': 'Devise',
  'exchange_rate_unavailable':
      'Impossible de charger le taux de change le plus récent. Vérifie ta connexion et réessaie.',
  // --- Category names (shared across dashboard, statistics, add-expense) ---
  'category_market': 'Courses',
  'category_food': 'Repas',
  'category_transport': 'Transport',
  'category_entertainment': 'Loisirs',
  'category_salary': 'Salaire',
  'category_dues': 'Cotisations',
  'category_bill': 'Facture',
  'category_other': 'Autre',
  // --- Month abbreviations ---
  'month_jan': 'janv.',
  'month_feb': 'févr.',
  'month_mar': 'mars',
  'month_apr': 'avr.',
  'month_may': 'mai',
  'month_jun': 'juin',
  'month_jul': 'juil.',
  'month_aug': 'août',
  'month_sep': 'sept.',
  'month_oct': 'oct.',
  'month_nov': 'nov.',
  'month_dec': 'déc.',
  // --- Dashboard ---
  'dashboard_title': 'Tableau de bord',
  'dashboard_statistics': 'Statistiques',
  'dashboard_notifications': 'Notifications',
  'dashboard_activity_feed': 'Activité',
  'dashboard_recent_transactions': 'Opérations récentes',
  'dashboard_no_activity': 'Pas encore d’activité.',
  'dashboard_no_transactions':
      'Aucune opération récente. Appuie sur + pour ajouter la première !',
  'dashboard_net_balance': 'Solde net',
  'dashboard_amount_hint': 'Montant',
  'dashboard_custom_category_hint': 'Saisis une catégorie personnalisée...',
  'dashboard_pick_date': 'Choisir une date',
  'dashboard_transaction_added': 'Opération ajoutée !',
  'home_welcome': 'Bienvenue, {name}',
  'home_default_name': 'toi',
  'home_subtitle': 'Mettons de l’ordre dans tes finances aujourd’hui.',
  'home_new_group': 'Nouveau',
  'home_group_name_hint': 'ex. : Voyage d’été',
  'home_groups_empty':
      'Aucun groupe pour l’instant. Appuie sur + Nouveau pour commencer à partager !',
  'home_members_loading': 'Chargement des membres…',
  'home_members_count': '{count} membres',
  'home_quick_add': 'Ajouter une opération',
  'home_switch_to_light': 'Passer au thème clair',
  'home_switch_to_dark': 'Passer au thème sombre',
  'home_switch_language': 'Changer de langue',
  'home_minimize_title': 'Minimiser les transactions',
  'home_minimize_description':
      'Splixa simplifie les soldes du groupe pour que chacun règle ses comptes avec le moins de paiements possible.',
  'minimize_without_title': 'Sans minimiser les transactions',
  'minimize_without_description':
      'Deux paiements distincts sont nécessaires. La personne B reçoit de l’argent uniquement pour transmettre le même montant à la personne C.',
  'minimize_with_title': 'Avec des transactions minimisées',
  'minimize_with_description':
      'Splixa supprime l’intermédiaire. La personne A paie directement la personne C et règle les mêmes soldes en un seul paiement.',
  'minimize_person_a': 'Personne A',
  'minimize_person_b': 'Personne B',
  'minimize_person_c': 'Personne C',
  'minimize_pays_100': 'Paie 100',
  'minimize_one_fewer': '1 transaction de moins',
  // --- Statistics ---
  'statistics_title': 'Statistiques',
  'statistics_category_distribution': 'Répartition par catégorie (ce mois-ci)',
  'statistics_no_expenses_this_month': 'Tu n’as aucune dépense ce mois-ci.',
  'statistics_heatmap_title': 'Carte d’activité',
  'statistics_monthly_trend': 'Dépenses mensuelles',
  'statistics_total': 'Total',
  'statistics_daily_average': 'Moyenne par jour',
  'statistics_largest': 'Plus grosse dépense',
  'statistics_heatmap_activity_count': 'activités',
  // --- Auth: login ---
  'login_title': 'Connexion à Splixa',
  'login_username_required': 'Saisis ton nom d’utilisateur.',
  'login_password_required': 'Saisis ton mot de passe.',
  'login_username_label': 'Nom d’utilisateur (@pseudo)',
  'login_password_label': 'Mot de passe',
  'login_forgot_password': 'Mot de passe oublié ?',
  'login_submit': 'Se connecter',
  'login_or': 'ou',
  'login_google_continue': 'Continuer avec Google',
  'login_no_account': 'Pas encore de compte ? Inscris-toi',
  'login_welcome': 'Bienvenue sur Splixa',
  'login_identifier_subtitle':
      'Connecte-toi avec ton e-mail ou ton nom d’utilisateur et ton mot de passe.',
  'login_identifier_label': 'E-mail ou nom d’utilisateur',
  'login_identifier_hint': 'toi@exemple.com ou @pseudo',
  'login_identifier_required': 'Saisis ton e-mail ou ton nom d’utilisateur.',
  // --- Auth: register ---
  'register_title': 'Inscription à Splixa',
  'register_username_too_short':
      'Le nom d’utilisateur doit contenir au moins 3 caractères.',
  'register_email_invalid': 'Saisis une adresse e-mail valide.',
  'register_password_too_short':
      'Le mot de passe doit contenir au moins 6 caractères.',
  'register_success': 'Inscription réussie ! Tu peux te connecter.',
  'register_email_label': 'E-mail',
  'register_submit': 'S’inscrire',
  'register_have_account': 'Déjà un compte ? Connecte-toi',
  // --- Auth: Google profile completion ---
  'profile_setup_title': 'Comment devons-nous t’appeler ?',
  'profile_setup_subtitle':
      'Choisis un nom d’utilisateur unique pour que tes amis te trouvent sur Splixa.',
  'profile_setup_username_label': 'Nom d’utilisateur',
  'profile_setup_username_hint': 'ton_pseudo',
  'profile_setup_username_helper':
      '3 à 30 caractères ; lettres, chiffres et tiret bas uniquement.',
  'profile_setup_continue': 'Continuer vers Splixa',
  'profile_setup_use_other_account': 'Utiliser un autre compte',
  'profile_setup_username_taken':
      'Ce nom d’utilisateur est déjà pris. Essaie-en un autre.',
  'profile_setup_session_expired': 'Ta session a expiré. Reconnecte-toi.',
  'profile_setup_timeout': 'La demande a expiré. Réessaie.',
  'profile_setup_failed':
      'Ton nom d’utilisateur n’a pas pu être enregistré. Réessaie.',
  // --- Auth: forgot / update password ---
  'forgot_password_title': 'Mot de passe oublié',
  'forgot_password_email_invalid': 'Saisis une adresse e-mail valide.',
  'forgot_password_sent_message':
      'Un code de récupération à 8 chiffres a été envoyé à ton adresse e-mail.',
  'forgot_password_back_to_login': 'Retour à la connexion',
  'forgot_password_prompt':
      'Saisis l’adresse e-mail de ton compte et nous t’enverrons un code de récupération à 8 chiffres.',
  'forgot_password_email_label': 'E-mail',
  'forgot_password_send_link': 'Envoyer le code de récupération',
  'forgot_password_send_code': 'Envoyer le code de récupération',
  'login_verification_title': 'Validation en deux étapes',
  'login_verification_prompt':
      'Saisis le code de vérification à 8 chiffres envoyé à {email}.',
  'login_verification_submit': 'Vérifier et se connecter',
  'auth_code_label': 'Code à 8 chiffres',
  'auth_code_eight_digits_required': 'Le code doit comporter 8 chiffres.',
  'auth_code_resend': 'Renvoyer le code',
  'auth_code_resending': 'Envoi...',
  'auth_code_resent':
      'Un nouveau code de vérification a été envoyé à ton adresse e-mail.',
  'auth_code_invalid_or_expired': 'Le code est invalide ou a expiré.',
  'reset_password_code_title': 'Réinitialiser le mot de passe',
  'reset_password_code_prompt':
      'Saisis le code de récupération envoyé à {email} et ton nouveau mot de passe.',
  'reset_password_code_submit': 'Vérifier le code et changer le mot de passe',
  'update_password_title': 'Définir un nouveau mot de passe',
  'update_password_too_short':
      'Le mot de passe doit contenir au moins 6 caractères.',
  'update_password_success': 'Ton mot de passe a bien été mis à jour !',
  'update_password_prompt': 'Définis un nouveau mot de passe pour ton compte.',
  'update_password_new_label': 'Nouveau mot de passe',
  'update_password_submit': 'Mettre à jour le mot de passe',
  // --- Groups: list ---
  'groups_title': 'Groupes',
  'groups_empty_title': 'Tu ne fais encore partie d’aucun groupe.',
  'groups_empty_subtitle':
      'Appuie sur le bouton + en bas à droite pour créer ton premier groupe.',
  'groups_tap_for_details': 'Appuie pour voir les détails du groupe',
  'groups_create_new_group': 'Créer un groupe',
  'groups_name_label': 'Nom du groupe',
  'groups_create_button': 'Créer',
  // --- Groups: detail screen ---
  'groups_participants_suffix': 'participants',
  'groups_participants_load_error': 'Impossible de charger les participants',
  'groups_chat_tooltip': 'Discussion du groupe',
  'groups_invite_friend_tooltip': 'Inviter un ami',
  'groups_paid_verb': 'a payé',
  'groups_tab_pending': 'En attente',
  'groups_tab_active': 'Actives',
  'groups_tab_archived': 'Archives',
  'groups_no_transactions':
      'Aucune opération pour l’instant. Ajoute la première dépense.',
  'groups_empty_pending': 'Aucune dépense en attente d’approbation.',
  'groups_empty_active': 'Aucune dépense active.',
  'groups_empty_archived': 'Aucune dépense archivée.',
  'groups_add_expense': 'Ajouter une dépense',
  'groups_archive_all_button': 'Tout archiver',
  'groups_action_failed': 'L’action n’a pas pu aboutir. Réessaie.',
  'groups_archive_failed': 'La dépense n’a pas pu être archivée. Réessaie.',
  'groups_status_payer': 'Payeur',
  'groups_status_pending': 'En attente d’approbation',
  'groups_status_approved_self': 'Approuvée',
  'groups_status_active_debt': 'Dette active',
  'groups_status_payment_pending_payer':
      'En attente de confirmation du paiement',
  'groups_status_payment_reported': 'Paiement signalé',
  'groups_status_settled': 'Payée',
  'groups_status_rejected': 'Refusée',
  'groups_action_approve': 'Approuver',
  'groups_action_mark_paid': 'Marquer comme payé',
  'groups_action_confirm_payment': 'Confirmer le paiement',
  'groups_balance_title': 'Solde du groupe',
  'groups_no_active_debt': 'Aucune dette active.',
  'groups_creditor_label': 'À recevoir',
  'groups_debtor_label': 'Doit',
  'groups_filter_payer_label': 'Payé par',
  // --- Groups: info screen ---
  'group_info_change_picture': 'Changer la photo du groupe',
  'group_info_group_picture': 'Photo du groupe',
  'group_info_admin': 'Administrateur',
  'group_info_remove_member': 'Retirer le membre',
  'group_info_this_member': 'ce membre',
  'group_info_remove_member_title': 'Retirer ce membre ?',
  'group_info_remove_member_body':
      '{member} perdra l’accès à ce groupe et à sa discussion.',
  'group_info_remove': 'Retirer',
  'group_info_title': 'Infos du groupe',
  'group_info_leave_button': 'Quitter le groupe',
  'group_info_delete_button': 'Supprimer le groupe',
  'group_info_leave_confirm':
      'Veux-tu vraiment quitter "%s" ? Tes dépenses passées resteront dans le groupe.',
  'group_info_leave_confirm_button': 'Quitter',
  'group_info_delete_confirm':
      'Veux-tu vraiment supprimer définitivement "%s" ainsi que toutes ses dépenses et ses données de membres ? Cette action est irréversible.',
  // --- Groups: chat ---
  'groups_chat_title': 'Discussion de {group}',
  'groups_chat_suffix': 'Discussion',
  'groups_chat_empty': 'Aucun message pour l’instant. Écris le premier !',
  'groups_chat_input_hint': 'Écris un message...',
  // --- Groups: add expense sheet ---
  'groups_scan_receipt': 'Scanner un reçu',
  'groups_custom_exchange_rate': 'Taux de change personnalisé',
  'groups_custom_rate_base_currency':
      'La devise choisie est déjà la devise de base.',
  'groups_custom_rate_label': '1 {code} = ? TRY',
  'groups_custom_rate_live': 'Taux actuel : {rate}',
  'groups_pro_tool_coming_soon': 'Cet outil Pro arrive bientôt.',
  'dashboard_custom_rate_coming_soon':
      'L’éditeur de taux personnalisé arrive bientôt.',
  'groups_expense_desc_label': 'Pour quoi ?',
  'groups_expense_category_label': 'Catégorie',
  'groups_total_amount_label': 'Montant total',
  'groups_split_equal': 'Égal (=)',
  'groups_split_percentage': 'Pourcentage (%)',
  'groups_split_exact': 'Montant',
  'groups_split_for_whom': 'Pour qui est cette dépense ?',
  'groups_auto_badge': 'auto',
  'groups_expense_validation_generic':
      'Saisis des informations valides et sélectionne au moins 1 personne.',
  'groups_percentage_validation':
      'Au maximum 1 personne peut rester sans pourcentage, et le total doit faire 100.',
  'groups_percentage_total_validation':
      'Le total des pourcentages doit faire 100.',
  'groups_exact_validation':
      'Au maximum 1 personne peut rester sans montant, et le total doit correspondre au montant de la dépense.',
  // --- Groups: invite friend modal ---
  'groups_invited_snackbar': 'Invitation envoyée !',
  'groups_already_member': 'Déjà dans le groupe',
  'groups_invite_modal_title': 'Inviter un ami dans le groupe',
  'groups_invite_search_hint': 'Cherche parmi tes amis',
  'groups_no_friends_to_invite': 'Tu n’as personne à inviter.',
  'groups_no_friends_hint': 'Ajoute d’abord des amis depuis l’onglet Social.',
  'groups_no_search_match': 'Aucun ami ne correspond à ta recherche.',
  // --- Debts ---
  'debts_back_tooltip': 'Retour',
  'debts_title': 'Dettes',
  'debts_tab_mine': 'Mes dettes',
  'debts_tab_owed_to_me': 'On me doit',
  'debts_tab_approvals': 'Approbations',
  'debts_tab_summary': 'Résumé',
  'debts_user_info_unavailable':
      'Impossible de récupérer les informations de l’utilisateur.',
  'debts_not_in_any_group': 'Tu ne fais encore partie d’aucun groupe.',
  'debts_owed_by_prefix': 'Dû à',
  'debts_owed_to_me_prefix': 'Nous doit',
  'debts_no_active_debt': 'Tu n’as aucune dette active.',
  'debts_no_active_credit':
      'Personne ne te doit quoi que ce soit pour l’instant.',
  'debts_total_debt_label': 'Dette totale',
  'debts_total_credit_label': 'Crédit total',
  'debts_awaiting_my_approval': 'En attente de ton approbation',
  'debts_no_awaiting_my_approval': 'Aucune dette n’attend ton approbation.',
  'debts_awaiting_other_approval':
      'En attente de l’approbation de l’autre partie',
  'debts_no_awaiting_other_approval':
      'Aucune dette n’attend l’approbation de l’autre partie.',
  'debts_reject_tooltip': 'Refuser',
  'debts_no_settlement': 'Aucune dette à régler.',
  'debts_settled_debt_subtitle': 'Dette réglée',
  'debts_total_prefix': 'Total',
  'debts_filter_group_label': 'Groupe',
  'debts_clear_filters_tooltip': 'Effacer les filtres',
  // --- Notifications ---
  'notifications_login_required': 'Connecte-toi pour voir tes notifications.',
  'notifications_empty_title': 'Tu n’as encore aucune notification.',
  'notifications_empty_subtitle':
      'Les nouveautés sur les dépenses et les approbations de tes groupes apparaîtront ici.',
  // --- Notifications: dynamically built messages ---
  'notif_new_expense_title': 'Nouvelle dépense',
  'notif_new_expense_message':
      '{sender} t’a ajouté à la dépense "{desc}" du groupe {group}. Montant : {amount}. En attente de ton approbation.',
  'notif_payment_confirmation_title': 'Paiement signalé',
  'notif_payment_confirmation_message':
      '{sender} a signalé un paiement pour "{desc}" dans le groupe {group}.',
  'notif_debt_approved_title': 'Dette approuvée',
  'notif_debt_approved_message':
      '{sender} a approuvé la dette pour "{desc}" dans le groupe {group}.',
  'notif_debt_rejected_title': 'Dette refusée',
  'notif_debt_rejected_message':
      '{sender} a refusé la dette pour "{desc}" dans le groupe {group}.',
  'notif_debt_settled_title': 'Paiement confirmé',
  'notif_debt_settled_message':
      '{sender} a confirmé ton paiement pour "{desc}" dans le groupe {group}. La dette est réglée.',
  'notif_default_group': 'Un groupe',
  'notif_default_user': 'Un utilisateur',
  'notif_default_expense_desc': 'dépense',
  // --- Profile ---
  'profile_title': 'Profil',
  'profile_email_missing': 'Aucun e-mail ajouté',
  'profile_user_fallback': 'Utilisateur Splixa',
  'profile_manage_subscription': 'Gérer l’abonnement',
  'profile_upgrade_pro': 'Passer à Pro',
  'profile_settings': 'Paramètres',
  'profile_invite_friends': 'Inviter des amis',
  'profile_download_monthly_report': 'Télécharger le rapport mensuel',
  'profile_download_monthly_report_pro': 'Télécharger le rapport mensuel · Pro',
  'profile_contact_us': 'Nous contacter',
  'profile_support_placeholder': 'Le contact du support sera disponible ici.',
  'profile_terms': 'Conditions',
  'profile_privacy': 'Confidentialité',
  'profile_choose_picture': 'Choisir une photo de profil',
  'profile_tap_choose_photo': 'Appuie pour choisir une photo',
  'profile_username_label': 'Nom d’utilisateur',
  'profile_email_label': 'E-mail',
  'profile_dark_mode': 'Mode sombre',
  'profile_link_failed': 'Impossible d’ouvrir cette page.',
  'profile_delete_dialog_title': 'Supprimer le compte et les données ?',
  'profile_delete_dialog_body':
      'C’est définitif. Ton profil, tes opérations personnelles, tes messages et tes relations sociales seront supprimés. L’historique financier partagé est conservé de façon anonyme afin que les soldes des autres membres restent corrects.',
  'profile_delete_group_warning':
      'Si tu administres un groupe comptant d’autres membres, tu dois d’abord le supprimer ou en transférer la propriété.',
  'profile_delete_type_confirm': 'Saisis DELETE pour confirmer :',
  'profile_delete_transfer_first':
      'Supprime ou transfère d’abord les groupes que tu administres :',
  'profile_delete_failed': 'La suppression du compte a échoué. Réessaie.',
  'profile_delete_invalid_response':
      'Le service de suppression a renvoyé une réponse invalide.',
  'profile_deleting': 'Suppression…',
  'profile_delete_permanently': 'Supprimer définitivement',
  'profile_membership_pro': 'PRO',
  'profile_membership_standard': 'STANDARD',
  'profile_unknown_username': '@inconnu',
  'profile_edit_tile': 'Modifier le profil',
  'profile_currency_tile': 'Devise',
  'profile_change_password_tile': 'Changer le mot de passe',
  'profile_download_report_tile': 'Télécharger le rapport mensuel (PDF)',
  'profile_pdf_error': 'Impossible de générer le PDF : %s',
  'profile_logout': 'Se déconnecter',
  'profile_danger_zone': 'Zone sensible',
  'profile_delete_account_data': 'Supprimer le compte et les données',
  'profile_delete_account_title': 'Supprimer le compte',
  'profile_delete_account_confirm':
      'Veux-tu vraiment supprimer définitivement ton compte et toutes ses données ? Cette action est irréversible.',
  'profile_avatar_url_label': 'URL de l’avatar (facultatif)',
  'profile_update_success': 'Profil mis à jour.',
  'profile_bio_label': 'Bio',
  'profile_bio_hint': 'Parle un peu de toi...',
  'profile_bio_empty': 'Aucune bio ajoutée pour l’instant.',
  // --- Profile: PDF export ---
  'pdf_title': 'Rapport mensuel - %s',
  'pdf_total_income': 'Total des revenus',
  'pdf_total_expense': 'Total des dépenses',
  'pdf_net_balance': 'Solde net',
  'pdf_transaction_details': 'Détail des opérations',
  'pdf_no_transactions': 'Aucune opération ce mois-ci.',
  'pdf_header_type': 'Type',
  // --- Social ---
  'social_title': 'Social',
  'social_request_sent_snackbar': 'Demande envoyée !',
  'social_user_not_found': 'Utilisateur introuvable.',
  'social_search_results_header': 'Résultats de recherche',
  'social_add_friend_tooltip': 'Ajouter en ami',
  'social_search_hint': 'Cherche des utilisateurs par @pseudo',
  'social_search_tooltip': 'Rechercher des utilisateurs',
  'social_no_friends_title': 'Tu n’as encore aucun ami.',
  'social_no_friends_subtitle':
      'Utilise la recherche ci-dessus pour trouver un nom d’utilisateur et envoyer une demande d’ami.',
  'social_request_sent_prefix': 'Demande envoyée : %s',
  'social_pending_status': 'En attente...',
  'social_incoming_request_prefix': 'Demande reçue : %s',
  'social_friend_prefix': 'Ami : %s',
  'social_default_chat_title': 'Ami',
  // --- Social: other user profile ---
  'other_profile_title': 'Profil de l’utilisateur',
  'other_profile_unknown': 'Inconnu',
  'other_profile_no_shared_groups': 'Aucun groupe en commun',
  'other_profile_member_new': 'Inscrit ce mois-ci',
  'other_profile_member_months': '{months} mois sur Splixa',
  'other_profile_member_years': '{years} ans sur Splixa',
  'other_profile_shared_groups_title': 'Groupes en commun',
  'other_profile_shared_groups_count': 'Vous avez %s groupes en commun',
  'other_profile_send_message': 'Envoyer un message',
  // --- Subscriptions: paywall ---
  'paywall_title': 'Passe à Splixa Pro',
  'paywall_subtitle':
      'Crée des groupes illimités, accède à toutes les statistiques et profite de ta liberté financière !',
  'paywall_no_packages': 'Aucune formule disponible pour le moment.',
  'paywall_restore_purchases': 'Restaurer les achats',
  'paywall_restore_success': 'Achats restaurés !',
  'paywall_processing_purchase': 'Traitement de l’achat...',
  'paywall_welcome_pro': 'Bienvenue sur Splixa Pro !',
  'paywall_purchase_failed': 'L’opération a été annulée ou a échoué.',
  'paywall_benefit_unlimited_groups': 'Crée des groupes illimités',
  'paywall_benefit_statistics':
      'Accède à toutes les statistiques et à tous les rapports',
  'paywall_benefit_freedom': 'Profite de ta liberté financière',
  'paywall_no_packages_hint': 'Les formules apparaîtront ici bientôt.',
  'paywall_footer_note': 'Tu peux résilier ton abonnement à tout moment.',
  // --- Friendly error messages ---
  'error_generic_short': 'Une erreur est survenue. Réessaie.',
  'error_auth_generic': 'Un problème est survenu. Réessaie.',
  'error_google_cancelled':
      'La connexion Google a été annulée ou l’appareil n’a pas pu être vérifié. Réessaie.',
  'error_google_configuration':
      'La connexion Google n’est pas configurée correctement.',
  'error_google_unavailable':
      'La connexion Google n’est pas disponible sur cet appareil.',
  'error_google_timeout': 'La connexion Google a expiré. Réessaie.',
  'error_google_failed': 'La connexion Google n’a pas pu aboutir. Réessaie.',
  'error_invalid_credentials': 'Nom d’utilisateur ou mot de passe incorrect.',
  'error_email_not_confirmed':
      'Ton adresse e-mail n’a pas encore été vérifiée.',
  'error_email_already_registered':
      'Un compte existe déjà avec cette adresse e-mail.',
  'error_password_too_short':
      'Le mot de passe est trop court. Choisis-en un plus long.',
  'error_rate_limited': 'Trop de tentatives. Réessaie dans un instant.',
  'error_duplicate_record': 'Cet enregistrement existe déjà.',
  'error_forbidden': 'Tu n’as pas l’autorisation de faire cela.',
  'error_not_found': 'Enregistrement introuvable.',
  'error_server_generic':
      'Un problème de communication avec le serveur est survenu. Réessaie.',
  // --- Main scaffold (bottom nav) ---
  'nav_dashboard': 'Tableau de bord',
  'nav_debts': 'Dettes',
  'nav_groups': 'Groupes',
  'nav_social': 'Social',
  'nav_profile': 'Profil',
  // --- Router fallback titles (used when navigation `extra` is absent) ---
  'route_fallback_group_detail': 'Détail du groupe',
  'route_fallback_group_info': 'Infos du groupe',
  'route_fallback_group': 'Groupe',
  'route_fallback_chat': 'Discussion',
  // --- Activity feed descriptions ---
  'activity_someone': 'Quelqu’un',
  'activity_a_group': 'Un groupe',
  'activity_became_friends': 'Tu es maintenant ami avec {name}.',
  'activity_added_expense':
      'Tu as ajouté une dépense de {amount} dans {group}.',

  // --- Onboarding ---
  'onboarding_skip': 'Passer',
  'onboarding_continue': 'Continuer',
  'onboarding_start_free': 'Commencer gratuitement',
  'onboarding_no_card':
      'Aucune carte requise. Passe à Pro seulement quand cela te fait gagner du temps.',
  'onboarding_persistence_error':
      'Nous n’avons pas pu enregistrer ton choix. Réessaie.',
  'onboarding_p1_eyebrow': 'PERSO + PARTAGÉ',
  'onboarding_p1_title': 'Suis tes dépenses. Partagez les vôtres.',
  'onboarding_p1_description':
      'Ton budget et toutes les dépenses partagées, au même endroit.',
  'onboarding_p1_proof_1': 'Budget personnel',
  'onboarding_p1_proof_2': 'Dépenses de groupe',
  'onboarding_p2_eyebrow': 'PLUS DE CALCULS GÊNANTS',
  'onboarding_p2_title': 'Partagez équitablement. Réglez clairement.',
  'onboarding_p2_description':
      'À parts égales, en pourcentage ou au centime : chacun sait quoi faire.',
  'onboarding_p2_proof_1': 'Partages flexibles',
  'onboarding_p2_proof_2': 'Approbations claires',
  'onboarding_p3_eyebrow': 'DES COMPTES QUI TOMBENT JUSTE',
  'onboarding_p3_title': 'Voyage librement. Garde chaque taux.',
  'onboarding_p3_description':
      'Montants d’origine et taux figés préservent le solde d’hier.',
  'onboarding_p3_proof_1': 'Taux figés',
  'onboarding_p3_proof_2': 'Historique fiable',
  'onboarding_p4_eyebrow': 'DÉBUT GRATUIT',
  'onboarding_p4_title': 'Commence gratuitement. Passe à Pro si utile.',
  'onboarding_p4_description':
      'Active la saisie rapide, les analyses poussées et les rapports avancés au besoin.',
  'onboarding_p4_proof_1': 'Aucun essai imposé',
  'onboarding_p4_proof_2': 'Résiliable à tout moment',

  // --- Subscriptions: paywall copy ---
  'paywall_appbar_title': 'Splixa Pro',
  'paywall_close': 'Fermer',
  'paywall_hero_title':
      'Transforme la gestion de l’argent en une tâche de deux minutes',
  'paywall_hero_subtitle':
      'L’essentiel de Splixa reste gratuit. Passe à Pro quand l’automatisation, le contrôle et des réponses plus fines valent plus que le temps qu’ils font gagner.',
  'paywall_benefits_title': 'Ce que débloque Pro',
  'paywall_benefit_1_title': 'Groupes illimités',
  'paywall_benefit_1_body':
      'Garde chaque voyage, foyer et projet actif, sans limite de groupes.',
  'paywall_benefit_2_title': 'Vois les tendances derrière tes dépenses',
  'paywall_benefit_2_body':
      'Explore d’un coup d’œil la répartition par catégorie et tes habitudes d’activité.',
  'paywall_benefit_3_title': 'Exporte des rapports mensuels soignés',
  'paywall_benefit_3_body':
      'Transforme tes données personnelles en un PDF partageable en un geste.',
  'paywall_benefit_4_title':
      'Aperçu de la feuille de route : moins de saisie, plus de contrôle',
  'paywall_benefit_4_body':
      'Le scan de reçus et les taux de change personnalisés arrivent ensuite.',
  'paywall_choose_plan': 'Choisis ta formule',
  'paywall_best_value': 'MEILLEUR CHOIX',
  'paywall_save_percent': 'ÉCONOMISEZ {percent}%',
  'paywall_start_trial_cta': 'Démarrer mon essai gratuit de {days} jours',
  'paywall_start_trial_cta_generic': 'Démarrer mon essai gratuit',
  'paywall_trust_cancel': 'Annulable à tout moment',
  'paywall_trust_no_charge': 'Aucun débit aujourd\'hui',
  'paywall_trust_store': 'Paiement sécurisé via votre store',
  'paywall_continue_free': 'Pas maintenant — continuer en gratuit',
  'paywall_restore': 'Restaurer les achats',
  'paywall_restore_restored': 'Ton accès Pro a été restauré.',
  'paywall_restore_none':
      'Aucun achat Pro actif n’a été trouvé pour ce compte de la boutique.',
  'paywall_welcome_message': 'Bienvenue sur Splixa Pro.',
  'paywall_purchase_failed_message':
      'L’achat a été annulé ou n’a pas pu aboutir.',
  'paywall_no_packages_available':
      'Les formules sont temporairement indisponibles. Réessaie.',
  'paywall_retry': 'Réessayer',
  'paywall_terms_link': 'Conditions d’utilisation',
  'paywall_privacy_link': 'Politique de confidentialité',
  'paywall_store_disclosure':
      'Le paiement est débité sur ton compte de la boutique. Gère ou résilie l’abonnement depuis les réglages d’abonnement de l’App Store ou de Google Play.',
  'paywall_link_failed': 'La page n’a pas pu être ouverte.',
  'paywall_plan_annual': 'Pro annuel',
  'paywall_plan_monthly': 'Pro mensuel',
  'paywall_period_annual': '/ an',
  'paywall_period_monthly': '/ mois',
  'paywall_monthly_equivalent': 'soit {price} par mois',
  'paywall_continue_with_plan': 'Continuer avec {plan}',
  'paywall_renewal_annual':
      '{price} est débité maintenant. L’abonnement se renouvelle chaque année jusqu’à résiliation.',
  'paywall_renewal_monthly':
      '{price} est débité maintenant. L’abonnement se renouvelle chaque mois jusqu’à résiliation.',

  // --- Relative time (activity feed, chat, notifications) ---
  'time_just_now': 'À l’instant',
  'time_minutes_ago': 'il y a {count} min',
  'time_hours_ago': 'il y a {count} h',
  'time_days_ago': 'il y a {count} j',

  // --- Profile sections & language picker ---
  'profile_section_account': 'Compte',
  'profile_section_subscription': 'Abonnement',
  'profile_section_preferences': 'Préférences',
  'profile_section_support': 'Assistance',
  'profile_section_legal': 'Mentions légales',
  'language_picker_title': 'Choisis ta langue',
  'error_free_group_limit':
      'Le forfait gratuit inclut 2 groupes. Passez à Pro pour des groupes illimités.',
  'error_free_personal_expense_limit':
      'Vous avez atteint 50 dépenses personnelles ce mois-ci. Passez à Pro pour continuer.',
  'error_not_authenticated': 'Reconnectez-vous pour continuer.',
  'pro_tools_title': 'Outils Pro',
  'pro_tools_locked': 'Débloquez tous les outils avancés avec Splixa Pro.',
  'pro_server_verified': 'Accès Pro vérifié en toute sécurité',
  'pro_sync_pending': 'Synchronisation de l’accès Pro',
  'pro_biometric_lock': 'Verrouillage biométrique',
  'pro_biometric_lock_body':
      'Exigez Face ID, empreinte ou sécurité de l’appareil au retour dans Splixa.',
  'pro_biometric_unavailable':
      'L’authentification biométrique est indisponible.',
  'pro_app_lock_reason': 'Authentifiez-vous pour ouvrir vos finances Splixa',
  'pro_app_locked_title': 'Splixa est verrouillé',
  'pro_app_locked_body':
      'Authentifiez-vous pour protéger vos données financières privées.',
  'pro_unlock': 'Déverrouiller',
  'pro_home_widget': 'Widget Ajout rapide',
  'pro_home_widget_body': 'Ajoutez une dépense depuis votre écran d’accueil.',
  'pro_home_widget_manual':
      'Ajoutez le widget Splixa depuis la galerie de widgets.',
  'pro_custom_categories': 'Catégories personnalisées',
  'pro_category_add': 'Ajouter une catégorie',
  'pro_category_name': 'Nom de la catégorie',
  'pro_category_name_helper':
      'Vous pouvez ajouter un emoji au nom si vous le souhaitez',
  'pro_category_emoji': 'Emoji',
  'pro_categories_empty':
      'Créez des catégories réutilisables avec votre emoji et couleur.',
  'pro_recurring_expenses': 'Dépenses récurrentes',
  'pro_recurring_add': 'Ajouter une dépense récurrente',
  'pro_recurring_name': 'Nom de la dépense',
  'pro_recurring_start_date': 'Date de début',
  'pro_recurring_explainer_weekly':
      'La première le {date}, puis chaque semaine.',
  'pro_recurring_explainer_monthly': 'La première le {date}, puis chaque mois.',
  'pro_recurring_empty':
      'Automatisez loyer, abonnements et autres coûts réguliers.',
  'pro_frequency_weekly': 'Hebdomadaire',
  'pro_frequency_monthly': 'Mensuel',
  'pro_export_csv': 'Exporter le CSV complet',
  'pro_advanced_analytics': 'Analyses avancées et plages de dates',
  'pro_custom_rate_title': 'Verrouiller un taux personnalisé',
  'pro_custom_rate_label': 'TRY pour 1 {currency}',
  'pro_custom_rate_helper':
      'Ce taux est enregistré avec la dépense et ne change jamais dans l’historique.',
  'pro_custom_rate_try_identity': 'TRY utilise déjà un taux fixe de 1:1.',
  'pro_receipt_camera': 'Scanner avec l’appareil photo',
  'pro_receipt_gallery': 'Choisir dans la galerie',
  'pro_receipt_ready': 'Reçu prêt · vérifiez les champs',
  'pro_receipt_view': 'Voir le reçu',
  'pro_receipt_review_required':
      'Les suggestions OCR sont remplies. Vérifiez-les avant d’enregistrer.',
  'pro_receipt_upload_failed':
      'La dépense est enregistrée, mais le reçu n’a pas pu être joint.',
  'pro_receipt_invalid_image': 'Cette image n’a pas pu être lue.',
  'pro_ocr_mobile_only': 'Le scanner est disponible sur Android et iOS.',
  'pro_send_reminder': 'Rappeler',
  'pro_reminder_sent': 'Un rappel cordial a été envoyé.',
  'pro_trip_summary': 'Résumé de voyage partageable',
  'pro_trip_privacy_note':
      'L’image contient seulement les totaux, sans soldes privés.',
  'trip_summary_settled_up': 'Tout le monde est à jour',
  'trip_summary_who_owes': 'Qui doit à qui',
  'trip_summary_expenses_title': 'Dépenses',
  'trip_summary_people': '{count} personnes',
  'trip_summary_expenses_count': '{count} dépenses',
  'trip_summary_more': '+{count} autres',
  'pro_trip_share': 'Partager le résumé',
  'statistics_current_month': 'Mois en cours',
  'paywall_free_trial': '7 JOURS GRATUITS',
  'paywall_free_trial_days': 'ESSAI GRATUIT DE {days} JOURS',
  'paywall_free_trial_generic': 'ESSAI GRATUIT',
  'paywall_plan_lifetime': 'Pro à vie',
  'paywall_period_once': 'paiement unique',
  'paywall_lifetime_disclosure':
      '{price} est facturé une fois. Ce n’est pas un abonnement et il ne se renouvelle pas.',
};
