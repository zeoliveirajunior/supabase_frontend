import 'package:flutter_test/flutter_test.dart';
import 'package:odonto_app/features/logs/data/event_repository.dart';
import 'package:odonto_app/features/logs/domain/event_log_entry.dart';
import 'package:odonto_app/features/profiles/domain/access_profile.dart';

void main() {
  group('AccessProfile com telas', () {
    test('parse de screens e toJson para o save', () {
      final p = AccessProfile.fromJson({
        'nr_profile': 3,
        'vc_name': 'Recepção',
        'it_level': 10,
        'it_status': 1,
        'qt_users': 1,
        'screens': [
          {
            'uu_screen': '0d6a1f3e-1b2c-4d5e-8f90-000000000002',
            'vc_code': 'USERS',
            'vc_name': 'Usuários',
            'id_read': true,
            'id_create': false,
            'id_update': true,
          },
        ],
      });
      expect(p.isAdmin, isFalse);
      expect(p.screens.single.vcCode, 'USERS');
      expect(
        p.screen('0d6a1f3e-1b2c-4d5e-8f90-000000000002')?.idUpdate,
        isTrue,
      );
      expect(p.screens.single.toJson(), {
        'uu_screen': '0d6a1f3e-1b2c-4d5e-8f90-000000000002',
        'id_read': true,
        'id_create': false,
        'id_update': true,
      });
    });

    test('ScreenInfo parse', () {
      final s = ScreenInfo.fromJson({
        'uu_screen': 'u',
        'vc_code': 'LOGS',
        'vc_name': 'Logs',
        'vc_group': 'Administração',
        'nr_order': 40,
      });
      expect(s.vcGroup, 'Administração');
      expect(s.nrOrder, 40);
    });
  });

  group('Log de atividades', () {
    test('parse da pagina e dos campos opcionais', () {
      final page = EventLogPage.fromJson({
        'qt_total': 51,
        'nr_page': 1,
        'qt_page_size': 50,
        'events': [
          {
            'nr_event': 9,
            'nr_user': 1,
            'vc_user': 'Ana',
            'uu_screen': null,
            'vc_screen_code': null,
            'vc_screen': null,
            'vc_action': 'CREATE',
            'vc_entity': 'company',
            'vc_key': '1',
            'vc_summary': 'Empresa X criada',
            'js_detail': {'vc_name': 'X'},
            'nr_branch': 1,
            'vc_branch': 'Matriz',
            'dh_event': '2026-10-13T23:00:00+00:00',
          },
        ],
      });
      expect(page.pageCount, 2);
      final e = page.events.single;
      expect(e.vcScreen, isNull);
      expect(e.jsDetail?['vc_name'], 'X');
      expect(e.dhEvent.toUtc().hour, 23);
      expect(EventAction.label(e.vcAction), 'Criação');
      expect(EventAction.label('XPTO'), '-');
    });

    test('EventFilters.lastDays e copyWith', () {
      final f = EventFilters.lastDays(30);
      expect(f.to.difference(f.from).inDays, 29);
      expect(f.copyWith(uuScreen: 'u').uuScreen, 'u');
      expect(f.copyWith(uuScreen: 'u', clearScreen: true).uuScreen, isNull);
      expect(f.copyWith(vcAction: 'CREATE').vcAction, 'CREATE');
    });
  });
}
