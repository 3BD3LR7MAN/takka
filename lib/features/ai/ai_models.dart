class ProposedEvent {
  String title;
  DateTime? start;
  DateTime? end;
  bool isAllDay;
  String category;
  String? description;
  String? location;
  bool timeMissing;
  bool suggested;
  bool selected;
  List<int> reminders; // دقائق قبل البدء
  String importance;   // normal|important|critical

  ProposedEvent({
    required this.title,
    this.start,
    this.end,
    this.isAllDay = false,
    this.category = 'other',
    this.description,
    this.location,
    this.timeMissing = false,
    this.suggested = false,
    this.selected = true,
    this.reminders = const [],
    this.importance = 'normal',
  });
}

/// مهمة مقترحة من الـAI (بند checklist بدون وقت محدد).
class ProposedTask {
  String title;
  DateTime? dueDate;
  bool selected;
  ProposedTask({required this.title, this.dueDate, this.selected = true});
}

class AiExtractionResult {
  final List<ProposedEvent> events;
  final List<ProposedTask> tasks;
  final List<String> ambiguities;
  const AiExtractionResult(this.events, this.ambiguities,
      {this.tasks = const []});
}
