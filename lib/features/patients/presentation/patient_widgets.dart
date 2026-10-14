import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/patient_models.dart';

/// Avatar com as iniciais do paciente (cor estavel por paciente).
class PatientAvatar extends StatelessWidget {
  const PatientAvatar({super.key, required this.patient, this.size = 40});

  final Patient patient;
  final double size;

  static const _palette = [
    AppColors.primary,
    AppColors.primaryDark,
    AppColors.gold,
    AppColors.goldDark,
    AppColors.accent,
    AppColors.ink,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[patient.nrPatient % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: patient.isActive ? 0.14 : 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        patient.initials,
        style: TextStyle(
          color: patient.isActive ? color : AppColors.muted,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
