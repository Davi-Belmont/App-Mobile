// Responsável: João Pedro Meneses
import 'package:flutter/material.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/data/models/activity.dart';

/// "Semáforo da semana": vermelho (atrasadas ou em até 48h), âmbar (até 7 dias)
/// e verde (mais de 7 dias). Considera só as atividades pendentes.
class SemaphoreCard extends StatelessWidget {
  const SemaphoreCard({super.key, required this.pending});
  final List<Activity> pending;

  @override
  Widget build(BuildContext context) {
    int count(bool Function(Urgency) test) => pending.where((a) => test(a.urgency)).length;
    final red = count((u) => u == Urgency.overdue || u == Urgency.urgent);
    final amber = count((u) => u == Urgency.soon);
    final green = count((u) => u == Urgency.ok);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Semáforo da semana', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            red > 0 ? 'Você tem $red ${red == 1 ? 'entrega urgente' : 'entregas urgentes'}.' : 'Nenhuma entrega urgente por enquanto.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Light(count: red, label: 'Urgentes', fg: AppColors.danger, bg: AppColors.dangerBg),
              _Light(count: amber, label: 'Atenção', fg: AppColors.warning, bg: AppColors.warningBg),
              _Light(count: green, label: 'No prazo', fg: AppColors.success, bg: AppColors.successBg),
            ],
          ),
        ],
      ),
    );
  }
}

class _Light extends StatelessWidget {
  const _Light({required this.count, required this.label, required this.fg, required this.bg});
  final int count;
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: fg, width: 2)),
            child: Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
