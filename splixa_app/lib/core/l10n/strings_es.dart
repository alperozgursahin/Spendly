// GENERATED-STYLE LOCALE CATALOG — edit by hand, keep keys in sync.
//
// Key order mirrors lib/core/l10n/strings_en.dart, the source locale.
// Every key present in `enStrings` must exist here; `localization_catalog_test`
// fails the build otherwise. Placeholders such as {name} must be preserved
// verbatim — only the surrounding words are translated.

// Launch locale — machine-assisted translation, pending native review.
const Map<String, String> esStrings = {
  // --- Common / shared ---
  'language_selector_label': 'Idioma de la aplicación',
  'common_all': 'Todo',
  'common_reset': 'Restablecer',
  'common_filter': 'Filtrar',
  'common_save': 'Guardar',
  'common_cancel': 'Cancelar',
  'common_delete': 'Eliminar',
  'common_edit': 'Editar',
  'common_add': 'Añadir',
  'common_close': 'Cerrar',
  'common_send': 'Enviar',
  'common_you': 'Tú',
  'common_user': 'Usuario',
  'common_loading': 'Cargando...',
  'common_error_generic': 'Algo salió mal. Inténtalo de nuevo.',
  'common_date': 'Fecha',
  'common_category': 'Categoría',
  'common_expense': 'Gasto',
  'common_income': 'Ingreso',
  'common_currency': 'Moneda',
  'exchange_rate_unavailable':
      'No se pudo cargar el tipo de cambio más reciente. Comprueba tu conexión e inténtalo de nuevo.',
  // --- Category names (shared across dashboard, statistics, add-expense) ---
  'category_market': 'Supermercado',
  'category_food': 'Comida',
  'category_transport': 'Transporte',
  'category_entertainment': 'Ocio',
  'category_salary': 'Salario',
  'category_dues': 'Cuotas',
  'category_bill': 'Factura',
  'category_other': 'Otros',
  // --- Month abbreviations ---
  'month_jan': 'Ene',
  'month_feb': 'Feb',
  'month_mar': 'Mar',
  'month_apr': 'Abr',
  'month_may': 'May',
  'month_jun': 'Jun',
  'month_jul': 'Jul',
  'month_aug': 'Ago',
  'month_sep': 'Sep',
  'month_oct': 'Oct',
  'month_nov': 'Nov',
  'month_dec': 'Dic',
  // --- Dashboard ---
  'dashboard_title': 'Panel',
  'dashboard_statistics': 'Estadísticas',
  'dashboard_notifications': 'Notificaciones',
  'dashboard_activity_feed': 'Actividad',
  'dashboard_recent_transactions': 'Movimientos recientes',
  'dashboard_no_activity': 'Todavía no hay actividad social.',
  'dashboard_no_transactions':
      'Aún no hay movimientos recientes. ¡Pulsa + para añadir el primero!',
  'dashboard_net_balance': 'Balance neto',
  'dashboard_amount_hint': 'Importe',
  'dashboard_custom_category_hint': 'Escribe una categoría personalizada...',
  'dashboard_pick_date': 'Elegir fecha',
  'dashboard_transaction_added': '¡Movimiento añadido!',
  'home_welcome': 'Hola, {name}',
  'home_default_name': '¿qué tal?',
  'home_subtitle': 'Organicemos tus finanzas hoy.',
  'home_new_group': 'Nuevo',
  'home_group_name_hint': 'p. ej. Viaje de verano',
  'home_groups_empty':
      'Aún no tienes grupos. ¡Pulsa + Nuevo para empezar a dividir!',
  'home_members_loading': 'Cargando miembros…',
  'home_members_count': '{count} miembros',
  'home_quick_add': 'Añadir movimiento',
  'home_switch_to_light': 'Cambiar al tema claro',
  'home_switch_to_dark': 'Cambiar al tema oscuro',
  'home_switch_language': 'Cambiar idioma',
  'home_minimize_title': 'Minimizar transacciones',
  'home_minimize_description':
      'Splixa simplifica los saldos del grupo para que todos salden cuentas con el menor número de pagos posible.',
  'minimize_without_title': 'Sin minimizar transacciones',
  'minimize_without_description':
      'Hacen falta dos pagos distintos. La persona B recibe dinero solo para pasarle la misma cantidad a la persona C.',
  'minimize_with_title': 'Con transacciones minimizadas',
  'minimize_with_description':
      'Splixa elimina al intermediario. La persona A paga directamente a la persona C y salda los mismos saldos con un solo pago.',
  'minimize_person_a': 'Persona A',
  'minimize_person_b': 'Persona B',
  'minimize_person_c': 'Persona C',
  'minimize_pays_100': 'Paga 100',
  'minimize_one_fewer': '1 transacción menos',
  // --- Statistics ---
  'statistics_title': 'Estadísticas',
  'statistics_category_distribution': 'Desglose por categoría (este mes)',
  'statistics_no_expenses_this_month': 'No tienes gastos este mes.',
  'statistics_heatmap_title': 'Mapa de actividad',
  'statistics_heatmap_activity_count': 'actividades',
  // --- Auth: login ---
  'login_title': 'Iniciar sesión en Splixa',
  'login_username_required': 'Escribe tu nombre de usuario.',
  'login_password_required': 'Escribe tu contraseña.',
  'login_username_label': 'Nombre de usuario (@usuario)',
  'login_password_label': 'Contraseña',
  'login_forgot_password': '¿Olvidaste tu contraseña?',
  'login_submit': 'Iniciar sesión',
  'login_or': 'o',
  'login_google_continue': 'Continuar con Google',
  'login_no_account': '¿No tienes cuenta? Regístrate',
  'login_welcome': 'Te damos la bienvenida a Splixa',
  'login_identifier_subtitle':
      'Inicia sesión con tu correo o nombre de usuario y tu contraseña.',
  'login_identifier_label': 'Correo o nombre de usuario',
  'login_identifier_hint': 'tu@ejemplo.com o @usuario',
  'login_identifier_required': 'Escribe tu correo o nombre de usuario.',
  // --- Auth: register ---
  'register_title': 'Crear cuenta en Splixa',
  'register_username_too_short':
      'El nombre de usuario debe tener al menos 3 caracteres.',
  'register_email_invalid': 'Escribe una dirección de correo válida.',
  'register_password_too_short':
      'La contraseña debe tener al menos 6 caracteres.',
  'register_success': '¡Registro completado! Ya puedes iniciar sesión.',
  'register_email_label': 'Correo electrónico',
  'register_submit': 'Registrarse',
  'register_have_account': '¿Ya tienes cuenta? Inicia sesión',
  // --- Auth: Google profile completion ---
  'profile_setup_title': '¿Cómo quieres que te llamemos?',
  'profile_setup_subtitle':
      'Elige un nombre de usuario único para que tus amigos puedan encontrarte en Splixa.',
  'profile_setup_username_label': 'Nombre de usuario',
  'profile_setup_username_hint': 'tu_usuario',
  'profile_setup_username_helper':
      'De 3 a 30 caracteres; solo letras, números y guion bajo.',
  'profile_setup_continue': 'Continuar a Splixa',
  'profile_setup_use_other_account': 'Usar otra cuenta',
  'profile_setup_username_taken':
      'Ese nombre de usuario ya está en uso. Prueba con otro.',
  'profile_setup_session_expired':
      'Tu sesión ha caducado. Inicia sesión de nuevo.',
  'profile_setup_timeout':
      'La solicitud ha tardado demasiado. Inténtalo de nuevo.',
  'profile_setup_failed':
      'No se pudo guardar tu nombre de usuario. Inténtalo de nuevo.',
  // --- Auth: forgot / update password ---
  'forgot_password_title': 'Contraseña olvidada',
  'forgot_password_email_invalid': 'Escribe una dirección de correo válida.',
  'forgot_password_sent_message':
      'Hemos enviado un código de recuperación de 8 dígitos a tu correo.',
  'forgot_password_back_to_login': 'Volver al inicio de sesión',
  'forgot_password_prompt':
      'Escribe el correo de tu cuenta y te enviaremos un código de recuperación de 8 dígitos.',
  'forgot_password_email_label': 'Correo electrónico',
  'forgot_password_send_link': 'Enviar código de recuperación',
  'forgot_password_send_code': 'Enviar código de recuperación',
  'login_verification_title': 'Verificación en dos pasos',
  'login_verification_prompt':
      'Escribe el código de verificación de 8 dígitos enviado a {email}.',
  'login_verification_submit': 'Verificar e iniciar sesión',
  'auth_code_label': 'Código de 8 dígitos',
  'auth_code_eight_digits_required': 'El código debe tener 8 dígitos.',
  'auth_code_resend': 'Reenviar código',
  'auth_code_resending': 'Enviando...',
  'auth_code_resent':
      'Hemos enviado un nuevo código de verificación a tu correo.',
  'auth_code_invalid_or_expired': 'El código no es válido o ha caducado.',
  'reset_password_code_title': 'Restablecer contraseña',
  'reset_password_code_prompt':
      'Escribe el código de recuperación enviado a {email} y tu nueva contraseña.',
  'reset_password_code_submit': 'Verificar código y actualizar contraseña',
  'update_password_title': 'Establecer nueva contraseña',
  'update_password_too_short':
      'La contraseña debe tener al menos 6 caracteres.',
  'update_password_success': '¡Tu contraseña se ha actualizado correctamente!',
  'update_password_prompt': 'Establece una nueva contraseña para tu cuenta.',
  'update_password_new_label': 'Nueva contraseña',
  'update_password_submit': 'Actualizar contraseña',
  // --- Groups: list ---
  'groups_title': 'Grupos',
  'groups_empty_title': 'Todavía no formas parte de ningún grupo.',
  'groups_empty_subtitle':
      'Pulsa el botón + de abajo a la derecha para crear tu primer grupo.',
  'groups_tap_for_details': 'Pulsa para ver los detalles del grupo',
  'groups_create_new_group': 'Crear grupo',
  'groups_name_label': 'Nombre del grupo',
  'groups_create_button': 'Crear',
  // --- Groups: detail screen ---
  'groups_participants_suffix': 'participantes',
  'groups_participants_load_error': 'No se pudieron cargar los participantes',
  'groups_chat_tooltip': 'Chat del grupo',
  'groups_invite_friend_tooltip': 'Invitar a un amigo',
  'groups_paid_verb': 'pagó',
  'groups_tab_pending': 'Pendientes',
  'groups_tab_active': 'Activos',
  'groups_tab_archived': 'Archivo',
  'groups_no_transactions':
      'Todavía no hay movimientos. Añade el primer gasto.',
  'groups_empty_pending': 'No hay gastos pendientes de aprobación.',
  'groups_empty_active': 'No hay gastos activos.',
  'groups_empty_archived': 'No hay gastos archivados.',
  'groups_add_expense': 'Añadir gasto',
  'groups_archive_all_button': 'Archivar todo',
  'groups_action_failed': 'No se pudo completar la acción. Inténtalo de nuevo.',
  'groups_archive_failed': 'No se pudo archivar el gasto. Inténtalo de nuevo.',
  'groups_status_payer': 'Pagador',
  'groups_status_pending': 'Pendiente de aprobación',
  'groups_status_approved_self': 'Aprobado',
  'groups_status_active_debt': 'Deuda activa',
  'groups_status_payment_pending_payer': 'Pendiente de confirmar el pago',
  'groups_status_payment_reported': 'Pago notificado',
  'groups_status_settled': 'Pagado',
  'groups_status_rejected': 'Rechazado',
  'groups_action_approve': 'Aprobar',
  'groups_action_mark_paid': 'Marcar como pagado',
  'groups_action_confirm_payment': 'Confirmar pago',
  'groups_balance_title': 'Balance del grupo',
  'groups_no_active_debt': 'No hay deudas activas.',
  'groups_creditor_label': 'Le deben',
  'groups_debtor_label': 'Debe',
  'groups_filter_payer_label': 'Pagado por',
  // --- Groups: info screen ---
  'group_info_change_picture': 'Cambiar la foto del grupo',
  'group_info_group_picture': 'Foto del grupo',
  'group_info_admin': 'Administrador',
  'group_info_remove_member': 'Expulsar miembro',
  'group_info_this_member': 'este miembro',
  'group_info_remove_member_title': '¿Expulsar al miembro?',
  'group_info_remove_member_body':
      '{member} perderá el acceso a este grupo y a su chat.',
  'group_info_remove': 'Expulsar',
  'group_info_title': 'Información del grupo',
  'group_info_leave_button': 'Salir del grupo',
  'group_info_delete_button': 'Eliminar grupo',
  'group_info_leave_confirm':
      '¿Seguro que quieres salir de "%s"? Tus gastos anteriores seguirán en el grupo.',
  'group_info_leave_confirm_button': 'Salir',
  'group_info_delete_confirm':
      '¿Seguro que quieres eliminar definitivamente "%s" y todos sus datos de gastos y miembros? Esta acción no se puede deshacer.',
  // --- Groups: chat ---
  'groups_chat_title': 'Chat de {group}',
  'groups_chat_suffix': 'Chat',
  'groups_chat_empty': 'Todavía no hay mensajes. ¡Escribe el primero!',
  'groups_chat_input_hint': 'Escribe un mensaje...',
  // --- Groups: add expense sheet ---
  'groups_scan_receipt': 'Escanear recibo',
  'groups_custom_exchange_rate': 'Tipo de cambio personalizado',
  'groups_pro_tool_coming_soon':
      'Esta herramienta Pro estará disponible pronto.',
  'dashboard_custom_rate_coming_soon':
      'El editor de tipo de cambio personalizado llegará pronto.',
  'groups_expense_desc_label': '¿Para qué?',
  'groups_total_amount_label': 'Importe total',
  'groups_split_equal': 'Partes iguales (=)',
  'groups_split_percentage': 'Porcentaje (%)',
  'groups_split_exact': 'Importe',
  'groups_split_for_whom': '¿Para quién es este gasto?',
  'groups_auto_badge': 'auto',
  'groups_expense_validation_generic':
      'Introduce datos válidos y selecciona al menos 1 persona.',
  'groups_percentage_validation':
      'Como máximo 1 persona puede quedarse sin porcentaje y el total debe sumar 100.',
  'groups_percentage_total_validation': 'Los porcentajes deben sumar 100.',
  'groups_exact_validation':
      'Como máximo 1 persona puede quedarse sin importe y el total debe coincidir con el gasto.',
  // --- Groups: invite friend modal ---
  'groups_invited_snackbar': '¡Invitación enviada!',
  'groups_invite_modal_title': 'Invitar a un amigo al grupo',
  'groups_invite_search_hint': 'Busca entre tus amigos',
  'groups_no_friends_to_invite': 'No tienes amigos a los que invitar.',
  'groups_no_friends_hint': 'Añade amigos primero desde la pestaña Social.',
  'groups_no_search_match': 'Ningún amigo coincide con tu búsqueda.',
  // --- Debts ---
  'debts_back_tooltip': 'Atrás',
  'debts_title': 'Deudas',
  'debts_tab_mine': 'Mis deudas',
  'debts_tab_owed_to_me': 'Me deben',
  'debts_tab_approvals': 'Aprobaciones',
  'debts_tab_summary': 'Resumen',
  'debts_user_info_unavailable':
      'No se pudo obtener la información del usuario.',
  'debts_not_in_any_group': 'Todavía no formas parte de ningún grupo.',
  'debts_owed_by_prefix': 'Se le debe a',
  'debts_owed_to_me_prefix': 'Nos debe',
  'debts_no_active_debt': 'No tienes deudas activas.',
  'debts_no_active_credit': 'Nadie te debe nada ahora mismo.',
  'debts_total_debt_label': 'Deuda total',
  'debts_total_credit_label': 'Crédito total',
  'debts_awaiting_my_approval': 'Esperando tu aprobación',
  'debts_no_awaiting_my_approval': 'No hay deudas esperando tu aprobación.',
  'debts_awaiting_other_approval': 'Esperando la aprobación de la otra parte',
  'debts_no_awaiting_other_approval':
      'No hay deudas esperando la aprobación de la otra parte.',
  'debts_reject_tooltip': 'Rechazar',
  'debts_no_settlement': 'No hay ninguna deuda que saldar.',
  'debts_settled_debt_subtitle': 'Deuda saldada',
  'debts_total_prefix': 'Total',
  'debts_filter_group_label': 'Grupo',
  'debts_clear_filters_tooltip': 'Borrar filtros',
  // --- Notifications ---
  'notifications_login_required': 'Inicia sesión para ver tus notificaciones.',
  'notifications_empty_title': 'Todavía no tienes notificaciones.',
  'notifications_empty_subtitle':
      'Aquí aparecerán las novedades de gastos y aprobaciones de tus grupos.',
  // --- Notifications: dynamically built messages ---
  'notif_new_expense_title': 'Nuevo gasto',
  'notif_new_expense_message':
      '{sender} te ha añadido al gasto "{desc}" del grupo {group}. Importe: {amount}. Esperando tu aprobación.',
  'notif_payment_confirmation_title': 'Pago notificado',
  'notif_payment_confirmation_message':
      '{sender} ha notificado un pago de "{desc}" en el grupo {group}.',
  'notif_debt_approved_title': 'Deuda aprobada',
  'notif_debt_approved_message':
      '{sender} ha aprobado la deuda de "{desc}" en el grupo {group}.',
  'notif_debt_rejected_title': 'Deuda rechazada',
  'notif_debt_rejected_message':
      '{sender} ha rechazado la deuda de "{desc}" en el grupo {group}.',
  'notif_debt_settled_title': 'Pago confirmado',
  'notif_debt_settled_message':
      '{sender} ha confirmado tu pago de "{desc}" en el grupo {group}. La deuda está saldada.',
  'notif_default_group': 'Un grupo',
  'notif_default_user': 'Un usuario',
  'notif_default_expense_desc': 'gasto',
  // --- Profile ---
  'profile_title': 'Perfil',
  'profile_email_missing': 'Correo no añadido',
  'profile_user_fallback': 'Usuario de Splixa',
  'profile_manage_subscription': 'Gestionar suscripción',
  'profile_upgrade_pro': 'Pasar a Pro',
  'profile_settings': 'Ajustes',
  'profile_invite_friends': 'Invitar a amigos',
  'profile_download_monthly_report': 'Descargar informe mensual',
  'profile_download_monthly_report_pro': 'Descargar informe mensual · Pro',
  'profile_contact_us': 'Contacto',
  'profile_support_placeholder':
      'Aquí estará disponible el contacto de soporte.',
  'profile_terms': 'Términos',
  'profile_privacy': 'Privacidad',
  'profile_choose_picture': 'Elegir foto de perfil',
  'profile_tap_choose_photo': 'Pulsa para elegir una foto',
  'profile_username_label': 'Nombre de usuario',
  'profile_email_label': 'Correo electrónico',
  'profile_dark_mode': 'Modo oscuro',
  'profile_link_failed': 'No se pudo abrir esta página.',
  'profile_delete_dialog_title': '¿Eliminar la cuenta y los datos?',
  'profile_delete_dialog_body':
      'Esta acción es permanente. Se eliminarán tu perfil, tus movimientos personales, tus mensajes y tus conexiones sociales. El historial financiero compartido se conserva de forma anónima para que los saldos de los demás miembros sigan siendo correctos.',
  'profile_delete_group_warning':
      'Si administras un grupo con otros miembros, primero debes eliminarlo o transferir su propiedad.',
  'profile_delete_type_confirm': 'Escribe DELETE para confirmar:',
  'profile_delete_transfer_first':
      'Elimina o transfiere primero los grupos que administras:',
  'profile_delete_failed': 'No se pudo eliminar la cuenta. Inténtalo de nuevo.',
  'profile_delete_invalid_response':
      'El servicio de eliminación devolvió una respuesta no válida.',
  'profile_deleting': 'Eliminando…',
  'profile_delete_permanently': 'Eliminar definitivamente',
  'profile_membership_pro': 'PRO',
  'profile_membership_standard': 'ESTÁNDAR',
  'profile_unknown_username': '@desconocido',
  'profile_edit_tile': 'Editar perfil',
  'profile_currency_tile': 'Moneda',
  'profile_change_password_tile': 'Cambiar contraseña',
  'profile_download_report_tile': 'Descargar informe mensual (PDF)',
  'profile_pdf_error': 'No se pudo generar el PDF: %s',
  'profile_logout': 'Cerrar sesión',
  'profile_danger_zone': 'Zona de riesgo',
  'profile_delete_account_data': 'Eliminar cuenta y datos',
  'profile_delete_account_title': 'Eliminar cuenta',
  'profile_delete_account_confirm':
      '¿Seguro que quieres eliminar definitivamente tu cuenta y todos sus datos? Esta acción no se puede deshacer.',
  'profile_avatar_url_label': 'URL del avatar (opcional)',
  'profile_update_success': 'Perfil actualizado correctamente.',
  'profile_bio_label': 'Biografía',
  'profile_bio_hint': 'Cuenta algo sobre ti...',
  'profile_bio_empty': 'Todavía no has añadido una biografía.',
  // --- Profile: PDF export ---
  'pdf_title': 'Informe mensual - %s',
  'pdf_total_income': 'Ingresos totales',
  'pdf_total_expense': 'Gastos totales',
  'pdf_net_balance': 'Balance neto',
  'pdf_transaction_details': 'Detalle de movimientos',
  'pdf_no_transactions': 'No hay movimientos este mes.',
  'pdf_header_type': 'Tipo',
  // --- Social ---
  'social_title': 'Social',
  'social_request_sent_snackbar': '¡Solicitud enviada!',
  'social_user_not_found': 'Usuario no encontrado.',
  'social_search_results_header': 'Resultados de la búsqueda',
  'social_add_friend_tooltip': 'Añadir amigo',
  'social_search_hint': 'Busca usuarios por @usuario',
  'social_search_tooltip': 'Buscar usuarios',
  'social_no_friends_title': 'Todavía no tienes amigos.',
  'social_no_friends_subtitle':
      'Usa el buscador de arriba para encontrar un nombre de usuario y enviar una solicitud de amistad.',
  'social_request_sent_prefix': 'Solicitud enviada: %s',
  'social_pending_status': 'Pendiente...',
  'social_incoming_request_prefix': 'Solicitud para ti: %s',
  'social_friend_prefix': 'Amigo: %s',
  'social_default_chat_title': 'Amigo',
  // --- Social: other user profile ---
  'other_profile_title': 'Perfil de usuario',
  'other_profile_unknown': 'Desconocido',
  'other_profile_no_shared_groups': 'Sin grupos en común',
  'other_profile_shared_groups_count': 'Tenéis %s grupos en común',
  'other_profile_send_message': 'Enviar mensaje',
  // --- Subscriptions: paywall ---
  'paywall_title': 'Pasa a Splixa Pro',
  'paywall_subtitle':
      '¡Crea grupos ilimitados, accede a todas las estadísticas y disfruta de tu libertad financiera!',
  'paywall_no_packages': 'Ahora mismo no hay paquetes disponibles.',
  'paywall_restore_purchases': 'Restaurar compras',
  'paywall_restore_success': '¡Compras restauradas!',
  'paywall_processing_purchase': 'Procesando la compra...',
  'paywall_welcome_pro': '¡Te damos la bienvenida a Splixa Pro!',
  'paywall_purchase_failed': 'La operación se canceló o no se pudo completar.',
  'paywall_benefit_unlimited_groups': 'Crea grupos ilimitados',
  'paywall_benefit_statistics': 'Accede a todas las estadísticas e informes',
  'paywall_benefit_freedom': 'Disfruta de tu libertad financiera',
  'paywall_no_packages_hint': 'Los paquetes aparecerán aquí pronto.',
  'paywall_footer_note': 'Puedes cancelar tu suscripción cuando quieras.',
  // --- Friendly error messages ---
  'error_generic_short': 'Algo salió mal. Inténtalo de nuevo.',
  'error_auth_generic': 'Ha ocurrido un problema. Inténtalo de nuevo.',
  'error_google_cancelled':
      'El inicio de sesión con Google se canceló o no se pudo verificar el dispositivo. Inténtalo de nuevo.',
  'error_google_configuration':
      'El inicio de sesión con Google no está configurado correctamente.',
  'error_google_unavailable':
      'El inicio de sesión con Google no está disponible en este dispositivo.',
  'error_google_timeout':
      'El inicio de sesión con Google ha tardado demasiado. Inténtalo de nuevo.',
  'error_google_failed':
      'No se pudo completar el inicio de sesión con Google. Inténtalo de nuevo.',
  'error_invalid_credentials': 'Nombre de usuario o contraseña incorrectos.',
  'error_email_not_confirmed':
      'Tu dirección de correo aún no se ha verificado.',
  'error_email_already_registered': 'Ya existe una cuenta con este correo.',
  'error_password_too_short':
      'La contraseña es demasiado corta. Elige una más larga.',
  'error_rate_limited':
      'Demasiados intentos. Vuelve a intentarlo en un momento.',
  'error_duplicate_record': 'Este registro ya existe.',
  'error_forbidden': 'No tienes permiso para hacer esto.',
  'error_not_found': 'Registro no encontrado.',
  'error_server_generic':
      'Hubo un problema de comunicación con el servidor. Inténtalo de nuevo.',
  // --- Main scaffold (bottom nav) ---
  'nav_dashboard': 'Panel',
  'nav_debts': 'Deudas',
  'nav_groups': 'Grupos',
  'nav_social': 'Social',
  'nav_profile': 'Perfil',
  // --- Router fallback titles (used when navigation `extra` is absent) ---
  'route_fallback_group_detail': 'Detalle del grupo',
  'route_fallback_group_info': 'Información del grupo',
  'route_fallback_group': 'Grupo',
  'route_fallback_chat': 'Chat',
  // --- Activity feed descriptions ---
  'activity_someone': 'Alguien',
  'activity_a_group': 'Un grupo',
  'activity_became_friends': 'Ahora eres amigo de {name}.',
  'activity_added_expense': 'Has añadido un gasto de {amount} en {group}.',

  // --- Onboarding ---
  'onboarding_skip': 'Omitir',
  'onboarding_continue': 'Continuar',
  'onboarding_start_free': 'Empezar gratis',
  'onboarding_no_card':
      'No hace falta tarjeta. Pasa a Pro solo cuando te ahorre tiempo.',
  'onboarding_persistence_error':
      'No hemos podido guardar tu elección. Inténtalo de nuevo.',
  'onboarding_p1_eyebrow': 'PERSONAL + COMPARTIDO',
  'onboarding_p1_title': 'Un único lugar tranquilo para cada gasto',
  'onboarding_p1_description':
      'Controla tu propio presupuesto y los gastos compartidos del grupo sin cambiar de aplicación ni perder la visión completa.',
  'onboarding_p1_proof_1': 'Presupuesto personal',
  'onboarding_p1_proof_2': 'Gastos de grupo',
  'onboarding_p2_eyebrow': 'SIN CUENTAS INCÓMODAS',
  'onboarding_p2_title': 'Reparte el momento, no la amistad',
  'onboarding_p2_description':
      'Elige partes iguales, porcentajes o importes exactos. Todos pueden aprobar, pagar y saldar con un historial claro.',
  'onboarding_p2_proof_1': 'Repartos flexibles',
  'onboarding_p2_proof_2': 'Aprobaciones claras',
  'onboarding_p3_eyebrow': 'CUENTAS QUE CUADRAN',
  'onboarding_p3_title': 'Cada moneda conserva su historia',
  'onboarding_p3_description':
      'Splixa guarda el importe original y el tipo de cambio bloqueado, así el saldo de ayer nunca cambia a tus espaldas.',
  'onboarding_p3_proof_1': 'Tipos bloqueados',
  'onboarding_p3_proof_2': 'Historial fiable',
  'onboarding_p4_eyebrow': 'EMPEZAR ES GRATIS',
  'onboarding_p4_title': 'Lo esencial, gratis. Con Pro, ahorra tiempo.',
  'onboarding_p4_description':
      'Primero crea el hábito. Cuando quieras escaneo de recibos, tipos personalizados, análisis más profundos e informes avanzados, mira lo que ofrece Pro hoy y lo que viene después.',
  'onboarding_p4_proof_1': 'Sin prueba obligatoria',
  'onboarding_p4_proof_2': 'Cancela cuando quieras',

  // --- Subscriptions: paywall copy ---
  'paywall_appbar_title': 'Splixa Pro',
  'paywall_close': 'Cerrar',
  'paywall_hero_title':
      'Convierte la gestión del dinero en una tarea de dos minutos',
  'paywall_hero_subtitle':
      'El núcleo de Splixa seguirá siendo gratis. Pasa a Pro cuando la automatización, el control y las respuestas más profundas valgan más que el tiempo que ahorran.',
  'paywall_benefits_title': 'Lo que desbloquea Pro',
  'paywall_benefit_1_title': 'Grupos ilimitados',
  'paywall_benefit_1_body':
      'Mantén activos todos tus viajes, tu casa y tus proyectos sin límite de grupos.',
  'paywall_benefit_2_title': 'Descubre los patrones de tus gastos',
  'paywall_benefit_2_body':
      'Explora de un vistazo la distribución por categorías y tus patrones de actividad.',
  'paywall_benefit_3_title': 'Exporta informes mensuales cuidados',
  'paywall_benefit_3_body':
      'Convierte tus registros personales en un PDF listo para compartir con un toque.',
  'paywall_benefit_4_title':
      'Vista previa del roadmap: menos escribir, más control',
  'paywall_benefit_4_body':
      'El escaneo de recibos y los tipos de cambio personalizados llegarán a continuación.',
  'paywall_choose_plan': 'Elige tu plan',
  'paywall_best_value': 'MEJOR OPCIÓN',
  'paywall_continue_free': 'Ahora no — seguir con la versión gratuita',
  'paywall_restore': 'Restaurar compras',
  'paywall_restore_restored': 'Se ha restaurado tu acceso Pro.',
  'paywall_restore_none':
      'No se encontró ninguna compra Pro activa en esta cuenta de la tienda.',
  'paywall_welcome_message': 'Te damos la bienvenida a Splixa Pro.',
  'paywall_purchase_failed_message':
      'La compra se canceló o no se pudo completar.',
  'paywall_no_packages_available':
      'Los planes no están disponibles temporalmente. Inténtalo de nuevo.',
  'paywall_retry': 'Reintentar',
  'paywall_terms_link': 'Condiciones de uso',
  'paywall_privacy_link': 'Política de privacidad',
  'paywall_store_disclosure':
      'El pago se cobra en tu cuenta de la tienda. Gestiona o cancela la suscripción desde los ajustes de App Store o Google Play.',
  'paywall_link_failed': 'No se pudo abrir la página.',
  'paywall_plan_annual': 'Pro anual',
  'paywall_plan_monthly': 'Pro mensual',
  'paywall_period_annual': '/ año',
  'paywall_period_monthly': '/ mes',
  'paywall_monthly_equivalent': '{price} equivalente al mes',
  'paywall_continue_with_plan': 'Continuar con {plan}',
  'paywall_renewal_annual':
      'Se cobra {price} ahora. La suscripción se renueva cada año hasta que la canceles.',
  'paywall_renewal_monthly':
      'Se cobra {price} ahora. La suscripción se renueva cada mes hasta que la canceles.',

  // --- Relative time (activity feed, chat, notifications) ---
  'time_just_now': 'Ahora mismo',
  'time_minutes_ago': 'hace {count} min',
  'time_hours_ago': 'hace {count} h',
  'time_days_ago': 'hace {count} d',

  // --- Profile sections & language picker ---
  'profile_section_account': 'Cuenta',
  'profile_section_subscription': 'Suscripción',
  'profile_section_preferences': 'Preferencias',
  'profile_section_support': 'Soporte',
  'profile_section_legal': 'Legal',
  'language_picker_title': 'Elige tu idioma',
};
