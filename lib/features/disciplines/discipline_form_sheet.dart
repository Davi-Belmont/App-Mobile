// Responsável: Eduardo Madruga
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/core/widgets/common_widgets.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/discipline.dart';
import 'package:study_planner/features/disciplines/disciplines_provider.dart';

class DisciplineFormSheet extends StatefulWidget {
  const DisciplineFormSheet({super.key, this.discipline});
  final Discipline? discipline;

  static Future<void> show(BuildContext context, {Discipline? discipline}) =>
      showFormSheet(context, DisciplineFormSheet(discipline: discipline));

  @override
  State<DisciplineFormSheet> createState() => _DisciplineFormSheetState();
}

class _DisciplineFormSheetState extends State<DisciplineFormSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.discipline != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.discipline?.name);
    _desc = TextEditingController(text: widget.discipline?.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final p = context.read<DisciplinesProvider>();
    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();
    try {
      if (_editing) {
        await p.update(widget.discipline!.id, _name.text.trim(), desc);
      } else {
        await p.create(_name.text.trim(), desc);
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_editing ? 'Editar disciplina' : 'Nova disciplina',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nome da disciplina', prefixIcon: Icon(Icons.menu_book_rounded)),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome da disciplina' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _desc,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Descrição (opcional)', alignLabelWithHint: true),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text(_editing ? 'Salvar alterações' : 'Criar disciplina'),
          ),
        ],
      ),
    );
  }
}
