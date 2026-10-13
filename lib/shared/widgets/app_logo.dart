import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';

/// Dente estilizado + nome do app.
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
      'assets/images/tooth_logo.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: Strings.appName,
    );
    if (!showWordmark) return icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: size * 0.25),
        Text(
          Strings.appName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: size * 0.65,
            fontWeight: FontWeight.w800,
            color: wordmarkColor ?? color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
