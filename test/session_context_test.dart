import 'package:flutter_test/flutter_test.dart';
import 'package:odonto_app/features/session/domain/screen_codes.dart';
import 'package:odonto_app/features/session/domain/session_context.dart';

Map<String, dynamic> _json({
  int companies = 1,
  int branchesPerCompany = 1,
  List<Map<String, dynamic>> blocked = const [],
  int level = 100,
  List<Map<String, dynamic>>? permissions,
}) {
  return {
    'user': {
      'nr_user': 7,
      'vc_name': 'Ana Admin',
      'vc_email': 'ana@test.local',
      'vc_avatar_url': null,
      'it_level': 0,
      'dh_last_login': '2026-10-13T20:00:00+00:00',
    },
    'companies': [
      for (var c = 1; c <= companies; c++)
        {
          'nr_company': c,
          'vc_name': 'Clínica $c',
          'vc_cnpj': '11222333000181',
          'nr_company_user': 100 + c,
          'id_admin': c == 1 && level >= 100,
          'branches': [
            for (var b = 1; b <= branchesPerCompany; b++)
              {
                'nr_branch': b,
                'vc_name': b == 1 ? 'Matriz' : 'Filial $b',
                'vc_cnpj': null,
                'vc_timezone': 'America/Sao_Paulo',
                'id_main': b == 1,
                'it_level': c == 1 ? level : 10,
                'profiles': [
                  {
                    'nr_profile': 1,
                    'vc_name': 'Administrador',
                    'it_level': level,
                  },
                ],
                if (permissions != null) 'permissions': permissions,
              },
          ],
        },
    ],
    'blocked': blocked,
  };
}

void main() {
  test('parse completo do session_context', () {
    final ctx = SessionContext.fromJson(_json());
    expect(ctx.user.nrUser, 7);
    expect(ctx.user.initials, 'AA');
    expect(ctx.user.dhLastLogin, isNotNull);
    expect(ctx.companies.single.idAdmin, isTrue);
    expect(ctx.companies.single.branches.single.isAdmin, isTrue);
    expect(
      ctx.companies.single.branches.single.profiles.single.vcName,
      'Administrador',
    );
  });

  test('uma unica filial nao precisa de selecao', () {
    final ctx = SessionContext.fromJson(_json());
    expect(ctx.hasAccess, isTrue);
    expect(ctx.needsSelection, isFalse);
    expect(ctx.branches.single.label, 'Clínica 1 · Matriz');
  });

  test('mais de uma filial (mesma empresa) precisa de selecao', () {
    final ctx = SessionContext.fromJson(_json(branchesPerCompany: 2));
    expect(ctx.needsSelection, isTrue);
    expect(ctx.branches.length, 2);
  });

  test('mais de uma empresa precisa de selecao e find localiza', () {
    final ctx = SessionContext.fromJson(_json(companies: 2));
    expect(ctx.needsSelection, isTrue);
    final ref = ctx.find(2, 1);
    expect(ref, isNotNull);
    expect(ref!.company.vcName, 'Clínica 2');
    expect(ctx.find(9, 9), isNull);
  });

  test('primeiro acesso: sem empresa e sem bloqueio', () {
    final ctx = SessionContext.fromJson(_json(companies: 0));
    expect(ctx.hasAccess, isFalse);
    expect(ctx.isFirstAccess, isTrue);
  });

  test('bloqueado traduz o motivo com o parametro', () {
    final ctx = SessionContext.fromJson(
      _json(
        companies: 0,
        blocked: [
          {
            'nr_company': 5,
            'vc_name': 'Clínica X',
            'vc_reason_key': 'SESSION_USER_COMPANY_BLOCKED',
            'vc_reason': 'Inadimplência',
          },
          {
            'nr_company': 6,
            'vc_name': 'Clínica Y',
            'vc_reason_key': 'SESSION_WITHOUT_PROFILE',
            'vc_reason': null,
          },
        ],
      ),
    );
    expect(ctx.isFirstAccess, isFalse);
    expect(ctx.blocked.first.message, contains('Inadimplência'));
    expect(ctx.blocked.last.message, isNot(contains('{')));
  });

  test('numeros podem chegar como double', () {
    final json = _json();
    json['user']['nr_user'] = 7.0;
    expect(SessionContext.fromJson(json).user.nrUser, 7);
  });

  group('permissoes por tela', () {
    test('administrador pode tudo mesmo sem lista de permissoes', () {
      final ref = SessionContext.fromJson(_json()).branches.single;
      expect(ref.canRead(ScreenCodes.users), isTrue);
      expect(ref.canCreate(ScreenCodes.profiles), isTrue);
      expect(ref.canUpdate(ScreenCodes.logs), isTrue);
    });

    test('usuario comum: so o que veio em permissions; dashboard sempre', () {
      final ctx = SessionContext.fromJson(
        _json(
          level: 10,
          permissions: [
            {
              'uu_screen': 'u-1',
              'vc_code': 'USERS',
              'vc_name': 'Usuários',
              'id_read': true,
              'id_create': false,
              'id_update': false,
            },
            {
              'uu_screen': 'u-2',
              'vc_code': 'PROFILES',
              'vc_name': 'Perfis',
              'id_read': true,
              'id_create': true,
              'id_update': false,
            },
          ],
        ),
      );
      final ref = ctx.branches.single;
      expect(ref.isAdmin, isFalse);
      expect(ref.canRead(ScreenCodes.dashboard), isTrue);
      expect(ref.canRead(ScreenCodes.users), isTrue);
      expect(ref.canCreate(ScreenCodes.users), isFalse);
      expect(ref.canRead(ScreenCodes.profiles), isTrue);
      expect(ref.canCreate(ScreenCodes.profiles), isTrue);
      expect(ref.canUpdate(ScreenCodes.profiles), isFalse);
      expect(ref.canRead(ScreenCodes.logs), isFalse);
      expect(ref.branch.permission('PROFILES')?.vcName, 'Perfis');
    });

    test(
      'sem permissions no JSON (backend antigo) o comum ve so o dashboard',
      () {
        final ref = SessionContext.fromJson(_json(level: 10)).branches.single;
        expect(ref.canRead(ScreenCodes.dashboard), isTrue);
        expect(ref.canRead(ScreenCodes.users), isFalse);
      },
    );
  });
}
