// Responsável: Eduardo Madruga
import 'package:study_planner/data/models/activity.dart';

class Discipline {
  const Discipline({
    required this.id,
    required this.name,
    this.description,
    this.average,
    this.createdAt,
    this.activities = const [],
  });

  final String id;
  final String name;
  final String? description;

  /// Média aritmética calculada pela API em GET /disciplines (null = sem notas).
  final double? average;
  final DateTime? createdAt;

  /// Só vem preenchido em GET /disciplines/:id.
  final List<Activity> activities;

  factory Discipline.fromJson(Map<String, dynamic> json) => Discipline(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        description: json['description']?.toString(),
        average: (json['average'] as num?)?.toDouble(),
        createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}')?.toLocal(),
        activities: (json['activities'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Activity.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  /// Corpo de POST/PUT /disciplines.
  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null && description!.isNotEmpty) 'description': description,
      };
}