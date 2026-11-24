// Responsável: João Pedro Meneses (Tela de Perfil e Notas)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/config/app_user.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/core/widgets/grade_chip.dart';
import 'package:study_planner/data/models/discipline.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';
import 'package:study_planner/features/profile/grade_form_sheet.dart';
import 'package:study_planner/features/profile/grades_provider.dart';
import 'package:study_planner/features/tasks/activities_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final discs = context.watch<DisciplinesProvider>();
    final grades = context.watch<GradesProvider>();
    final acts = context.watch<ActivitiesProvider>();
    final overall = discs.overallAverage;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GradeFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Lançar nota'),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          grades.load(silent: true),
          discs.load(silent: true),
        ]),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ScreenHeader(
              title: AppUser.name,
              subtitle: AppUser.subtitle,
              trailing: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight,
                child: Text(AppUser.initials, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Média geral', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              Text(
                                overall == null ? '--' : fmtGrade(overall),
                                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: overall == null ? AppColors.textMuted : gradeColor(overall)),
                              ),
                              Text(
                                overall == null ? 'Lance suas notas' : (overall >= 7 ? 'Acima da meta (7,0)' : 'Abaixo da meta (7,0)'),
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _MiniStat(label: 'Disciplinas', value: '${discs.items.length}'),
                            const SizedBox(height: 8),
                            _MiniStat(label: 'Notas', value: '${grades.items.length}'),
                            const SizedBox(height: 8),
                            _MiniStat(label: 'Pendências', value: '${acts.pendingCount}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SectionTitle('Boletim'),
                  if (discs.items.isEmpty)
                    const AppCard(child: Text('Cadastre disciplinas para ver o boletim.', style: TextStyle(color: AppColors.textMuted)))
                  else
                    for (final d in discs.items)
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: _BoletimCard(discipline: d)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sair'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _BoletimCard extends StatelessWidget {
  const _BoletimCard({required this.discipline});
  final Discipline discipline;

  @override
  Widget build(BuildContext context) {
    final grades = context.watch<GradesProvider>();
    final list = grades.forDiscipline(discipline.id);
    final avg = discipline.average;
    final c = AppColors.subject(discipline.id);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(discipline.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
              Text(
                avg == null ? '--' : fmtGrade(avg),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: avg == null ? AppColors.textMuted : gradeColor(avg)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Barra de desempenho na escala de 0 a 10.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ((avg ?? 0) / 10).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              color: avg == null ? AppColors.border : gradeColor(avg),
            ),
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            const Text('Sem notas lançadas.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final g in list) GradeChip(g, onTap: () => GradeFormSheet.show(context, grade: g))],
            ),
        ],
      ),
    );
  }
}
