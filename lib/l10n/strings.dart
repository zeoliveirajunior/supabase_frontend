/// Textos do app em pt-BR e traducao das chaves de erro do backend.
///
/// As chaves de erro vem de `ad.fn_message` (ver dicionario do repositorio
/// supabase, aba Functions > errors). Chave sem traducao cai em UNKNOWN.
abstract final class Strings {
  static const appName = 'Odonto';
  static const tagline = 'Gestão da sua clínica, do agendamento ao prontuário.';

  // Login
  static const loginTitle = 'Bem-vindo de volta';
  static const loginSubtitle = 'Entre para acessar sua clínica.';
  static const email = 'E-mail';
  static const emailHint = 'voce@clinica.com.br';
  static const password = 'Senha';
  static const passwordHint = 'Sua senha';
  static const signIn = 'Entrar';
  static const forgotPassword = 'Esqueci minha senha';
  static const noAccount = 'Ainda não tem conta?';
  static const createAccount = 'Criar conta';
  static const comingSoon = 'Em breve.';
  static const showPassword = 'Mostrar senha';
  static const hidePassword = 'Ocultar senha';

  // Selecao de empresa / filial
  static const selectBranchTitle = 'Onde você vai trabalhar hoje?';
  static const selectBranchSubtitle =
      'Você tem acesso a mais de uma filial. Escolha a empresa e a filial para continuar.';
  static const company = 'Empresa';
  static const branch = 'Filial';
  static const searchHint = 'Pesquisar...';
  static const noResults = 'Nenhum resultado.';
  static const continueLabel = 'Continuar';
  static const cancel = 'Cancelar';
  static const switchBranch = 'Trocar filial';
  static const mainBranch = 'Matriz';
  static const admin = 'Administrador';

  // Sem empresa
  static const noCompanyTitle = 'Você ainda não tem uma empresa';
  static const noCompanySubtitle =
      'Crie a sua clínica para começar ou peça a um administrador para vincular você.';
  static const blockedTitle = 'Acesso indisponível';
  static const blockedSubtitle =
      'Seus vínculos estão sem acesso no momento. Fale com o administrador da empresa.';
  static const createCompany = 'Criar empresa';

  // Shell
  static const dashboard = 'Dashboard';
  static const users = 'Usuários';
  static const profiles = 'Perfis';
  static const logs = 'Logs';
  static const signOut = 'Sair';
  static const dashboardEmptyTitle = 'Seu painel está quase pronto';
  static const dashboardEmptySubtitle =
      'Os indicadores da clínica aparecem aqui assim que houver dados.';

  // Genericos das telas internas
  static const statusActive = 'Ativo';
  static const statusBlocked = 'Bloqueado';
  static const statusInactive = 'Inativo';
  static const allStatuses = 'Todas as situações';
  static const loadError = 'Não foi possível carregar.';
  static const retry = 'Tentar de novo';
  static const confirm = 'Confirmar';
  static const save = 'Salvar';
  static const edit = 'Editar';
  static const remove = 'Remover';
  static const search = 'Buscar';
  static const name = 'Nome';
  static const level = 'Nível';
  static const status = 'Situação';
  static const actions = 'Ações';
  static const profile = 'Perfil';
  static const user = 'Usuário';
  static const showInactive = 'Mostrar inativos';
  static const savedSuccess = 'Salvo com sucesso.';
  static const removedSuccess = 'Vínculo removido.';
  static const previousPage = 'Página anterior';
  static const nextPage = 'Próxima página';
  static const adminOnlyTitle = 'Área de administradores';
  static const adminOnlySubtitle =
      'Somente administradores da empresa podem gerenciar usuários.';
  static String totalRecords(int n) => n == 1 ? '1 registro' : '$n registros';
  static String pageOf(int page, int count) => 'Página $page de $count';

  // Perfis de acesso
  static const profilesTitle = 'Perfis de acesso';
  static const profilesSubtitle =
      'Níveis de acesso que os usuários recebem em cada filial. Nível 100 é administrador da empresa.';
  static const newProfile = 'Novo perfil';
  static const editProfile = 'Editar perfil';
  static const profileName = 'Nome do perfil';
  static const profileLevel = 'Nível de acesso';
  static const profileLevelHint =
      '0 a 100. Quem tem nível 100 administra a empresa: usuários, perfis e filiais.';
  static const profileActive = 'Perfil ativo';
  static const noProfiles = 'Nenhum perfil cadastrado.';
  static const levelAdmin = 'Administrador';
  static const levelUser = 'Usuário';
  static String profileUsers(int n) => n == 1 ? '1 usuário' : '$n usuários';

  // Usuarios da empresa
  static const usersTitle = 'Usuários';
  static const usersSubtitle =
      'Quem acessa a empresa, em quais filiais e com qual perfil.';
  static const linkUser = 'Vincular usuário';
  static const editUser = 'Editar usuário';
  static const userEmailHelp =
      'A pessoa precisa ter criado a conta no app com este e-mail.';
  static const userAccessTitle = 'Acesso por filial';
  static const userNoAccess = 'Sem acesso';
  static const userBranchesRequired =
      'Informe pelo menos uma filial com perfil.';
  static const blockReason = 'Motivo do bloqueio';
  static const lastLogin = 'Último acesso';
  static const never = 'Nunca';
  static const unlinkUser = 'Remover vínculo';
  static const noUsers = 'Nenhum usuário encontrado.';
  static const searchUsersHint = 'Nome ou e-mail';
  static const allBranches = 'Todas as filiais';
  static const userCode = 'Código';
  static String unlinkConfirm(String name) =>
      'Remover $name da empresa? A pessoa perde o acesso a todas as filiais.';

  // Logs de acesso
  static const logsTitle = 'Logs de acesso';
  static const logsSubtitle =
      'Quem entrou, quando, por qual app e em qual filial.';
  static const logsOwnOnly = 'Você vê apenas os seus próprios acessos.';
  static const customPeriod = 'Período';
  static const app = 'App';
  static const allApps = 'Todos os apps';
  static const allUsers = 'Todos os usuários';
  static const dateTime = 'Data e hora';
  static const device = 'Dispositivo';
  static const ip = 'IP';
  static const noLogs = 'Nenhum acesso no período.';
  static const noBranch = 'Sem filial';
  static String lastDays(int n) => 'Últimos $n dias';

  // Navegacao e permissoes
  static const adminMenu = 'Administração';
  static const openAdminMenu = 'Abrir ou fechar o menu de administração';
  static const noPermissionTitle = 'Sem acesso a esta tela';
  static const noPermissionSubtitle =
      'Peça a um administrador para liberar esta tela no seu perfil.';
  static const permRead = 'Ler';
  static const permCreate = 'Criar';
  static const permUpdate = 'Alterar';
  static const screen = 'Tela';
  static const screensTitle = 'Telas e permissões';
  static const adminAllScreens =
      'Nível 100 é administrador: acesso total a todas as telas, sem precisar marcar.';
  static const allScreens = 'Todas as telas';
  static const noScreens = 'Nenhuma tela liberada';
  static String screensCount(int n) => n == 1 ? '1 tela' : '$n telas';
  static const close = 'Fechar';

  // Cadastro de usuario (Edge Function user-create)
  static const newUser = 'Novo usuário';
  static const newUserHelp =
      'Se o e-mail já tiver conta no app, só o vínculo com a empresa é criado.';
  static const fullName = 'Nome completo';
  static const cpf = 'CPF';
  static const phone = 'Telefone';
  static const mobile = 'Celular';
  static const initialPassword = 'Senha inicial';
  static const confirmPassword = 'Confirmar senha';
  static const passwordsDiffer = 'As senhas não conferem.';
  static const userCreated = 'Usuário cadastrado.';

  // Log de atividades
  static const activitiesTab = 'Atividades';
  static const accessTab = 'Acessos';
  static const allScreensFilter = 'Todas as telas';
  static const action = 'Ação';
  static const allActions = 'Todas as ações';
  static const summary = 'O que aconteceu';
  static const details = 'Detalhes';
  static const searchEventsHint = 'Resumo, registro ou chave';
  static const noEvents = 'Nenhuma atividade no período.';

  // Validacao de formularios
  static const required = 'Campo obrigatório.';
  static const invalidEmail = 'Informe um e-mail válido.';
  static const invalidCpf = 'CPF inválido.';
  static const invalidCnpj = 'CNPJ inválido.';
  static const invalidCpfCnpj = 'CPF/CNPJ inválido.';
  static const invalidPhone = 'Telefone inválido.';
  static const invalidDate = 'Data inválida.';
  static String minLength(int n) => 'Mínimo de $n caracteres.';

  static const Map<String, String> _errors = {
    // Auth (Supabase Auth)
    'AUTH_INVALID_CREDENTIALS': 'E-mail ou senha inválidos.',
    'AUTH_EMAIL_NOT_CONFIRMED': 'Confirme seu e-mail antes de entrar.',
    'AUTH_USER_BANNED': 'Este usuário está suspenso.',
    'AUTH_RATE_LIMIT':
        'Muitas tentativas. Aguarde um instante e tente de novo.',
    'AUTH_ERROR': 'Não foi possível entrar. Tente novamente.',
    // Backend: sessao (ad.fn_message)
    'VERSION_MISMATCH': 'Seu app está desatualizado. Atualize para continuar.',
    'SESSION_USER_NOT_FOUND':
        'Usuário não encontrado. Fale com o administrador.',
    'SESSION_USER_INACTIVE': 'Seu usuário está inativo.',
    'SESSION_USER_BLOCKED': 'Seu usuário está bloqueado. {Reason}',
    'SESSION_COMPANY_BLOCKED': 'Empresa bloqueada pela plataforma. {Reason}',
    'SESSION_COMPANY_INACTIVE': 'Empresa inativa.',
    'SESSION_USER_COMPANY_BLOCKED':
        'Seu acesso a esta empresa está bloqueado. {Reason}',
    'SESSION_USER_COMPANY_INACTIVE': 'Seu acesso a esta empresa está inativo.',
    'SESSION_WITHOUT_PROFILE':
        'Você não tem perfil em nenhuma filial ativa desta empresa.',
    // Backend: perfis de acesso
    'ACCESS_PROFILE_ACTION_INVALID': 'Ação inválida.',
    'ACCESS_PROFILE_COMPANY_REQUIRED': 'Empresa não informada.',
    'ACCESS_PROFILE_FORBIDDEN':
        'Somente administradores da empresa podem alterar perfis.',
    'ACCESS_PROFILE_NAME_REQUIRED': 'Informe o nome do perfil.',
    'ACCESS_PROFILE_NAME_IN_USE': 'Já existe um perfil chamado {Name}.',
    'ACCESS_PROFILE_LEVEL_INVALID': 'O nível deve estar entre 0 e 100.',
    'ACCESS_PROFILE_REQUIRED': 'Perfil não informado.',
    'ACCESS_PROFILE_NOT_FOUND': 'Perfil não encontrado.',
    'ACCESS_PROFILE_STATUS_INVALID': 'Situação inválida.',
    'ACCESS_PROFILE_LAST_ADMIN':
        'A empresa ficaria sem administrador ativo. Mantenha ao menos um.',
    'ACCESS_PROFILE_LIST_COMPANY_REQUIRED': 'Empresa não informada.',
    'ACCESS_PROFILE_LIST_FORBIDDEN': 'Você não tem acesso a esta empresa.',
    // Backend: usuarios da empresa
    'COMPANY_USER_ACTION_INVALID': 'Ação inválida.',
    'COMPANY_USER_COMPANY_REQUIRED': 'Empresa não informada.',
    'COMPANY_USER_FORBIDDEN':
        'Somente administradores da empresa podem gerenciar usuários.',
    'COMPANY_USER_EMAIL_REQUIRED': 'Informe o e-mail do usuário.',
    'COMPANY_USER_EMAIL_NOT_FOUND':
        'Não existe conta com o e-mail {Email}. A pessoa precisa criar a conta no app antes.',
    'COMPANY_USER_ALREADY_LINKED': 'Este usuário já está vinculado à empresa.',
    'COMPANY_USER_USER_REQUIRED': 'Usuário não informado.',
    'COMPANY_USER_NOT_FOUND': 'Usuário não encontrado nesta empresa.',
    'COMPANY_USER_STATUS_INVALID': 'Situação inválida.',
    'COMPANY_USER_BRANCHES_REQUIRED':
        'Informe pelo menos uma filial com perfil.',
    'COMPANY_USER_BRANCH_INVALID': 'Filial inválida: {Branch}.',
    'COMPANY_USER_PROFILE_INVALID': 'Perfil inválido: {Profile}.',
    'COMPANY_USER_LAST_ADMIN':
        'A empresa ficaria sem administrador ativo. Mantenha ao menos um.',
    'COMPANY_USER_LIST_COMPANY_REQUIRED': 'Empresa não informada.',
    'COMPANY_USER_LIST_FORBIDDEN':
        'Somente administradores podem ver os usuários da empresa.',
    'COMPANY_USER_LIST_STATUS_INVALID': 'Situação inválida.',
    // Backend: filiais e logs
    'BRANCH_LIST_COMPANY_REQUIRED': 'Empresa não informada.',
    'BRANCH_LIST_FORBIDDEN': 'Você não tem acesso a esta empresa.',
    'ACCESS_LOG_LIST_COMPANY_REQUIRED': 'Empresa não informada.',
    'ACCESS_LOG_LIST_FORBIDDEN': 'Você não tem acesso a esta empresa.',
    'ACCESS_LOG_LIST_APP_INVALID': 'Tipo de app inválido.',
    'ACCESS_LOG_LIST_PERIOD_INVALID':
        'A data inicial deve ser anterior à data final.',
    // Backend: telas, permissoes e log de atividades
    'SCREEN_LIST_FORBIDDEN': 'Sessão inválida. Entre de novo.',
    'ACCESS_PROFILE_SCREENS_INVALID': 'Lista de telas inválida.',
    'ACCESS_PROFILE_SCREEN_INVALID': 'Tela inválida: {Screen}.',
    'EVENT_LOG_LIST_COMPANY_REQUIRED': 'Empresa não informada.',
    'EVENT_LOG_LIST_FORBIDDEN': 'Você não tem acesso a esta empresa.',
    'EVENT_LOG_LIST_ACTION_INVALID': 'Tipo de ação inválido.',
    'EVENT_LOG_LIST_PERIOD_INVALID':
        'A data inicial deve ser anterior à data final.',
    // Edge Function user-create
    'USER_CREATE_COMPANY_REQUIRED': 'Empresa não informada.',
    'USER_CREATE_FORBIDDEN':
        'Somente administradores da empresa podem cadastrar usuários.',
    'USER_CREATE_EMAIL_REQUIRED': 'Informe o e-mail.',
    'USER_CREATE_EMAIL_INVALID': 'E-mail inválido: {Email}.',
    'USER_CREATE_NAME_REQUIRED': 'Informe o nome.',
    'USER_CREATE_PASSWORD_WEAK':
        'A senha inicial precisa ter ao menos 8 caracteres.',
    'USER_CREATE_AUTH_FAILED': 'Não foi possível criar a conta. {Detail}',
    'USER_CREATE_BACKEND_ERROR': 'Falha no cadastro. {Detail}',
    'USER_CREATE_UNAUTHORIZED': 'Sessão inválida. Entre de novo.',
    'USER_CREATE_METHOD': 'Requisição inválida.',
    'USER_CREATE_BODY_INVALID': 'Dados inválidos.',
    // App
    'NETWORK': 'Sem conexão. Verifique sua internet e tente de novo.',
    'UNKNOWN': 'Ocorreu um erro inesperado. Tente novamente.',
  };

  /// Traduz uma chave de erro, substituindo `{Param}` pelos parametros.
  /// Parametro vazio some junto com o espaco que o precede.
  static String errorMessage(
    String key,
    Map<String, dynamic> parameters, [
    String? fallback,
  ]) {
    var text = _errors[key] ?? fallback ?? _errors['UNKNOWN']!;
    parameters.forEach((name, value) {
      final v = value?.toString().trim() ?? '';
      text = text.replaceAll('{$name}', v);
    });
    return text.replaceAll(RegExp(r'\s*\{\w+\}'), '').trim();
  }
}
