// GENERATED-STYLE LOCALE CATALOG — edit by hand, keep keys in sync.
//
// Key order mirrors lib/core/l10n/strings_en.dart, the source locale.
// Every key present in `enStrings` must exist here; `localization_catalog_test`
// fails the build otherwise. Placeholders such as {name} must be preserved
// verbatim — only the surrounding words are translated.

// Launch locale — machine-assisted translation, pending native review.
const Map<String, String> ptStrings = {
  // --- Common / shared ---
  'language_selector_label': 'Idioma do aplicativo',
  'common_all': 'Tudo',
  'common_reset': 'Redefinir',
  'common_filter': 'Filtrar',
  'common_save': 'Salvar',
  'common_cancel': 'Cancelar',
  'common_delete': 'Excluir',
  'common_edit': 'Editar',
  'common_add': 'Adicionar',
  'common_close': 'Fechar',
  'common_send': 'Enviar',
  'common_you': 'Você',
  'common_user': 'Usuário',
  'common_loading': 'Carregando...',
  'common_retry': 'Tentar novamente',
  'common_error_generic': 'Algo deu errado. Tente novamente.',
  'common_date': 'Data',
  'common_category': 'Categoria',
  'common_expense': 'Despesa',
  'common_income': 'Receita',
  'common_currency': 'Moeda',
  'exchange_rate_unavailable':
      'Não foi possível carregar a taxa de câmbio mais recente. Verifique sua conexão e tente novamente.',
  // --- Category names (shared across dashboard, statistics, add-expense) ---
  'category_market': 'Mercado',
  'category_food': 'Alimentação',
  'category_transport': 'Transporte',
  'category_entertainment': 'Lazer',
  'category_salary': 'Salário',
  'category_dues': 'Mensalidade',
  'category_bill': 'Conta',
  'category_other': 'Outros',
  // --- Month abbreviations ---
  'month_jan': 'Jan',
  'month_feb': 'Fev',
  'month_mar': 'Mar',
  'month_apr': 'Abr',
  'month_may': 'Mai',
  'month_jun': 'Jun',
  'month_jul': 'Jul',
  'month_aug': 'Ago',
  'month_sep': 'Set',
  'month_oct': 'Out',
  'month_nov': 'Nov',
  'month_dec': 'Dez',
  // --- Dashboard ---
  'dashboard_title': 'Painel',
  'dashboard_statistics': 'Estatísticas',
  'dashboard_notifications': 'Notificações',
  'dashboard_activity_feed': 'Atividades',
  'dashboard_recent_transactions': 'Transações recentes',
  'dashboard_no_activity': 'Ainda não há atividade social.',
  'dashboard_no_transactions':
      'Ainda não há transações recentes. Toque em + para adicionar a primeira!',
  'dashboard_net_balance': 'Saldo líquido',
  'dashboard_amount_hint': 'Valor',
  'dashboard_custom_category_hint': 'Digite uma categoria personalizada...',
  'dashboard_pick_date': 'Escolher data',
  'dashboard_transaction_added': 'Transação adicionada!',
  'home_welcome': 'Olá, {name}',
  'home_default_name': 'tudo bem?',
  'home_subtitle': 'Vamos organizar suas finanças hoje.',
  'home_new_group': 'Novo',
  'home_group_name_hint': 'ex.: Viagem de verão',
  'home_groups_empty':
      'Nenhum grupo ainda. Toque em + Novo para começar a dividir!',
  'home_members_loading': 'Carregando participantes…',
  'home_members_count': '{count} participantes',
  'home_quick_add': 'Adicionar transação',
  'home_switch_to_light': 'Mudar para o tema claro',
  'home_switch_to_dark': 'Mudar para o tema escuro',
  'home_switch_language': 'Mudar idioma',
  'home_minimize_title': 'Minimizar transações',
  'home_minimize_description':
      'O Splixa simplifica os saldos do grupo para que todos acertem as contas com o menor número possível de pagamentos.',
  'minimize_without_title': 'Sem minimizar transações',
  'minimize_without_description':
      'São necessários dois pagamentos separados. A pessoa B recebe dinheiro só para repassar o mesmo valor à pessoa C.',
  'minimize_with_title': 'Com transações minimizadas',
  'minimize_with_description':
      'O Splixa elimina o intermediário. A pessoa A paga direto à pessoa C e quita os mesmos saldos com um único pagamento.',
  'minimize_person_a': 'Pessoa A',
  'minimize_person_b': 'Pessoa B',
  'minimize_person_c': 'Pessoa C',
  'minimize_pays_100': 'Paga 100',
  'minimize_one_fewer': '1 transação a menos',
  // --- Statistics ---
  'statistics_title': 'Estatísticas',
  'statistics_category_distribution': 'Distribuição por categoria (este mês)',
  'statistics_no_expenses_this_month': 'Você não tem despesas neste mês.',
  'statistics_heatmap_title': 'Mapa de atividades',
  'statistics_heatmap_activity_count': 'atividades',
  // --- Auth: login ---
  'login_title': 'Entrar no Splixa',
  'login_username_required': 'Digite seu nome de usuário.',
  'login_password_required': 'Digite sua senha.',
  'login_username_label': 'Nome de usuário (@usuario)',
  'login_password_label': 'Senha',
  'login_forgot_password': 'Esqueceu a senha?',
  'login_submit': 'Entrar',
  'login_or': 'ou',
  'login_google_continue': 'Continuar com o Google',
  'login_no_account': 'Não tem uma conta? Cadastre-se',
  'login_welcome': 'Boas-vindas ao Splixa',
  'login_identifier_subtitle':
      'Entre com seu e-mail ou nome de usuário e sua senha.',
  'login_identifier_label': 'E-mail ou nome de usuário',
  'login_identifier_hint': 'voce@exemplo.com ou @usuario',
  'login_identifier_required': 'Digite seu e-mail ou nome de usuário.',
  // --- Auth: register ---
  'register_title': 'Criar conta no Splixa',
  'register_username_too_short':
      'O nome de usuário precisa ter pelo menos 3 caracteres.',
  'register_email_invalid': 'Digite um endereço de e-mail válido.',
  'register_password_too_short': 'A senha precisa ter pelo menos 6 caracteres.',
  'register_success': 'Cadastro concluído! Faça login.',
  'register_email_label': 'E-mail',
  'register_submit': 'Cadastrar',
  'register_have_account': 'Já tem uma conta? Entrar',
  // --- Auth: Google profile completion ---
  'profile_setup_title': 'Como podemos te chamar?',
  'profile_setup_subtitle':
      'Escolha um nome de usuário único para que seus amigos encontrem você no Splixa.',
  'profile_setup_username_label': 'Nome de usuário',
  'profile_setup_username_hint': 'seu_usuario',
  'profile_setup_username_helper':
      'De 3 a 30 caracteres; apenas letras, números e sublinhado.',
  'profile_setup_continue': 'Continuar para o Splixa',
  'profile_setup_use_other_account': 'Usar outra conta',
  'profile_setup_username_taken':
      'Esse nome de usuário já está em uso. Tente outro.',
  'profile_setup_session_expired': 'Sua sessão expirou. Entre novamente.',
  'profile_setup_timeout': 'A solicitação expirou. Tente novamente.',
  'profile_setup_failed':
      'Não foi possível salvar seu nome de usuário. Tente novamente.',
  // --- Auth: forgot / update password ---
  'forgot_password_title': 'Esqueci a senha',
  'forgot_password_email_invalid': 'Digite um endereço de e-mail válido.',
  'forgot_password_sent_message':
      'Enviamos um código de recuperação de 8 dígitos para o seu e-mail.',
  'forgot_password_back_to_login': 'Voltar para o login',
  'forgot_password_prompt':
      'Digite o e-mail da sua conta e enviaremos um código de recuperação de 8 dígitos.',
  'forgot_password_email_label': 'E-mail',
  'forgot_password_send_link': 'Enviar código de recuperação',
  'forgot_password_send_code': 'Enviar código de recuperação',
  'login_verification_title': 'Verificação em duas etapas',
  'login_verification_prompt':
      'Digite o código de verificação de 8 dígitos enviado para {email}.',
  'login_verification_submit': 'Verificar e entrar',
  'auth_code_label': 'Código de 8 dígitos',
  'auth_code_eight_digits_required': 'O código precisa ter 8 dígitos.',
  'auth_code_resend': 'Reenviar código',
  'auth_code_resending': 'Enviando...',
  'auth_code_resent':
      'Um novo código de verificação foi enviado para o seu e-mail.',
  'auth_code_invalid_or_expired': 'O código é inválido ou expirou.',
  'reset_password_code_title': 'Redefinir senha',
  'reset_password_code_prompt':
      'Digite o código de recuperação enviado para {email} e sua nova senha.',
  'reset_password_code_submit': 'Verificar código e atualizar senha',
  'update_password_title': 'Definir nova senha',
  'update_password_too_short': 'A senha precisa ter pelo menos 6 caracteres.',
  'update_password_success': 'Sua senha foi atualizada com sucesso!',
  'update_password_prompt': 'Defina uma nova senha para a sua conta.',
  'update_password_new_label': 'Nova senha',
  'update_password_submit': 'Atualizar senha',
  // --- Groups: list ---
  'groups_title': 'Grupos',
  'groups_empty_title': 'Você ainda não faz parte de nenhum grupo.',
  'groups_empty_subtitle':
      'Toque no botão + no canto inferior direito para criar seu primeiro grupo.',
  'groups_tap_for_details': 'Toque para ver os detalhes do grupo',
  'groups_create_new_group': 'Criar grupo',
  'groups_name_label': 'Nome do grupo',
  'groups_create_button': 'Criar',
  // --- Groups: detail screen ---
  'groups_participants_suffix': 'participantes',
  'groups_participants_load_error':
      'Não foi possível carregar os participantes',
  'groups_chat_tooltip': 'Chat do grupo',
  'groups_invite_friend_tooltip': 'Convidar amigo',
  'groups_paid_verb': 'pagou',
  'groups_tab_pending': 'Pendentes',
  'groups_tab_active': 'Ativas',
  'groups_tab_archived': 'Arquivo',
  'groups_no_transactions':
      'Ainda não há transações. Adicione a primeira despesa.',
  'groups_empty_pending': 'Nenhuma despesa aguardando aprovação.',
  'groups_empty_active': 'Nenhuma despesa ativa.',
  'groups_empty_archived': 'Nenhuma despesa arquivada.',
  'groups_add_expense': 'Adicionar despesa',
  'groups_archive_all_button': 'Arquivar tudo',
  'groups_action_failed': 'Não foi possível concluir a ação. Tente novamente.',
  'groups_archive_failed':
      'Não foi possível arquivar a despesa. Tente novamente.',
  'groups_status_payer': 'Pagador',
  'groups_status_pending': 'Aguardando aprovação',
  'groups_status_approved_self': 'Aprovada',
  'groups_status_active_debt': 'Dívida ativa',
  'groups_status_payment_pending_payer': 'Aguardando confirmação do pagamento',
  'groups_status_payment_reported': 'Pagamento informado',
  'groups_status_settled': 'Pago',
  'groups_status_rejected': 'Recusada',
  'groups_action_approve': 'Aprovar',
  'groups_action_mark_paid': 'Marcar como pago',
  'groups_action_confirm_payment': 'Confirmar pagamento',
  'groups_balance_title': 'Saldo do grupo',
  'groups_no_active_debt': 'Nenhuma dívida ativa.',
  'groups_creditor_label': 'A receber',
  'groups_debtor_label': 'Deve',
  'groups_filter_payer_label': 'Pago por',
  // --- Groups: info screen ---
  'group_info_change_picture': 'Alterar a foto do grupo',
  'group_info_group_picture': 'Foto do grupo',
  'group_info_admin': 'Administrador',
  'group_info_remove_member': 'Remover participante',
  'group_info_this_member': 'este participante',
  'group_info_remove_member_title': 'Remover participante?',
  'group_info_remove_member_body':
      '{member} vai perder o acesso a este grupo e ao chat dele.',
  'group_info_remove': 'Remover',
  'group_info_title': 'Informações do grupo',
  'group_info_leave_button': 'Sair do grupo',
  'group_info_delete_button': 'Excluir grupo',
  'group_info_leave_confirm':
      'Tem certeza de que deseja sair de "%s"? Suas despesas anteriores continuarão no grupo.',
  'group_info_leave_confirm_button': 'Sair',
  'group_info_delete_confirm':
      'Tem certeza de que deseja excluir permanentemente "%s" e todos os dados de despesas e participantes? Esta ação não pode ser desfeita.',
  // --- Groups: chat ---
  'groups_chat_title': 'Chat de {group}',
  'groups_chat_suffix': 'Chat',
  'groups_chat_empty': 'Ainda não há mensagens. Escreva a primeira!',
  'groups_chat_input_hint': 'Escreva uma mensagem...',
  // --- Groups: add expense sheet ---
  'groups_scan_receipt': 'Escanear recibo',
  'groups_custom_exchange_rate': 'Taxa de câmbio personalizada',
  'groups_pro_tool_coming_soon': 'Esta ferramenta Pro chega em breve.',
  'dashboard_custom_rate_coming_soon':
      'O editor de taxa personalizada chega em breve.',
  'groups_expense_desc_label': 'Para quê?',
  'groups_total_amount_label': 'Valor total',
  'groups_split_equal': 'Igual (=)',
  'groups_split_percentage': 'Porcentagem (%)',
  'groups_split_exact': 'Valor',
  'groups_split_for_whom': 'Para quem é esta despesa?',
  'groups_auto_badge': 'auto',
  'groups_expense_validation_generic':
      'Informe dados válidos e selecione pelo menos 1 pessoa.',
  'groups_percentage_validation':
      'No máximo 1 pessoa pode ficar sem porcentagem, e o total precisa somar 100.',
  'groups_percentage_total_validation': 'As porcentagens precisam somar 100.',
  'groups_exact_validation':
      'No máximo 1 pessoa pode ficar sem valor, e o total precisa ser igual ao valor da despesa.',
  // --- Groups: invite friend modal ---
  'groups_invited_snackbar': 'Convite enviado!',
  'groups_invite_modal_title': 'Convidar amigo para o grupo',
  'groups_invite_search_hint': 'Pesquisar entre seus amigos',
  'groups_no_friends_to_invite': 'Você não tem amigos para convidar.',
  'groups_no_friends_hint': 'Primeiro adicione amigos na aba Social.',
  'groups_no_search_match': 'Nenhum amigo corresponde à sua busca.',
  // --- Debts ---
  'debts_back_tooltip': 'Voltar',
  'debts_title': 'Dívidas',
  'debts_tab_mine': 'Minhas dívidas',
  'debts_tab_owed_to_me': 'Devem a mim',
  'debts_tab_approvals': 'Aprovações',
  'debts_tab_summary': 'Resumo',
  'debts_user_info_unavailable':
      'Não foi possível obter as informações do usuário.',
  'debts_not_in_any_group': 'Você ainda não faz parte de nenhum grupo.',
  'debts_owed_by_prefix': 'A receber por',
  'debts_owed_to_me_prefix': 'Deve a nós',
  'debts_no_active_debt': 'Você não tem dívidas ativas.',
  'debts_no_active_credit': 'Ninguém deve nada a você no momento.',
  'debts_total_debt_label': 'Dívida total',
  'debts_total_credit_label': 'Crédito total',
  'debts_awaiting_my_approval': 'Aguardando sua aprovação',
  'debts_no_awaiting_my_approval': 'Nenhuma dívida aguardando sua aprovação.',
  'debts_awaiting_other_approval': 'Aguardando a aprovação da outra parte',
  'debts_no_awaiting_other_approval':
      'Nenhuma dívida aguardando a aprovação da outra parte.',
  'debts_reject_tooltip': 'Recusar',
  'debts_no_settlement': 'Nenhuma dívida a acertar.',
  'debts_settled_debt_subtitle': 'Dívida quitada',
  'debts_total_prefix': 'Total',
  'debts_filter_group_label': 'Grupo',
  'debts_clear_filters_tooltip': 'Limpar filtros',
  // --- Notifications ---
  'notifications_login_required': 'Entre para ver suas notificações.',
  'notifications_empty_title': 'Você ainda não tem notificações.',
  'notifications_empty_subtitle':
      'As novidades de despesas e aprovações dos seus grupos aparecerão aqui.',
  // --- Notifications: dynamically built messages ---
  'notif_new_expense_title': 'Nova despesa',
  'notif_new_expense_message':
      '{sender} adicionou você à despesa "{desc}" no grupo {group}. Valor: {amount}. Aguardando sua aprovação.',
  'notif_payment_confirmation_title': 'Pagamento informado',
  'notif_payment_confirmation_message':
      '{sender} informou um pagamento de "{desc}" no grupo {group}.',
  'notif_debt_approved_title': 'Dívida aprovada',
  'notif_debt_approved_message':
      '{sender} aprovou a dívida de "{desc}" no grupo {group}.',
  'notif_debt_rejected_title': 'Dívida recusada',
  'notif_debt_rejected_message':
      '{sender} recusou a dívida de "{desc}" no grupo {group}.',
  'notif_debt_settled_title': 'Pagamento confirmado',
  'notif_debt_settled_message':
      '{sender} confirmou seu pagamento de "{desc}" no grupo {group}. A dívida está quitada.',
  'notif_default_group': 'Um grupo',
  'notif_default_user': 'Um usuário',
  'notif_default_expense_desc': 'despesa',
  // --- Profile ---
  'profile_title': 'Perfil',
  'profile_email_missing': 'E-mail não adicionado',
  'profile_user_fallback': 'Usuário do Splixa',
  'profile_manage_subscription': 'Gerenciar assinatura',
  'profile_upgrade_pro': 'Assinar o Pro',
  'profile_settings': 'Configurações',
  'profile_invite_friends': 'Convidar amigos',
  'profile_download_monthly_report': 'Baixar relatório mensal',
  'profile_download_monthly_report_pro': 'Baixar relatório mensal · Pro',
  'profile_contact_us': 'Fale conosco',
  'profile_support_placeholder': 'O contato do suporte ficará disponível aqui.',
  'profile_terms': 'Termos',
  'profile_privacy': 'Privacidade',
  'profile_choose_picture': 'Escolher foto de perfil',
  'profile_tap_choose_photo': 'Toque para escolher uma foto',
  'profile_username_label': 'Nome de usuário',
  'profile_email_label': 'E-mail',
  'profile_dark_mode': 'Modo escuro',
  'profile_link_failed': 'Não foi possível abrir esta página.',
  'profile_delete_dialog_title': 'Excluir conta e dados?',
  'profile_delete_dialog_body':
      'Esta ação é permanente. Seu perfil, suas transações pessoais, suas mensagens e suas conexões sociais serão excluídos. O histórico financeiro compartilhado é mantido de forma anônima para que os saldos dos outros participantes continuem corretos.',
  'profile_delete_group_warning':
      'Se você administra um grupo com outros participantes, é preciso excluí-lo ou transferir a propriedade antes.',
  'profile_delete_type_confirm': 'Digite DELETE para confirmar:',
  'profile_delete_transfer_first':
      'Antes, exclua ou transfira os grupos que você administra:',
  'profile_delete_failed': 'Não foi possível excluir a conta. Tente novamente.',
  'profile_delete_invalid_response':
      'O serviço de exclusão retornou uma resposta inválida.',
  'profile_deleting': 'Excluindo…',
  'profile_delete_permanently': 'Excluir permanentemente',
  'profile_membership_pro': 'PRO',
  'profile_membership_standard': 'PADRÃO',
  'profile_unknown_username': '@desconhecido',
  'profile_edit_tile': 'Editar perfil',
  'profile_currency_tile': 'Moeda',
  'profile_change_password_tile': 'Alterar senha',
  'profile_download_report_tile': 'Baixar relatório mensal (PDF)',
  'profile_pdf_error': 'Não foi possível gerar o PDF: %s',
  'profile_logout': 'Sair',
  'profile_danger_zone': 'Zona de risco',
  'profile_delete_account_data': 'Excluir conta e dados',
  'profile_delete_account_title': 'Excluir conta',
  'profile_delete_account_confirm':
      'Tem certeza de que deseja excluir permanentemente sua conta e todos os seus dados? Esta ação não pode ser desfeita.',
  'profile_avatar_url_label': 'URL do avatar (opcional)',
  'profile_update_success': 'Perfil atualizado com sucesso.',
  'profile_bio_label': 'Bio',
  'profile_bio_hint': 'Conte um pouco sobre você...',
  'profile_bio_empty': 'Nenhuma bio adicionada ainda.',
  // --- Profile: PDF export ---
  'pdf_title': 'Relatório mensal - %s',
  'pdf_total_income': 'Receita total',
  'pdf_total_expense': 'Despesa total',
  'pdf_net_balance': 'Saldo líquido',
  'pdf_transaction_details': 'Detalhes das transações',
  'pdf_no_transactions': 'Nenhuma transação neste mês.',
  'pdf_header_type': 'Tipo',
  // --- Social ---
  'social_title': 'Social',
  'social_request_sent_snackbar': 'Convite enviado!',
  'social_user_not_found': 'Usuário não encontrado.',
  'social_search_results_header': 'Resultados da busca',
  'social_add_friend_tooltip': 'Adicionar amigo',
  'social_search_hint': 'Pesquise usuários por @usuario',
  'social_search_tooltip': 'Pesquisar usuários',
  'social_no_friends_title': 'Você ainda não tem amigos.',
  'social_no_friends_subtitle':
      'Use a busca acima para encontrar um nome de usuário e enviar um pedido de amizade.',
  'social_request_sent_prefix': 'Pedido enviado: %s',
  'social_pending_status': 'Pendente...',
  'social_incoming_request_prefix': 'Pedido para você: %s',
  'social_friend_prefix': 'Amigo: %s',
  'social_default_chat_title': 'Amigo',
  // --- Social: other user profile ---
  'other_profile_title': 'Perfil do usuário',
  'other_profile_unknown': 'Desconhecido',
  'other_profile_no_shared_groups': 'Nenhum grupo em comum',
  'other_profile_shared_groups_count': 'Vocês têm %s grupos em comum',
  'other_profile_send_message': 'Enviar mensagem',
  // --- Subscriptions: paywall ---
  'paywall_title': 'Assine o Splixa Pro',
  'paywall_subtitle':
      'Crie grupos ilimitados, acesse todas as estatísticas e aproveite sua liberdade financeira!',
  'paywall_no_packages': 'Nenhum pacote disponível no momento.',
  'paywall_restore_purchases': 'Restaurar compras',
  'paywall_restore_success': 'Compras restauradas!',
  'paywall_processing_purchase': 'Processando a compra...',
  'paywall_welcome_pro': 'Boas-vindas ao Splixa Pro!',
  'paywall_purchase_failed': 'A operação foi cancelada ou falhou.',
  'paywall_benefit_unlimited_groups': 'Crie grupos ilimitados',
  'paywall_benefit_statistics': 'Acesse todas as estatísticas e relatórios',
  'paywall_benefit_freedom': 'Aproveite sua liberdade financeira',
  'paywall_no_packages_hint': 'Os pacotes aparecerão aqui em breve.',
  'paywall_footer_note': 'Você pode cancelar sua assinatura quando quiser.',
  // --- Friendly error messages ---
  'error_generic_short': 'Algo deu errado. Tente novamente.',
  'error_auth_generic': 'Ocorreu um problema. Tente novamente.',
  'error_google_cancelled':
      'O login com o Google foi cancelado ou o dispositivo não pôde ser verificado. Tente novamente.',
  'error_google_configuration':
      'O login com o Google não está configurado corretamente.',
  'error_google_unavailable':
      'O login com o Google não está disponível neste dispositivo.',
  'error_google_timeout': 'O login com o Google expirou. Tente novamente.',
  'error_google_failed':
      'Não foi possível concluir o login com o Google. Tente novamente.',
  'error_invalid_credentials': 'Nome de usuário ou senha incorretos.',
  'error_email_not_confirmed':
      'Seu endereço de e-mail ainda não foi verificado.',
  'error_email_already_registered': 'Já existe uma conta com este e-mail.',
  'error_password_too_short': 'A senha é muito curta. Escolha uma mais longa.',
  'error_rate_limited': 'Tentativas demais. Tente de novo daqui a pouco.',
  'error_duplicate_record': 'Este registro já existe.',
  'error_forbidden': 'Você não tem permissão para fazer isso.',
  'error_not_found': 'Registro não encontrado.',
  'error_server_generic':
      'Houve um problema na comunicação com o servidor. Tente novamente.',
  // --- Main scaffold (bottom nav) ---
  'nav_dashboard': 'Painel',
  'nav_debts': 'Dívidas',
  'nav_groups': 'Grupos',
  'nav_social': 'Social',
  'nav_profile': 'Perfil',
  // --- Router fallback titles (used when navigation `extra` is absent) ---
  'route_fallback_group_detail': 'Detalhes do grupo',
  'route_fallback_group_info': 'Informações do grupo',
  'route_fallback_group': 'Grupo',
  'route_fallback_chat': 'Chat',
  // --- Activity feed descriptions ---
  'activity_someone': 'Alguém',
  'activity_a_group': 'Um grupo',
  'activity_became_friends': 'Você e {name} agora são amigos.',
  'activity_added_expense':
      'Você adicionou uma despesa de {amount} em {group}.',

  // --- Onboarding ---
  'onboarding_skip': 'Pular',
  'onboarding_continue': 'Continuar',
  'onboarding_start_free': 'Começar grátis',
  'onboarding_no_card':
      'Não precisa de cartão. Assine o Pro só quando ele economizar seu tempo.',
  'onboarding_persistence_error':
      'Não conseguimos salvar sua escolha. Tente novamente.',
  'onboarding_p1_eyebrow': 'PESSOAL + COMPARTILHADO',
  'onboarding_p1_title': 'Controle o seu. Divida em grupo.',
  'onboarding_p1_description':
      'Seu orçamento e todas as despesas compartilhadas em um só lugar.',
  'onboarding_p1_proof_1': 'Orçamento pessoal',
  'onboarding_p1_proof_2': 'Despesas de grupo',
  'onboarding_p2_eyebrow': 'SEM CONTA CONSTRANGEDORA',
  'onboarding_p2_title': 'Divida com justiça. Acerte com clareza.',
  'onboarding_p2_description':
      'Igual, percentual ou exato — todos sabem o próximo passo.',
  'onboarding_p2_proof_1': 'Divisões flexíveis',
  'onboarding_p2_proof_2': 'Aprovações claras',
  'onboarding_p3_eyebrow': 'CONTAS QUE FECHAM',
  'onboarding_p3_title': 'Viaje livre. Preserve cada taxa.',
  'onboarding_p3_description':
      'Valores originais e taxas fixadas mantêm o saldo de ontem correto.',
  'onboarding_p3_proof_1': 'Taxas travadas',
  'onboarding_p3_proof_2': 'Histórico confiável',
  'onboarding_p4_eyebrow': 'COMEÇAR É GRÁTIS',
  'onboarding_p4_title': 'Comece grátis. Use Pro quando valer a pena.',
  'onboarding_p4_description':
      'Libere captura rápida, análises profundas e relatórios avançados quando precisar.',
  'onboarding_p4_proof_1': 'Sem teste obrigatório',
  'onboarding_p4_proof_2': 'Cancele quando quiser',

  // --- Subscriptions: paywall copy ---
  'paywall_appbar_title': 'Splixa Pro',
  'paywall_close': 'Fechar',
  'paywall_hero_title':
      'Transforme a gestão do dinheiro numa tarefa de dois minutos',
  'paywall_hero_subtitle':
      'O essencial do Splixa continua grátis. Assine o Pro quando automação, controle e respostas mais profundas valerem mais do que o tempo que economizam.',
  'paywall_benefits_title': 'O que o Pro libera',
  'paywall_benefit_1_title': 'Grupos ilimitados',
  'paywall_benefit_1_body':
      'Mantenha cada viagem, casa e projeto ativos sem limite de grupos.',
  'paywall_benefit_2_title': 'Veja os padrões por trás dos gastos',
  'paywall_benefit_2_body':
      'Explore a distribuição por categoria e os padrões de atividade num relance.',
  'paywall_benefit_3_title': 'Exporte relatórios mensais caprichados',
  'paywall_benefit_3_body':
      'Transforme seus registros pessoais em um PDF pronto para compartilhar com um toque.',
  'paywall_benefit_4_title':
      'Prévia do roadmap: menos digitação, mais controle',
  'paywall_benefit_4_body':
      'Escaneamento de recibos e taxas de câmbio personalizadas vêm a seguir.',
  'paywall_choose_plan': 'Escolha seu plano',
  'paywall_best_value': 'MELHOR CUSTO',
  'paywall_continue_free': 'Agora não — continuar no plano grátis',
  'paywall_restore': 'Restaurar compras',
  'paywall_restore_restored': 'Seu acesso Pro foi restaurado.',
  'paywall_restore_none':
      'Nenhuma compra Pro ativa foi encontrada nesta conta da loja.',
  'paywall_welcome_message': 'Boas-vindas ao Splixa Pro.',
  'paywall_purchase_failed_message':
      'A compra foi cancelada ou não pôde ser concluída.',
  'paywall_no_packages_available':
      'Os planos estão temporariamente indisponíveis. Tente novamente.',
  'paywall_retry': 'Tentar de novo',
  'paywall_terms_link': 'Termos de Uso',
  'paywall_privacy_link': 'Política de Privacidade',
  'paywall_store_disclosure':
      'O pagamento é cobrado na sua conta da loja. Gerencie ou cancele nas configurações de assinatura da App Store ou do Google Play.',
  'paywall_link_failed': 'Não foi possível abrir a página.',
  'paywall_plan_annual': 'Pro anual',
  'paywall_plan_monthly': 'Pro mensal',
  'paywall_period_annual': '/ ano',
  'paywall_period_monthly': '/ mês',
  'paywall_monthly_equivalent': '{price} equivalente por mês',
  'paywall_continue_with_plan': 'Continuar com o {plan}',
  'paywall_renewal_annual':
      '{price} é cobrado agora. A assinatura é renovada anualmente até ser cancelada.',
  'paywall_renewal_monthly':
      '{price} é cobrado agora. A assinatura é renovada mensalmente até ser cancelada.',

  // --- Relative time (activity feed, chat, notifications) ---
  'time_just_now': 'Agora mesmo',
  'time_minutes_ago': 'há {count} min',
  'time_hours_ago': 'há {count} h',
  'time_days_ago': 'há {count} d',

  // --- Profile sections & language picker ---
  'profile_section_account': 'Conta',
  'profile_section_subscription': 'Assinatura',
  'profile_section_preferences': 'Preferências',
  'profile_section_support': 'Suporte',
  'profile_section_legal': 'Jurídico',
  'language_picker_title': 'Escolha seu idioma',
  'error_free_group_limit':
      'O plano grátis inclui até 2 grupos. Assine o Pro para grupos ilimitados.',
  'error_free_personal_expense_limit':
      'Você atingiu 50 despesas pessoais neste mês. Assine o Pro para continuar.',
  'error_not_authenticated': 'Entre novamente para continuar.',
  'pro_tools_title': 'Ferramentas Pro',
  'pro_tools_locked': 'Libere todas as ferramentas avançadas com o Splixa Pro.',
  'pro_server_verified': 'Acesso Pro verificado com segurança',
  'pro_sync_pending': 'Sincronizando acesso Pro',
  'pro_biometric_lock': 'Bloqueio biométrico',
  'pro_biometric_lock_body':
      'Exija Face ID, digital ou segurança do aparelho ao voltar ao Splixa.',
  'pro_biometric_unavailable': 'A autenticação biométrica não está disponível.',
  'pro_app_lock_reason': 'Autentique-se para abrir suas finanças no Splixa',
  'pro_app_locked_title': 'Splixa está bloqueado',
  'pro_app_locked_body':
      'Autentique-se para proteger suas informações financeiras.',
  'pro_unlock': 'Desbloquear',
  'pro_home_widget': 'Widget de adição rápida',
  'pro_home_widget_body': 'Registre uma despesa direto da tela inicial.',
  'pro_home_widget_manual':
      'Adicione o widget do Splixa pela galeria de widgets.',
  'pro_custom_categories': 'Categorias personalizadas',
  'pro_category_add': 'Adicionar categoria',
  'pro_category_name': 'Nome da categoria',
  'pro_category_emoji': 'Emoji',
  'pro_categories_empty': 'Crie categorias reutilizáveis com seu emoji e cor.',
  'pro_recurring_expenses': 'Despesas recorrentes',
  'pro_recurring_add': 'Adicionar despesa recorrente',
  'pro_recurring_name': 'Nome da despesa',
  'pro_recurring_empty':
      'Automatize aluguel, assinaturas e outros custos repetidos.',
  'pro_frequency_weekly': 'Semanal',
  'pro_frequency_monthly': 'Mensal',
  'pro_export_csv': 'Exportar CSV completo',
  'pro_advanced_analytics': 'Análises avançadas e períodos personalizados',
  'pro_custom_rate_title': 'Fixar câmbio personalizado',
  'pro_custom_rate_label': 'TRY por 1 {currency}',
  'pro_custom_rate_helper':
      'Esta taxa é salva com a despesa e nunca muda no histórico.',
  'pro_custom_rate_try_identity': 'TRY já usa uma taxa fixa de 1:1.',
  'pro_receipt_camera': 'Escanear com a câmera',
  'pro_receipt_gallery': 'Escolher da galeria',
  'pro_receipt_ready': 'Recibo pronto · revise os campos',
  'pro_receipt_view': 'Ver recibo',
  'pro_receipt_review_required':
      'As sugestões do OCR foram preenchidas. Revise antes de salvar.',
  'pro_receipt_upload_failed':
      'A despesa foi salva, mas o recibo não pôde ser anexado.',
  'pro_receipt_invalid_image': 'Não foi possível ler esta imagem.',
  'pro_ocr_mobile_only': 'O scanner está disponível no Android e iOS.',
  'pro_send_reminder': 'Lembrar',
  'pro_reminder_sent': 'Um lembrete gentil foi enviado.',
  'pro_trip_summary': 'Resumo de viagem compartilhável',
  'pro_trip_privacy_note':
      'A imagem contém apenas totais, sem saldos privados.',
  'pro_trip_share': 'Compartilhar resumo',
  'statistics_current_month': 'Mês atual',
  'paywall_free_trial': '7 DIAS GRÁTIS',
  'paywall_plan_lifetime': 'Pro vitalício',
  'paywall_period_once': 'pagamento único',
  'paywall_lifetime_disclosure':
      '{price} é cobrado uma vez. Não é assinatura e não renova.',
};
