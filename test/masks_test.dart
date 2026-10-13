import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odonto_app/shared/formatters/masks.dart';

TextEditingValue _type(TextInputFormatter formatter, String text) =>
    formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );

void main() {
  test('format aplica a mascara e unmask desfaz', () {
    expect(Masks.format(MaskType.cpf, '52998224725'), '529.982.247-25');
    expect(Masks.format(MaskType.cnpj, '11222333000181'), '11.222.333/0001-81');
    expect(Masks.format(MaskType.cep, '01311000'), '01311-000');
    expect(Masks.format(MaskType.date, '13102026'), '13/10/2026');
    expect(Masks.unmask('529.982.247-25'), '52998224725');
  });

  test('mascara parcial para quando acabam os digitos', () {
    expect(Masks.format(MaskType.cpf, '529'), '529');
    expect(Masks.format(MaskType.cpf, '5299'), '529.9');
  });

  test('telefone troca entre fixo e celular', () {
    expect(Masks.format(MaskType.phone, '1133334444'), '(11) 3333-4444');
    expect(Masks.format(MaskType.phone, '11987654321'), '(11) 98765-4321');
  });

  test('cpfCnpj troca de mascara no 12o digito', () {
    expect(Masks.format(MaskType.cpfCnpj, '52998224725'), '529.982.247-25');
    expect(Masks.format(MaskType.cpfCnpj, '112223330001'), '11.222.333/0001');
  });

  test('formatter dinamico limita digitos e ignora letras', () {
    final f = Masks.formatter(MaskType.phone);
    expect(_type(f, '11a98765432199').text, '(11) 98765-4321');
    final c = Masks.formatter(MaskType.cpfCnpj);
    expect(_type(c, '11222333000181999').text, '11.222.333/0001-81');
  });

  test('formatter fixo (CPF) formata enquanto digita', () {
    final f = Masks.formatter(MaskType.cpf);
    expect(_type(f, '52998224725').text, '529.982.247-25');
  });
}
