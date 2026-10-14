import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';

/// Logomarca Clinify: selo dourado com o dente estilizado + nome em dourado.
///
/// [color] e mantido pelos chamadores antigos: branco indica fundo escuro, e
/// ai o nome usa o dourado claro; em fundo claro usa o dourado escuro.
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
      Strings.appName,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontSize: size * 0.65,
        fontWeight: FontWeight.w800,
        color: wordmarkColor ?? Colors.white,
        letterSpacing: -0.5,
        height: 1.1,
      ),
    );
    if (wordmarkColor == null) {
      final colors = onDark
          ? const [AppColors.goldPale, AppColors.goldLight]
          : const [AppColors.goldLight, AppColors.goldDark];
      wordmark = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: wordmark,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: size * 0.25),
        wordmark,
      ],
    );
  }
}
