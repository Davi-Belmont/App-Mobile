// Responsável: Davi Mariano Belmont (Tela de Tarefas)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/utils/date_utils.dart';
import 'package:study_planner/core/widgets/activity_tile.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/activity.dart';
import 'package:study_planner/data/models/activity_query.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';
import 'package:study_planner/features/tasks/activities_provider.dart';
import 'package:study_planner/features/tasks/activities_query_builder.dart';
import 'package:study_planner/features/tasks/task_form_sheet.dart';

// A API só tem dois status (PENDING e COMPLETED).
enum _StatusFilter { pending, completed, all }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _StatusFilter _status = _StatusFilter.pending;
  ActivityType? _type; // null = todos os tipos
  String? _disciplineId; // null = todas as disciplinas

  /// Os três filtros são enviados à API: GET /activities?status=&type=&disciplineId=
  ActivityQuery get _query => ActivityQuery(
        disciplineId: _disciplineId,
        type: _type,
        status: switch (_status) {
          _StatusFilter.pending => ActivityStatus.pending,
          _StatusFilter.completed => ActivityStatus.completed,
          _StatusFilter.all => null,
        },
      );

  /// Agrupa por urgência: Atrasadas, Hoje, Próximos 7 dias, Mais tarde, Concluídas.
  List<MapEntry<String, List<Activity>>> _group(List<Activity> list) {
    final g = <String, List<Activity>>{
      'Atrasadas': [],
      'Hoje': [],
      'Próximos 7 dias': [],
      'Mais tarde': [],
      'Concluídas': [],
    };
    final now = DateTime.now();
    for (final a in list) {
      if (a.isCompleted) {
        g['Concluídas']!.add(a);
      } else if (a.dueDate.isBefore(now)) {
        g['Atrasadas']!.add(a);
      } else {
        final n = DateHelpers.daysFromToday(a.dueDate);
        g[n == 0 ? 'Hoje' : (n <= 7 ? 'Próximos 7 dias' : 'Mais tarde')]!.add(a);
      }
    }
    for (final e in g.entries) {
      e.value.sort((a, b) => e.key == 'Concluídas' ? b.dueDate.compareTo(a.dueDate) : a.dueDate.compareTo(b.dueDate));
    }
    return g.entries.where((e) => e.value.isNotEmpty).toList();
  }

  Future<void> _toggle(Activity a, bool done) async {
    final err = await context.read<ActivitiesProvider>().toggle(a, done);
    if (err != null && mounted) showSnack(context, err);
  }

  Future<void> _delete(Activity a) async {
    try {
      await context.read<ActivitiesProvider>().remove(a.id);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  Color _groupColor(String title) => switch (title) {
        'Atrasadas' => AppColors.danger,
        'Hoje' => AppColors.warning,
        'Concluídas' => AppColors.success,
        _ => AppColors.primary,
      };

  Widget _body(BuildContext context, ActivitiesResult r) {
    final discs = context.watch<DisciplinesProvider>();
    final acts = context.read<ActivitiesProvider>();
    final groups = _group(r.items);

    if (r.loading && r.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (r.error != null && r.items.isEmpty) {
      return ErrorState(message: r.error!, onRetry: () => r.reload());
    }
    if (groups.isEmpty) {
      return EmptyState(
        icon: Icons.task_alt_rounded,
        title: _status == _StatusFilter.completed ? 'Nada concluído ainda' : 'Tudo em dia!',
        message: _status == _StatusFilter.completed
            ? 'As atividades concluídas aparecem aqui.'
            : 'Nenhuma atividade encontrada com esses filtros.',
        actionLabel: 'Nova atividade',
        onAction: () => TaskFormSheet.show(context),
      );
    }
    return RefreshIndicator(
      onRefresh: () => Future.wait([acts.load(silent: true), r.reload()]),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          for (final g in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
              child: Row(
                children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: _groupColor(g.key), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('${g.key} · ${g.value.length}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
            for (final a in g.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: ValueKey(a.id),
                  background: _swipeBg(Alignment.centerLeft, AppColors.success, a.isCompleted ? Icons.undo_rounded : Icons.check_rounded),
                  secondaryBackground: _swipeBg(Alignment.centerRight, AppColors.danger, Icons.delete_outline_rounded),
                  confirmDismiss: (dir) async {
                    if (dir == DismissDirection.startToEnd) {
                      _toggle(a, !a.isCompleted);
                      return false;
                    }
                    return confirmDialog(context, title: 'Excluir atividade?', message: '"${a.title}" será removida.');
                  },
                  onDismissed: (_) => _delete(a),
                  child: ActivityTile(
                    activity: a,
                    discipline: discs.byId(a.disciplineId),
                    onTap: () => TaskFormSheet.show(context, activity: a),
                    onToggle: (done) => _toggle(a, done),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final acts = context.watch<ActivitiesProvider>();
    final discs = context.watch<DisciplinesProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TaskFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova tarefa'),
      ),
      body: Column(
        children: [
          ScreenHeader(title: 'Tarefas', subtitle: '${acts.pendingCount} pendentes'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_StatusFilter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _StatusFilter.pending, label: Text('Pendentes')),
                  ButtonSegment(value: _StatusFilter.completed, label: Text('Concluídas')),
                  ButtonSegment(value: _StatusFilter.all, label: Text('Todas')),
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
            ),
          ),
          // Filtro por tipo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                _chip('Todos', _type == null, () => setState(() => _type = null)),
                for (final t in ActivityType.values) _chip(t.label, _type == t, () => setState(() => _type = t)),
              ],
            ),
          ),
          // Filtro por disciplina
          if (discs.items.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  _chip('Todas as disciplinas', _disciplineId == null, () => setState(() => _disciplineId = null)),
                  for (final d in discs.items) _chip(d.name, _disciplineId == d.id, () => setState(() => _disciplineId = d.id)),
                ],
              ),
            ),
          Expanded(
            child: ActivitiesQueryBuilder(
              query: _query,
              builder: _body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.primaryLight,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border),
        ),
      );

  Widget _swipeBg(Alignment align, Color color, IconData icon) => Container(
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: Colors.white),
      );
}