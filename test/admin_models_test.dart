import 'package:flutter_test/flutter_test.dart';
import 'package:odonto_app/features/logs/data/log_repository.dart';
import 'package:odonto_app/features/logs/domain/access_log_entry.dart';
import 'package:odonto_app/features/profiles/domain/access_profile.dart';
import 'package:odonto_app/features/users/domain/company_user.dart';

void main() {
  group('AccessProfile', () {
    test('parse e flags', () {
      final p = AccessProfile.fromJson({
        'nr_profile': 1,
        'vc_name': 'Administrador',
        'it_level': 100,
        'it_status': 1,
        'qt_users': 2,
        'dh_updated': '2026-10-13T20:00:00+00:00',
      });
      expect(p.isAdmin, isTrue);
      expect(p.isActive, isTrue);
      expect(p.qtUsers, 2);
      expect(p.copyWith(itStatus: 90).isActive, isFalse);
    });
  });

  group('CompanyUserPage', () {
    final json = {
      'qt_total': 120,
      'nr_page': 2,
      'qt_page_size': 50,
      'users': [
        {
          'nr_user': 7,
          'nr_company_user': 3,
          'vc_name': 'Bia Lista',
          'vc_email': 'bia@test.local',
          'it_status': 80,
          'vc_block_reason': 'Inadimplência',
          'id_admin': false,
          'branches': [
            {
              'nr_branch': 1,
              'vc_branch': 'Matriz',
              'id_main': true,
              'nr_profile': 2,
              'vc_profile': 'Usuário',
              'it_level': 0,
            },
          ],
        },
      ],
    };

    test('paginacao', () {
      final page = CompanyUserPage.fromJson(json);
      expect(page.pageCount, 3);
      expect(page.hasPrevious, isTrue);
      expect(page.hasNext, isTrue);
      expect(page.users.single.isBlocked, isTrue);
      expect(page.users.single.initials, 'BL');
      expect(page.users.single.branches.single.vcProfile, 'Usuário');
    });

    test('pagina vazia tem 1 pagina', () {
      final page = CompanyUserPage.fromJson({'qt_total': 0, 'users': []});
      expect(page.pageCount, 1);
      expect(page.hasNext, isFalse);
    });

    test('BranchAssignment vira o json do company_user_save', () {
      expect(const BranchAssignment(nrBranch: 2, nrProfile: 3).toJson(), {
        'nr_branch': 2,
        'nr_profile': 3,
      });
    });
  });

  group('Logs', () {
    test('parse com campos nulos e data local', () {
      final e = AccessLogEntry.fromJson({
        'nr_access': 10,
        'nr_user': 1,
        'vc_user': 'Ana',
        'nr_company': null,
        'nr_branch': null,
        'vc_branch': null,
        'it_app': 2,
        'dh_access': '2026-10-13T20:00:00+00:00',
      });
      expect(e.nrCompany, isNull);
      expect(e.itApp, AppKind.android);
      expect(e.dhAccess.toUtc().hour, 20);
      expect(AppKind.label(e.itApp), 'Android');
      expect(AppKind.label(null), '-');
    });

    test('LogFilters.lastDays cobre o dia de hoje inteiro', () {
      final f = LogFilters.lastDays(7);
      final now = DateTime.now();
      expect(f.to.day, now.day);
      expect(f.to.hour, 23);
      expect(f.from.hour, 0);
      expect(f.to.difference(f.from).inDays, 6);
      expect(f.copyWith(clearApp: true, itApp: 1).itApp, isNull);
      expect(f.copyWith(itApp: 1).itApp, 1);
    });
  });

  test('Branch.isActive considera bloqueio', () {
    final b = Branch.fromJson({
      'nr_branch': 1,
      'vc_name': 'Matriz',
      'id_main': true,
      'it_status': 1,
      'id_blocked': true,
    });
    expect(b.isActive, isFalse);
  });
}
