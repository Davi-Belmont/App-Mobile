// Responsável: Eduardo Madruga (Tela de Disciplinas)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/discipline.dart';
import 'package:study_planner/features/disciplines/discipline_detail_screen.dart';
import 'package:study_planner/features/disciplines/discipline_form_sheet.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';
import 'package:study_planner/features/profile/grades_provider.dart';
import 'package:study_planner/features/tasks/activities_provider.dart';

class DisciplinesScreen extends StatefulWidget {
  const DisciplinesScreen({super.key});

  @override
  State<DisciplinesScreen> createState() => _DisciplinesScreenState();
}

class _DisciplinesScreenState extends State<DisciplinesScreen> {
  String _query = '';

  Future<void> _refresh() async {
    await Future.wait([
      context.read<DisciplinesProvider>().load(silent: true),
      context.read<ActivitiesProvider>().load(silent: true),
      context.read<GradesProvider>().load(silent: true),
    ]);
  }

  Future<void> _delete(Discipline d) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir "${d.name}"?',
      message: 'As atividades e notas dessa disciplina também serão excluídas. Essa ação não pode ser desfeita.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<DisciplinesProvider>().remove(d.id);
      if (!mounted) return;
      context.read<ActivitiesProvider>().load(silent: true);
      context.read<GradesProvider>().load(silent: true);
      showSnack(context, 'Disciplina excluída');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final discs = context.watch<DisciplinesProvider>();
    final acts = context.watch<ActivitiesProvider>();

    final list = discs.items.where((d) => d.name.toLowerCase().contains(_query.toLowerCase())).toList();

    Widget body;
    if (discs.loading && discs.items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (discs.error != null && discs.items.isEmpty) {
      body = ErrorState(message: discs.error!, onRetry: () => discs.load());
    } else if (discs.items.isEmpty) {
      body = EmptyState(
        icon: Icons.menu_book_rounded,
        title: 'Nenhuma disciplina ainda',
        message: 'Cadastre as matérias do semestre para organizar tarefas e notas.',
        actionLabel: 'Adicionar disciplina',
        onAction: () => DisciplineFormSheet.show(context),
      );
    } else if (list.isEmpty) {
      body = const EmptyState(icon: Icons.search_off_rounded, title: 'Nada encontrado', message: 'Tente buscar por outro nome.');
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final d = list[i];
            return _DisciplineCard(
              discipline: d,
              pending: acts.items.where((a) => a.disciplineId == d.id && !a.isCompleted).length,
              average: d.average,
              onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DisciplineDetailScreen(discipline: d))),
              onEdit: () => DisciplineFormSheet.show(context, discipline: d),
              onDelete: () => _delete(d),
            );
          },
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => DisciplineFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Disciplina'),
      ),
      body: Column(
        children: [
          ScreenHeader(
            title: 'Disciplinas',
            subtitle: '${discs.items.length} no semestre',
            bottom: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar disciplina',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _DisciplineCard extends StatelessWidget {
  const _DisciplineCard({
    required this.discipline,
    required this.pending,
    required this.average,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Discipline discipline;
  final int pending;
  final double? average;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.subject(discipline.id);
    final desc = discipline.description;
    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(14)),
            child: Text(
              discipline.name.isEmpty ? '?' : discipline.name[0].toUpperCase(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.text),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(discipline.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                if (desc != null && desc.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    MiniChip(
                      pending == 0 ? 'Em dia' : '$pending pendente${pending > 1 ? 's' : ''}',
                      icon: pending == 0 ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                      bg: pending == 0 ? AppColors.successBg : c.bg,
                      fg: pending == 0 ? AppColors.success : c.text,
                    ),
                    if (average != null)
                      MiniChip('Média ${fmtGrade(average!)}', icon: Icons.grade_rounded, bg: const Color(0xFFF3F4F6), fg: gradeColor(average!)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir', style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ],
      ),
    );
  }
}
