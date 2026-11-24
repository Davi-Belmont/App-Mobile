// Responsável: João Pedro Meneses (Tela de Perfil/Notas)
import 'package:flutter/foundation.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/grade.dart';

/// Endpoints: GET (com ?disciplineId=) / POST /grades · PUT/DELETE /grades/:id
/// Regras da API: nota de 0 a 10 e média aritmética simples.
class GradesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  List<Grade> items = [];
  bool loading = false;
  String? error;

  /// Aumenta a cada mudança confirmada; telas com consulta própria se atualizam por ele.
  int revision = 0;

  List<Grade> forDiscipline(String disciplineId) =>
      items.where((g) => g.disciplineId == disciplineId).toList();

  /// Reserva local. As telas usam a média que vem da API (Discipline.average).
  double? averageOf(String disciplineId) {
    final list = forDiscipline(disciplineId);
    if (list.isEmpty) return null;
    return list.fold<double>(0, (s, g) => s + g.value) / list.length;
  }

  /// GET /grades (opcionalmente só de uma disciplina). A API já devolve
  /// ordenado pela data, da mais recente para a mais antiga.
  /// Lança [ApiException] em caso de erro.
  Future<List<Grade>> fetch({String? disciplineId}) async {
    final data = await _api.get(
      '/grades',
      query: {if (disciplineId != null) 'disciplineId': disciplineId},
    );
    return ApiClient.asList(data).map(Grade.fromJson).toList();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      items = await fetch();
      error = null;
      revision++;
    } on ApiException catch (e) {
      if (!silent || items.isEmpty) error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// Lança [ApiException] em caso de erro.
  Future<void> create(double value, String description, String disciplineId, DateTime date) async {
    await _api.post('/grades', {
      'value': value,
      'description': description,
      'disciplineId': disciplineId,
      'date': date.toUtc().toIso8601String(),
    });
    await load(silent: true);
  }

  Future<void> update(Grade g, double value, String description, DateTime date) async {
    await _api.put('/grades/${g.id}', {
      'value': value,
      'description': description,
      'disciplineId': g.disciplineId,
      'date': date.toUtc().toIso8601String(),
    });
    await load(silent: true);
  }

  Future<void> remove(String id) async {
    await _api.delete('/grades/$id');
    items.removeWhere((g) => g.id == id);
    revision++;
    notifyListeners();
  }
}