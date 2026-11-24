// Responsável: Davi Mariano Belmont (Tela de Tarefas)
// Também usado pelo Calendário (Alisson), Dashboard e Disciplinas.
import 'package:flutter/foundation.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/activity.dart';
import 'package:study_planner/data/models/activity_query.dart';

/// Endpoints: GET/POST /activities · PUT/DELETE /activities/:id
/// `items` guarda a lista completa (usada por Início, semáforo e contadores).
/// Telas que precisam de recortes usam [fetch], que aplica os filtros no servidor.
class ActivitiesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  List<Activity> items = [];
  bool loading = false;
  String? error;

  /// true depois da primeira carga completa bem-sucedida.
  bool loadedOnce = false;

  /// Aumenta a cada mudança confirmada; telas com consulta própria se atualizam por ele.
  int revision = 0;

  List<Activity> forDiscipline(String disciplineId) =>
      items.where((a) => a.disciplineId == disciplineId).toList();

  int get pendingCount => items.where((a) => !a.isCompleted).length;

  /// GET /activities com filtros (disciplineId, status, type, from, to).
  /// Lança [ApiException] em caso de erro.
  Future<List<Activity>> fetch([ActivityQuery query = const ActivityQuery()]) async {
    final data = await _api.get('/activities', query: query.toQueryParameters());
    return ApiClient.asList(data).map(Activity.fromJson).toList();
  }

  /// Aplica numa lista vinda do servidor as mudanças locais já feitas:
  /// troca pelo estado atual (concluída/pendente) e remove o que foi excluído.
  List<Activity> overlay(List<Activity> remote) {
    if (!loadedOnce) return List<Activity>.of(remote);
    final local = {for (final a in items) a.id: a};
    return [
      for (final a in remote)
        if (local.containsKey(a.id)) local[a.id]!,
    ];
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final data = await _api.get('/activities');
      items = ApiClient.asList(data).map(Activity.fromJson).toList();
      error = null;
      loadedOnce = true;
      revision++;
    } on ApiException catch (e) {
      if (!silent || items.isEmpty) error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// Lança [ApiException] em caso de erro.
  Future<void> create({
    required String title,
    String? description,
    required ActivityType type,
    required DateTime dueDate,
    required String disciplineId,
  }) async {
    final draft = Activity(
      id: '',
      title: title,
      description: description,
      type: type,
      status: ActivityStatus.pending,
      dueDate: dueDate,
      disciplineId: disciplineId,
    );
    await _api.post('/activities', draft.toJson());
    await load(silent: true);
  }

  Future<void> update(Activity a) async {
    await _api.put('/activities/${a.id}', a.toJson(withStatus: true));
    await load(silent: true);
  }

  /// Marca como concluída/pendente com atualização imediata na tela.
  /// Retorna a mensagem de erro (ou null se deu certo); nunca lança.
  Future<String?> toggle(Activity a, bool done) async {
    final i = items.indexWhere((e) => e.id == a.id);
    if (i < 0) return null;
    final updated = a.copyWith(status: done ? ActivityStatus.completed : ActivityStatus.pending);
    items[i] = updated;
    notifyListeners();
    try {
      await _api.put('/activities/${a.id}', updated.toJson(withStatus: true));
      revision++;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      final j = items.indexWhere((x) => x.id == a.id);
      if (j >= 0) items[j] = a;
      notifyListeners();
      return e.message;
    }
  }

  Future<void> remove(String id) async {
    items.removeWhere((a) => a.id == id);
    notifyListeners();
    try {
      await _api.delete('/activities/$id');
      revision++;
      notifyListeners();
    } on ApiException {
      await load(silent: true);
      rethrow;
    }
  }
}