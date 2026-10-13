import 'package:flutter/widgets.dart';

/// Fator de forma pela LARGURA disponivel, nao pela plataforma: uma janela
/// estreita no navegador recebe o layout mobile, e um tablet deitado o desktop.
enum FormFactor { mobile, tablet, desktop }

abstract final class Breakpoints {
  /// Abaixo disto e mobile.
  static const double tablet = 600;

  /// A partir disto e desktop (layout web com painel lateral).
  static const double desktop = 1024;

  /// A partir disto o menu lateral abre com rotulos.
  static const double wide = 1280;

  static FormFactor of(double width) {
    if (width >= desktop) return FormFactor.desktop;
    if (width >= tablet) return FormFactor.tablet;
    return FormFactor.mobile;
  }
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  FormFactor get formFactor => Breakpoints.of(screenWidth);
  bool get isMobile => formFactor == FormFactor.mobile;
  bool get isTablet => formFactor == FormFactor.tablet;
  bool get isDesktop => formFactor == FormFactor.desktop;
  bool get isWide => screenWidth >= Breakpoints.wide;
}

/// Monta um layout diferente por fator de forma. [tablet] cai em [desktop]
/// quando nao informado.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder desktop;
  final WidgetBuilder? tablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return switch (Breakpoints.of(constraints.maxWidth)) {
          FormFactor.mobile => mobile(context),
          FormFactor.tablet => (tablet ?? desktop)(context),
          FormFactor.desktop => desktop(context),
        };
      },
    );
  }
}
