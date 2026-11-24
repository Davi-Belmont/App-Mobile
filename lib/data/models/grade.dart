// Responsável: João Pedro Meneses
class Grade {
  const Grade({
    required this.id,
    required this.value,
    required this.description,
    required this.disciplineId,
    required this.date,
  });

  final String id;
  final double value; // 0 a 10
  final String description;
  final String disciplineId;
  final DateTime date; // data da avaliação (campo `date` da API)

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        id: json['id'].toString(),
        value: (json['value'] as num).toDouble(),
        description: (json['description'] ?? '').toString(),
        disciplineId: (json['disciplineId'] ?? json['discipline']?['id'] ?? '').toString(),
        date: DateTime.tryParse('${json['date'] ?? ''}')?.toLocal() ?? DateTime.now(),
      );

  /// Corpo de POST/PUT /grades.
  Map<String, dynamic> toJson() => {
        'value': value,
        'description': description,
        'disciplineId': disciplineId,
        'date': date.toUtc().toIso8601String(),
      };
}