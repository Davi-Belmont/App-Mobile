// Responsável: Eduardo Madruga (lógica de salvamento de matérias)
import 'package:flutter/foundation.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/discipline.dart';

/// Endpoints: GET/POST /disciplines · GET/PUT/DELETE /disciplines/:id
class DisciplinesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  List<Discipline> items = [];
  bool loading = false;
  String? error;

  Discipline? byId(String? id) {
    for (final d in items) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Média da disciplina calculada pela API (null se não há notas).
  double? averageOf(String id) => byId(id)?.average;

  /// Média geral: média das médias (vindas da API) das disciplinas com nota.
  double? get overallAverage {
    final avgs = items.map((d) => d.average).whereType<double>().toList();
    if (avgs.isEmpty) return null;
    return avgs.reduce((a, b) => a + b) / avgs.length;
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final data = await _api.get('/disciplines');
      items = ApiClient.asList(data).map(Discipline.fromJson).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      error = null;
    } on ApiException catch (e) {
      if (!silent || items.isEmpty) error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// GET /disciplines/:id — disciplina com suas atividades.
  /// Lança [ApiException] em caso de erro.
  Future<Discipline> fetchById(String id) async {
    final data = await _api.get('/disciplines/$id');
    if (data is! Map) throw const ApiException('Resposta inválida do servidor.');
    return Discipline.fromJson(Map<String, dynamic>.from(data));
  }

  /// Lança [ApiException] em caso de erro (a tela mostra a mensagem).
  Future<void> create(String name, String? description) async {
    await _api.post('/disciplines', Discipline(id: '', name: name, description: description).toJson());
    await load(silent: true);
  }

  Future<void> update(String id, String name, String? description) async {
    await _api.put('/disciplines/$id', {'name': name, 'description': description ?? ''});
    await load(silent: true);
  }

  /// A API também exclui as atividades e notas da disciplina.
  Future<void> remove(String id) async {
    await _api.delete('/disciplines/$id');
    items.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}