// Responsável: Davi Mariano Belmont
enum ActivityType {
  task,
  exam,
  assignment;

  String get api => switch (this) {
        ActivityType.task => 'TASK',
        ActivityType.exam => 'EXAM',
        ActivityType.assignment => 'ASSIGNMENT',
      };

  String get label => switch (this) {
        ActivityType.task => 'Tarefa',
        ActivityType.exam => 'Prova',
        ActivityType.assignment => 'Trabalho',
      };

  static ActivityType parse(String? v) => ActivityType.values.firstWhere(
        (e) => e.api == v?.toUpperCase(),
        orElse: () => ActivityType.task,
      );
}

enum ActivityStatus {
  pending,
  completed;

  String get api => this == ActivityStatus.pending ? 'PENDING' : 'COMPLETED';

  static ActivityStatus parse(String? v) =>
      v?.toUpperCase() == 'COMPLETED' ? ActivityStatus.completed : ActivityStatus.pending;
}

/// Nível de urgência usado no "semáforo da semana".
enum Urgency { overdue, urgent, soon, ok }

class Activity {
  const Activity({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.status,
    required this.dueDate,
    required this.disciplineId,
  });

  final String id;
  final String title;
  final String? description;
  final ActivityType type;
  final ActivityStatus status;
  final DateTime dueDate;
  final String disciplineId;

  bool get isCompleted => status == ActivityStatus.completed;

  Urgency get urgency {
    if (isCompleted) return Urgency.ok;
    final diff = dueDate.difference(DateTime.now());
    if (diff.isNegative) return Urgency.overdue;
    if (diff.inHours <= 48) return Urgency.urgent;
    if (diff.inDays <= 7) return Urgency.soon;
    return Urgency.ok;
  }

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'].toString(),
        title: (json['title'] ?? '').toString(),
        description: json['description']?.toString(),
        type: ActivityType.parse(json['type']?.toString()),
        status: ActivityStatus.parse(json['status']?.toString()),
        dueDate: DateTime.parse(json['dueDate'].toString()).toLocal(),
        disciplineId: (json['disciplineId'] ?? json['discipline']?['id'] ?? '').toString(),
      );

  /// Corpo de POST/PUT /activities.
  /// A descrição é sempre enviada: vazia vira null, o que limpa o campo na API.
  Map<String, dynamic> toJson({bool withStatus = false}) => {
        'title': title,
        'description': (description == null || description!.isEmpty) ? null : description,
        'type': type.api,
        'dueDate': dueDate.toUtc().toIso8601String(),
        'disciplineId': disciplineId,
        if (withStatus) 'status': status.api,
      };

  /// Atenção: passar `description: null` mantém a descrição atual.
  /// Para limpar a descrição, crie um novo [Activity] (como o formulário faz).
  Activity copyWith({
    String? title,
    String? description,
    ActivityType? type,
    ActivityStatus? status,
    DateTime? dueDate,
    String? disciplineId,
  }) =>
      Activity(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        disciplineId: disciplineId ?? this.disciplineId,
      );
}