import 'package:flutter_test/flutter_test.dart';
import 'package:odonto_app/features/patients/domain/patient_models.dart';
import 'package:odonto_app/shared/formatters/dates.dart';

void main() {
  group('Patient', () {
    final p = Patient.fromJson({
      'nr_patient': 7,
      'vc_name': 'Mariana Souza',
      'vc_nickname': 'Mari',
      'vc_cpf': '52998224725',
      'dt_birth': '1990-05-20',
      'qt_age': 36,
      'it_gender': 2,
      'it_source': 4,
      'vc_referral': 'Dra. Paula',
      'vc_mobile': '11987654321',
      'vc_email': 'mariana@teste.com',
      'id_no_email': false,
      'vc_city': 'São Paulo',
      'vc_state': 'SP',
      'dt_return_alert': '2026-12-01',
      'vc_return_alert': 'Retorno da limpeza',
      'it_status': 1,
      'dh_created': '2026-10-14T10:00:00+00:00',
    });

    test('campos tipados e acesso por coluna', () {
      expect(p.nrPatient, 7);
      expect(p.vcName, 'Mariana Souza');
      expect(p.dtBirth, DateTime(1990, 5, 20));
      expect(p.age, 36);
      expect(p.isMinor, isFalse);
      expect(p.isActive, isTrue);
      expect(p.text('vc_city'), 'São Paulo');
      expect(p.text('vc_rg'), isNull);
      expect(p.code('it_gender'), 2);
      expect(p.hasReturnAlert, isTrue);
      expect(p.dtReturnAlert, DateTime(2026, 12, 1));
    });

    test('formatacao: iniciais, cpf, celular, origem', () {
      expect(p.initials, 'MS');
      expect(p.displayName, 'Mariana Souza (Mari)');
      expect(p.cpfFormatted, '529.982.247-25');
      expect(p.mobileFormatted, '(11) 98765-4321');
      expect(p.phoneFormatted, '-');
      expect(p.sourceLabel, 'Indicação: Dra. Paula');
      expect(Gender.label(p.itGender), 'Feminino');
    });

    test('menor de idade sem qt_age usa a data de nascimento', () {
      final kid = Patient.fromJson({
        'nr_patient': 1,
        'vc_name': 'Ana',
        'dt_birth': Dates.toIso(
          DateTime.now().subtract(const Duration(days: 365 * 10)),
        ),
      });
      expect(kid.isMinor, isTrue);
      expect(kid.initials, 'A');
      expect(kid.sourceLabel, '-');
      expect(kid.cpfFormatted, '-');
    });
  });

  group('PatientPage', () {
    test('parse e paginas', () {
      final page = PatientPage.fromJson({
        'patients': [
          {'nr_patient': 1, 'vc_name': 'A', 'dt_birth': '2000-01-01'},
          {'nr_patient': 2, 'vc_name': 'B', 'dt_birth': '2000-01-01'},
        ],
        'qt_total': 120,
        'nr_page': 2,
        'qt_page_size': 50,
      });
      expect(page.patients.length, 2);
      expect(page.page, 2);
      expect(page.pageCount, 3);
      expect(
        const PatientPage(
          patients: [],
          total: 0,
          page: 1,
          pageSize: 50,
        ).pageCount,
        1,
      );
    });
  });

  group('PatientRecord', () {
    test('notas com autor', () {
      final r = PatientRecord.fromJson({
        'patient': {'nr_patient': 1, 'vc_name': 'A', 'dt_birth': '2000-01-01'},
        'notes': [
          {
            'nr_note': 2,
            'vc_note': 'Trouxe exames',
            'nr_user': 1,
            'vc_user': 'Ana',
            'dh_note': '2026-10-14T12:00:00Z',
          },
        ],
      });
      expect(r.notes.single.vcUser, 'Ana');
      expect(r.notes.single.dhNote, isNotNull);
    });
  });

  group('Dates', () {
    test('campo <-> iso', () {
      expect(Dates.parseField('20/05/1990'), DateTime(1990, 5, 20));
      expect(Dates.parseField('31/02/1990'), isNull);
      expect(Dates.parseField(''), isNull);
      expect(Dates.toIso(DateTime(1990, 5, 20)), '1990-05-20');
      expect(Dates.toField(DateTime(1990, 5, 20)), '20/05/1990');
      expect(Dates.fromIso('1990-05-20'), DateTime(1990, 5, 20));
      expect(Dates.format(null), '-');
    });

    test('idade completa', () {
      final at = DateTime(2026, 10, 14);
      expect(Dates.age(DateTime(1990, 5, 20), at: at), 36);
      expect(Dates.age(DateTime(1990, 10, 15), at: at), 35);
      expect(Dates.age(DateTime(1990, 10, 14), at: at), 36);
    });
  });
}
