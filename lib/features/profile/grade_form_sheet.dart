// Responsável: João Pedro Meneses
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/utils/date_utils.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/grade.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';
import 'package:study_planner/features/profile/grades_provider.dart';

/// Formulário para lançar, editar ou excluir uma nota (0 a 10) com a data da avaliação.
class GradeFormSheet extends StatefulWidget {
  const GradeFormSheet({super.key, this.grade, this.disciplineId});
  final Grade? grade;
  final String? disciplineId;

  static Future<void> show(BuildContext context, {Grade? grade, String? disciplineId}) =>
      showFormSheet(context, GradeFormSheet(grade: grade, disciplineId: disciplineId));

  @override
  State<GradeFormSheet> createState() => _GradeFormSheetState();
}

class _GradeFormSheetState extends State<GradeFormSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _value;
  late final TextEditingController _desc;
  String? _disciplineId;
  late DateTime _date;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.grade != null;

  @override
  void initState() {
    super.initState();
    final g = widget.grade;
    _value = TextEditingController(text: g == null ? '' : fmtGrade(g.value));
    _desc = TextEditingController(text: g?.description);
    _disciplineId = g?.disciplineId ?? widget.disciplineId;
    _date = g?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _value.dispose();
    _desc.dispose();
    super.dispose();
  }

  double? _parse(String? s) => double.tryParse((s ?? '').trim().replaceAll(',', '.'));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day, 12));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_disciplineId == null) {
      setState(() => _error = 'Escolha a disciplina da nota.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final p = context.read<GradesProvider>();
    final disciplines = context.read<DisciplinesProvider>();
    final value = _parse(_value.text)!;
    try {
      if (_editing) {
        await p.update(widget.grade!, value, _desc.text.trim(), _date);
      } else {
        await p.create(value, _desc.text.trim(), _disciplineId!, _date);
      }
      // A média da disciplina é calculada pela API: recarrega para refletir a nota.
      disciplines.load(silent: true);
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
    final ok = await confirmDialog(context, title: 'Excluir nota?', message: 'A média da disciplina será recalculada.');
    if (!ok || !mounted) return;
    final disciplines = context.read<DisciplinesProvider>();
    try {
      await context.read<GradesProvider>().remove(widget.grade!.id);
      disciplines.load(silent: true);
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
                child: Text(_editing ? 'Editar nota' : 'Lançar nota',
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
          if (disciplines.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(12)),
              child: const Text('Cadastre uma disciplina antes de lançar notas.', style: TextStyle(color: AppColors.warning)),
            )
          else
            DropdownButtonFormField<String>(
              value: disciplines.any((d) => d.id == _disciplineId) ? _disciplineId : null,
              decoration: const InputDecoration(labelText: 'Disciplina'),
              items: [for (final d in disciplines) DropdownMenuItem(value: d.id, child: Text(d.name))],
              onChanged: _editing ? null : (v) => setState(() => _disciplineId = v),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: TextFormField(
                  controller: _value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Nota'),
                  validator: (v) {
                    final n = _parse(v);
                    if (n == null) return 'Informe a nota';
                    if (n < 0 || n > 10) return 'De 0 a 10';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _desc,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Descrição', hintText: 'Ex.: Prova 1'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Data da avaliação', prefixIcon: Icon(Icons.event_rounded)),
              child: Text(DateHelpers.fullDate(_date)),
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
                : Text(_editing ? 'Salvar alterações' : 'Lançar nota'),
          ),
        ],
      ),
    );
  }
}