import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';

/// Logomarca Clinify: monograma "C" em ouro metalico sobre um selo grafite com
/// filete dourado e um diamante lapidado na boca do C; nome em caixa alta,
/// espacado, tambem em ouro.
///
/// [color] e mantido pelos chamadores antigos: branco indica fundo escuro, e
/// ai o nome usa o ouro claro; em fundo claro usa o ouro escuro (contraste).
/// [wordmarkColor] forca uma cor solida no nome.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.color = AppColors.primary,
    this.showWordmark = true,
    this.wordmarkColor,
  });

  final double size;
  final Color color;
  final bool showWordmark;
  final Color? wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      'assets/images/clinify_logo.svg',
      width: size,
      height: size,
      semanticsLabel: Strings.appName,
    );
    if (!showWordmark) return icon;

    final onDark = color == Colors.white;
    Widget wordmark = Text(
      Strings.appName.toUpperCase(),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontSize: size * 0.54,
        fontWeight: FontWeight.w800,
        color: wordmarkColor ?? Colors.white,
        letterSpacing: size * 0.09,
        height: 1.0,
      ),
    );
    if (wordmarkColor == null) {
      final colors = onDark
          ? const [AppColors.goldPale, AppColors.goldLight, AppColors.gold]
          : const [AppColors.goldLight, AppColors.gold, AppColors.goldDeep];
      wordmark = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: colors,
          stops: const [0, 0.45, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        child: wordmark,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: size * 0.3),
        wordmark,
      ],
    );
  }
}
