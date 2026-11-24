// Responsável: Cainã Coutinho
import 'package:flutter/material.dart';

/// Trio de cores pastel usado para identificar cada disciplina.
class SubjectColor {
  const SubjectColor(this.bg, this.accent, this.text);
  final Color bg;
  final Color accent;
  final Color text;
}

class AppColors {
  static const primary = Color(0xFF1E5AA8);
  static const primaryDark = Color(0xFF14427F);
  static const primaryLight = Color(0xFFDBEAFE);
  static const background = Color(0xFFF4F6FA);
  static const border = Color(0xFFE5E7EB);
  static const textDark = Color(0xFF1F2937);
  static const textMuted = Color(0xFF6B7280);

  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);

  static const _subjects = [
    SubjectColor(Color(0xFFDBEAFE), Color(0xFF3B82F6), Color(0xFF1E3A8A)), // azul
    SubjectColor(Color(0xFFDCFCE7), Color(0xFF22C55E), Color(0xFF14532D)), // verde
    SubjectColor(Color(0xFFFEF3C7), Color(0xFFF59E0B), Color(0xFF78350F)), // âmbar
    SubjectColor(Color(0xFFFCE7F3), Color(0xFFEC4899), Color(0xFF831843)), // rosa
    SubjectColor(Color(0xFFEDE9FE), Color(0xFF8B5CF6), Color(0xFF4C1D95)), // roxo
    SubjectColor(Color(0xFFCCFBF1), Color(0xFF14B8A6), Color(0xFF134E4A)), // turquesa
  ];

  /// Cor estável para uma disciplina (sempre a mesma para o mesmo id).
  static SubjectColor subject(String? key) {
    final sum = (key ?? '').codeUnits.fold<int>(0, (a, b) => a + b);
    return _subjects[sum % _subjects.length];
  }
}
