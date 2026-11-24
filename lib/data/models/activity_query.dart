import 'package:study_planner/data/models/activity.dart';

/// Filtros aceitos por GET /activities: disciplineId, status, type, from, to.
class ActivityQuery {
  const ActivityQuery({this.disciplineId, this.status, this.type, this.from, this.to});

  final String? disciplineId;
  final ActivityStatus? status;
  final ActivityType? type;
  final DateTime? from;
  final DateTime? to;

  Map<String, String> toQueryParameters() => {
        if (disciplineId != null) 'disciplineId': disciplineId!,
        if (status != null) 'status': status!.api,
        if (type != null) 'type': type!.api,
        if (from != null) 'from': from!.toUtc().toIso8601String(),
        if (to != null) 'to': to!.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is ActivityQuery &&
      other.disciplineId == disciplineId &&
      other.status == status &&
      other.type == type &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(disciplineId, status, type, from, to);
}