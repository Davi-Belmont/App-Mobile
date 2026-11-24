// Responsável: Davi Mariano Belmont (cartão de atividade reutilizado em várias telas)
import 'package:flutter/material.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/utils/date_utils.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/data/models/activity.dart';
import 'package:study_planner/data/models/discipline.dart';

extension ActivityTypeUi on ActivityType {
  IconData get icon => switch (this) {
        ActivityType.task => Icons.task_alt_rounded,
        ActivityType.exam => Icons.quiz_rounded,
        ActivityType.assignment => Icons.description_rounded,
      };

  Color get color => switch (this) {
        ActivityType.task => const Color(0xFF3B82F6),
        ActivityType.exam => AppColors.danger,
        ActivityType.assignment => const Color(0xFFD97706),
      };

  Color get bg => switch (this) {
        ActivityType.task => const Color(0xFFDBEAFE),
        ActivityType.exam => AppColors.dangerBg,
        ActivityType.assignment => AppColors.warningBg,
      };
}

/// Selo de prazo: "Atrasada", "Hoje, 18:00", "Amanhã, 23:59", "05/10 · 19:00".
class DueBadge extends StatelessWidget {
  const DueBadge(this.activity, {super.key});
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    late final String label;
    Color bg = const Color(0xFFF3F4F6);
    Color fg = AppColors.textMuted;

    if (a.isCompleted) {
      label = DateHelpers.shortDate(a.dueDate);
    } else {
      switch (a.urgency) {
        case Urgency.overdue:
          label = 'Atrasada';
          bg = AppColors.dangerBg;
          fg = AppColors.danger;
        case Urgency.urgent:
          label = DateHelpers.relative(a.dueDate);
          bg = AppColors.dangerBg;
          fg = AppColors.danger;
        case Urgency.soon:
          label = DateHelpers.relative(a.dueDate);
          bg = AppColors.warningBg;
          fg = AppColors.warning;
        case Urgency.ok:
          label = DateHelpers.relative(a.dueDate);
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.activity,
    this.discipline,
    this.onTap,
    this.onToggle,
  });

  final Activity activity;
  final Discipline? discipline;
  final VoidCallback? onTap;

  /// Se informado, mostra um círculo para concluir/reabrir a atividade.
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final c = AppColors.subject(a.disciplineId);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (onToggle != null)
            _CheckCircle(done: a.isCompleted, onTap: () => onToggle!(!a.isCompleted))
          else
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: a.type.bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(a.type.icon, size: 20, color: a.type.color),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: a.isCompleted ? AppColors.textMuted : AppColors.textDark,
                    decoration: a.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    MiniChip(a.type.label, icon: a.type.icon, bg: a.type.bg, fg: a.type.color),
                    if (discipline != null) MiniChip(discipline!.name, bg: c.bg, fg: c.text),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DueBadge(a),
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done, required this.onTap});
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.success : Colors.transparent,
              border: Border.all(color: done ? AppColors.success : const Color(0xFF9CA3AF), width: 2),
            ),
            child: done ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
          ),
        ),
      ),
    );
  }
}
