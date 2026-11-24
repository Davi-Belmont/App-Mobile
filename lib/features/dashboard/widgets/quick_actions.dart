// Responsável: João Pedro Meneses
import 'package:flutter/material.dart';
import 'package:study_planner/core/navigation/tab_nav.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/features/tasks/task_form_sheet.dart';

/// Atalhos rápidos do dashboard.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Shortcut(icon: Icons.add_task_rounded, label: 'Nova\natividade', onTap: () => TaskFormSheet.show(context)),
        _Shortcut(icon: Icons.calendar_month_rounded, label: 'Calendário', onTap: () => currentTab.value = TabIndex.calendar),
        _Shortcut(icon: Icons.menu_book_rounded, label: 'Disciplinas', onTap: () => currentTab.value = TabIndex.disciplines),
        _Shortcut(icon: Icons.grade_rounded, label: 'Notas', onTap: () => currentTab.value = TabIndex.profile),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}
