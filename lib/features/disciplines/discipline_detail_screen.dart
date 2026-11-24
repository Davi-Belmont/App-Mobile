// Responsável: Eduardo Madruga (detalhamento da matéria)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/widgets/activity_tile.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/core/widgets/grade_chip.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/activity.dart';
import 'package:study_planner/data/models/discipline.dart';
import 'package:study_planner/data/models/grade.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';
import 'package:study_planner/features/profile/grade_form_sheet.dart';
import 'package:study_planner/features/profile/grades_provider.dart';
import 'package:study_planner/features/tasks/activities_provider.dart';
import 'package:study_planner/features/tasks/task_form_sheet.dart';

/// Detalhe da disciplina. Dados vindos da API:
///  - GET /disciplines/:id           → disciplina + atividades
///  - GET /grades?disciplineId=:id   → notas (da mais recente para a mais antiga)
///  - média                          → Discipline.average (GET /disciplines)
class DisciplineDetailScreen extends StatefulWidget {
  const DisciplineDetailScreen({super.key, required this.discipline});
  final Discipline discipline;

  @override
  State<DisciplineDetailScreen> createState() => _DisciplineDetailScreenState();
}

class _DisciplineDetailScreenState extends State<DisciplineDetailScreen> {
  Discipline? _detail;
  List<Grade> _grades = const [];
  bool _loading = true;
  String? _error;
  int _seq = 0;
  late int _revision;

  @override
  void initState() {
    super.initState();
    _revision = context.read<ActivitiesProvider>().revision + context.read<GradesProvider>().revision;
    _load();
  }

  Future<void> _load({bool showLoading = false}) async {
    final seq = ++_seq;
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final id = widget.discipline.id;
    final detailFuture = context.read<DisciplinesProvider>().fetchById(id);
    final gradesFuture = context.read<GradesProvider>().fetch(disciplineId: id);
    try {
      final results = await Future.wait<Object>([detailFuture, gradesFuture]);
      if (!mounted || seq != _seq) return;
      setState(() {
        _detail = results[0] as Discipline;
        _grades = results[1] as List<Grade>;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _loading = false;
        if (_detail == null) _error = e.message;
      });
    }
  }

  Future<void> _refresh() => Future.wait([
        _load(),
        context.read<DisciplinesProvider>().load(silent: true),
      ]);

  @override
  Widget build(BuildContext context) {
    final acts = context.watch<ActivitiesProvider>();
    final gradesProvider = context.watch<GradesProvider>();
    final discs = context.watch<DisciplinesProvider>();

    // Recarrega do servidor quando uma nota ou atividade é criada/editada/excluída.
    final rev = acts.revision + gradesProvider.revision;
    if (rev != _revision) {
      _revision = rev;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }

    final d = _detail ?? widget.discipline;
    final c = AppColors.subject(d.id);
    final avg = discs.averageOf(d.id);
    final myActs = acts.overlay(_detail?.activities ?? const <Activity>[])
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    Widget body;
    if (_loading && _detail == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _detail == null) {
      body = ErrorState(message: _error!, onRetry: () => _load(showLoading: true));
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text)),
                        if ((d.description ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(d.description!, style: TextStyle(color: c.text)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Text(avg == null ? '--' : fmtGrade(avg),
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: avg == null ? c.text : gradeColor(avg))),
                      Text('média', style: TextStyle(fontSize: 12, color: c.text)),
                    ],
                  ),
                ],
              ),
            ),
            SectionTitle(
              'Notas',
              trailing: TextButton.icon(
                onPressed: () => GradeFormSheet.show(context, disciplineId: d.id),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Lançar nota'),
              ),
            ),
            if (_grades.isEmpty)
              const Text('Nenhuma nota lançada nesta disciplina.', style: TextStyle(color: AppColors.textMuted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final g in _grades) GradeChip(g, onTap: () => GradeFormSheet.show(context, grade: g))],
              ),
            SectionTitle(
              'Atividades',
              trailing: TextButton.icon(
                onPressed: () => TaskFormSheet.show(context, disciplineId: d.id),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nova'),
              ),
            ),
            if (myActs.isEmpty)
              const Text('Nenhuma atividade cadastrada.', style: TextStyle(color: AppColors.textMuted))
            else
              for (final a in myActs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ActivityTile(
                    activity: a,
                    onTap: () => TaskFormSheet.show(context, activity: a),
                    onToggle: (done) => context.read<ActivitiesProvider>().toggle(a, done),
                  ),
                ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: body,
    );
  }
}