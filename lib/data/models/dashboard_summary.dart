// Responsável: João Pedro Meneses
import 'package:study_planner/data/models/activity.dart';

class DisciplineAverage {
  const DisciplineAverage({required this.disciplineId, required this.name, this.average});
  final String disciplineId;
  final String name;
  final double? average;
}

/// Resposta de GET /dashboard:
/// {
///   disciplineCount: int,
///   pendingActivities: int,
///   upcomingActivities: [Activity],
///   averages: [{ disciplineId, disciplineName, average }]
/// }
class DashboardSummary {
  const DashboardSummary({
    required this.disciplinesCount,
    required this.pendingCount,
    required this.nextActivities,
    required this.averages,
  });

  final int disciplinesCount;
  final int pendingCount;
  final List<Activity> nextActivities;
  final List<DisciplineAverage> averages;

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
        disciplinesCount: (j['disciplineCount'] as num?)?.toInt() ?? 0,
        pendingCount: (j['pendingActivities'] as num?)?.toInt() ?? 0,
        nextActivities: (j['upcomingActivities'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Activity.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        averages: (j['averages'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => DisciplineAverage(
                  disciplineId: '${e['disciplineId']}',
                  name: '${e['disciplineName']}',
                  average: (e['average'] as num?)?.toDouble(),
                ))
            .toList(),
      );
}