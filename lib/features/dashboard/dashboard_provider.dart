// Responsável: João Pedro Meneses (Dashboard)
import 'package:flutter/foundation.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/dashboard_summary.dart';

/// Endpoint: GET /dashboard
/// (qtd. de disciplinas, qtd. de pendentes, próximas 5 atividades, média por disciplina)
class DashboardProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  DashboardSummary? summary;
  bool loading = false;
  String? error;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final data = await _api.get('/dashboard');
      if (data is Map) {
        summary = DashboardSummary.fromJson(Map<String, dynamic>.from(data));
        error = null;
      }
    } on ApiException catch (e) {
      if (!silent || summary == null) error = e.message;
    }
    loading = false;
    notifyListeners();
  }
}
