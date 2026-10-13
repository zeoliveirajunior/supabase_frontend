import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odonto_app/core/theme/app_theme.dart';
import 'package:odonto_app/features/auth/presentation/widgets/login_form.dart';
import 'package:odonto_app/l10n/strings.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(useGoogleFonts: false),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('nao submete com campos vazios e mostra validacao', (
    tester,
  ) async {
    var submitted = false;
    await tester.pumpWidget(
      _wrap(LoginForm(onSubmit: (_, __) async => submitted = true)),
    );

    await tester.tap(find.text(Strings.signIn));
    await tester.pumpAndSettle();

    expect(submitted, isFalse);
    expect(find.text(Strings.required), findsNWidgets(2));
  });

  testWidgets('e-mail invalido bloqueia o envio', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      _wrap(LoginForm(onSubmit: (_, __) async => submitted = true)),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@clinica');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text(Strings.signIn));
    await tester.pumpAndSettle();

    expect(submitted, isFalse);
    expect(find.text(Strings.invalidEmail), findsOneWidget);
  });

  testWidgets('dados validos chamam onSubmit com e-mail sem espacos', (
    tester,
  ) async {
    String? email;
    String? password;
    await tester.pumpWidget(
      _wrap(
        LoginForm(
          onSubmit: (e, p) async {
            email = e;
            password = p;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  ana@clinica.com.br ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo1');
    await tester.tap(find.text(Strings.signIn));
    await tester.pumpAndSettle();

    expect(email, 'ana@clinica.com.br');
    expect(password, 'segredo1');
  });

  testWidgets('em loading o botao mostra progresso e nao envia', (
    tester,
  ) async {
    var submitted = false;
    await tester.pumpWidget(
      _wrap(
        LoginForm(loading: true, onSubmit: (_, __) async => submitted = true),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(Strings.signIn), findsNothing);
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();
    expect(submitted, isFalse);
  });

  testWidgets('botao de mostrar senha alterna a visibilidade', (tester) async {
    await tester.pumpWidget(_wrap(LoginForm(onSubmit: (_, __) async {})));

    expect(find.byTooltip(Strings.showPassword), findsOneWidget);
    await tester.tap(find.byTooltip(Strings.showPassword));
    await tester.pump();
    expect(find.byTooltip(Strings.hidePassword), findsOneWidget);
  });
}
