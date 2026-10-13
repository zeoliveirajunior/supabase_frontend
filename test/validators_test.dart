import 'package:flutter_test/flutter_test.dart';
import 'package:odonto_app/shared/validators/validators.dart';

void main() {
  group('Validators.email', () {
    test('aceita e-mail valido', () {
      expect(Validators.email()('ana@clinica.com.br'), isNull);
    });

    test('rejeita e-mail sem dominio', () {
      expect(Validators.email()('ana@clinica'), isNotNull);
    });

    test('vazio passa (so required reprova vazio)', () {
      expect(Validators.email()(''), isNull);
      expect(Validators.required()(''), isNotNull);
    });
  });

  group('CPF', () {
    test('valido com e sem mascara', () {
      expect(Validators.isValidCpf('529.982.247-25'), isTrue);
      expect(Validators.isValidCpf('52998224725'), isTrue);
    });

    test('digitos repetidos e verificador errado reprovam', () {
      expect(Validators.isValidCpf('111.111.111-11'), isFalse);
      expect(Validators.isValidCpf('529.982.247-26'), isFalse);
      expect(Validators.isValidCpf('123'), isFalse);
    });
  });

  group('CNPJ', () {
    test('valido', () {
      expect(Validators.isValidCnpj('11.222.333/0001-81'), isTrue);
    });

    test('invalido', () {
      expect(Validators.isValidCnpj('11.222.333/0001-82'), isFalse);
      expect(Validators.isValidCnpj('00.000.000/0000-00'), isFalse);
    });

    test('cpfCnpj decide pelo tamanho', () {
      expect(Validators.cpfCnpj()('529.982.247-25'), isNull);
      expect(Validators.cpfCnpj()('11.222.333/0001-81'), isNull);
      expect(Validators.cpfCnpj()('11.222.333/0001-82'), isNotNull);
    });
  });

  group('telefone e data', () {
    test('fixo e celular', () {
      expect(Validators.isValidPhone('(11) 3333-4444'), isTrue);
      expect(Validators.isValidPhone('(11) 98765-4321'), isTrue);
      expect(Validators.isValidPhone('(11) 88765-4321'), isFalse);
      expect(Validators.isValidPhone('123'), isFalse);
    });

    test('data real', () {
      expect(Validators.isValidDate('29/02/2024'), isTrue);
      expect(Validators.isValidDate('31/02/2024'), isFalse);
      expect(Validators.isValidDate('10/13/2024'), isFalse);
    });
  });

  test('compose devolve o primeiro erro', () {
    final v = Validators.compose([Validators.required(), Validators.email()]);
    expect(v(''), isNotNull);
    expect(v('x'), isNotNull);
    expect(v('a@b.co'), isNull);
  });
}
