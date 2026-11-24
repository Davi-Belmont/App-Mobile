// Responsável: João Pedro Meneses (Tela Inicial / Dashboard)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/config/app_user.dart';
import 'package:study_planner/core/navigation/tab_nav.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/utils/date_utils.dart';
import 'package:study_planner/core/widgets/activity_tile.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/features/dashboard/dashboard_provider.dart';
import 'package:study_planner/features/dashboard/widgets/quick_actions.dart';
import 'package:study_planner/features/dashboard/widgets/semaphore_card.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';
import 'package:study_planner/features/tasks/activities_provider.dart';
import 'package:study_planner/features/tasks/task_form_sheet.dart';
import 'package:study_planner/data/models/dashboard_summary.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(BuildContext context) => Future.wait([
        context.read<DashboardProvider>().load(silent: true),
        context.read<ActivitiesProvider>().load(silent: true),
        context.read<DisciplinesProvider>().load(silent: true),
      ]);

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final acts = context.watch<ActivitiesProvider>();
    final discs = context.watch<DisciplinesProvider>();

    final pending = acts.items.where((a) => !a.isCompleted).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final summary = dash.summary;
    // Prefere as "próximas 5 pendentes" que vêm do GET /dashboard.
    final next = (summary != null && summary.nextActivities.isNotEmpty)
        ? summary.nextActivities
        : pending.take(5).toList();

    final disciplinesCount = summary?.disciplinesCount ?? discs.items.length;
    final pendingCount = summary?.pendingCount ?? pending.length;
    final offline = dash.error != null && summary == null;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ScreenHeader(
              title: 'Olá, ${AppUser.firstName}',
              subtitle: DateHelpers.longDate(DateTime.now()),
              trailing: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: Text(AppUser.initials, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (offline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off_rounded, color: AppColors.warning),
                          const SizedBox(width: 10),
                          Expanded(child: Text(dash.error!, style: const TextStyle(color: AppColors.warning))),
                          TextButton(onPressed: () => dash.load(), child: const Text('Tentar')),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.menu_book_rounded, value: '$disciplinesCount', label: 'Disciplinas', fg: AppColors.primary, bg: AppColors.primaryLight)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(icon: Icons.pending_actions_rounded, value: '$pendingCount', label: 'Pendentes', fg: AppColors.warning, bg: AppColors.warningBg)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SemaphoreCard(pending: pending),
                  const SizedBox(height: 18),
                  const QuickActions(),
                  SectionTitle(
                    'Próximas atividades',
                    trailing: TextButton(
                      onPressed: () => currentTab.value = TabIndex.tasks,
                      child: const Text('Ver todas'),
                    ),
                  ),
                  if (next.isEmpty)
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.celebration_rounded, color: AppColors.success),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('Tudo em dia! Nenhuma atividade pendente.')),
                          TextButton(onPressed: () => TaskFormSheet.show(context), child: const Text('Adicionar')),
                        ],
                      ),
                    )
                  else
                    for (final a in next)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ActivityTile(
                          activity: a,
                          discipline: discs.byId(a.disciplineId),
                          onTap: () => TaskFormSheet.show(context, activity: a),
                        ),
                      ),
                                        if (summary != null && summary.averages.isNotEmpty) ...[
                    const SectionTitle('Médias por disciplina'),
                    AppCard(
                      child: Column(
                        children: [for (final m in summary.averages) _AverageRow(m)],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label, required this.fg, required this.bg});
  final IconData icon;
  final String value;
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: fg),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AverageRow extends StatelessWidget {
  const _AverageRow(this.item);
  final DisciplineAverage item;

  @override
  Widget build(BuildContext context) {
    final avg = item.average;
    final c = AppColors.subject(item.disciplineId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(
            avg == null ? '--' : fmtGrade(avg),
            style: TextStyle(fontWeight: FontWeight.w800, color: avg == null ? AppColors.textMuted : gradeColor(avg)),
          ),
        ],
      ),
    );
  }
}