// Responsável: João Pedro Meneses
import 'package:flutter/material.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/utils/date_utils.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/data/models/grade.dart';

/// Etiqueta de uma nota (ex.: "8,5 · Prova 1 · 12/11"). Colorida pelo desempenho.
class GradeChip extends StatelessWidget {
  const GradeChip(this.grade, {super.key, this.onTap});
  final Grade grade;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = gradeColor(grade.value);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fmtGrade(grade.value), style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text('${grade.description} · ${DateHelpers.shortDate(grade.date)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}