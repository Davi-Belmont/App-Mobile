// Responsável: Davi Mariano Belmont
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/utils/date_utils.dart';
import 'package:study_planner/core/widgets/activity_tile.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/activity.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';
import 'package:study_planner/features/tasks/activities_provider.dart';

/// Formulário de criar/editar atividade (tarefa, prova ou trabalho).
class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({super.key, this.activity, this.initialDate, this.disciplineId});
  final Activity? activity;
  final DateTime? initialDate;
  final String? disciplineId;

  static Future<void> show(
    BuildContext context, {
    Activity? activity,
    DateTime? initialDate,
    String? disciplineId,
  }) =>
      showFormSheet(
        context,
        TaskFormSheet(activity: activity, initialDate: initialDate, disciplineId: disciplineId),
      );

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late ActivityType _type;
  String? _disciplineId;
  late DateTime _due;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _title = TextEditingController(text: a?.title);
    _desc = TextEditingController(text: a?.description);
    _type = a?.type ?? ActivityType.task;
    _disciplineId = a?.disciplineId ?? widget.disciplineId;
    if (a != null) {
      _due = a.dueDate;
    } else {
      final base = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
      _due = DateTime(base.year, base.month, base.day, 23, 59);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_due));
    if (!mounted) return;
    setState(() {
      final t = time ?? TimeOfDay.fromDateTime(_due);
      _due = DateTime(date.year, date.month, date.day, t.hour, t.minute);
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_disciplineId == null) {
      setState(() => _error = 'Escolha a disciplina da atividade.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final p = context.read<ActivitiesProvider>();
    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();
    try {
      if (_editing) {
        final a = widget.activity!;
        // Cria um novo Activity (em vez de copyWith) para que uma descrição
        // vazia (null) realmente limpe o campo na API.
        await p.update(Activity(
          id: a.id,
          title: _title.text.trim(),
          description: desc,
          type: _type,
          status: a.status,
          dueDate: _due,
          disciplineId: _disciplineId!,
        ));
      } else {
        await p.create(
          title: _title.text.trim(),
          description: desc,
          type: _type,
          dueDate: _due,
          disciplineId: _disciplineId!,
        );
      }
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, title: 'Excluir atividade?', message: '"${widget.activity!.title}" será removida.');
    if (!ok || !mounted) return;
    try {
      await context.read<ActivitiesProvider>().remove(widget.activity!.id);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disciplines = context.watch<DisciplinesProvider>().items;

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_editing ? 'Editar atividade' : 'Nova atividade',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              if (_editing)
                IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  tooltip: 'Excluir',
                ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<ActivityType>(
            showSelectedIcon: false,
            segments: [
              for (final t in ActivityType.values)
                ButtonSegment(value: t, label: Text(t.label), icon: Icon(t.icon, size: 18)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Título'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _desc,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Descrição (opcional)', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          if (disciplines.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(12)),
              child: const Text('Cadastre uma disciplina na aba Disciplinas antes de criar atividades.',
                  style: TextStyle(color: AppColors.warning)),
            )
          else
            DropdownButtonFormField<String>(
              value: disciplines.any((d) => d.id == _disciplineId) ? _disciplineId : null,
              decoration: const InputDecoration(labelText: 'Disciplina'),
              items: [for (final d in disciplines) DropdownMenuItem(value: d.id, child: Text(d.name))],
              onChanged: (v) => setState(() => _disciplineId = v),
            ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDateTime,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Prazo', prefixIcon: Icon(Icons.event_rounded)),
              child: Text('${DateHelpers.fullDate(_due)} às ${DateHelpers.time(_due)}'),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: (_saving || disciplines.isEmpty) ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(_editing ? 'Salvar alterações' : 'Criar atividade'),
          ),
        ],
      ),
    );
  }
}