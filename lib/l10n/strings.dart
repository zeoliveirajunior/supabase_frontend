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
    // Backend (ad.fn_message)
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
