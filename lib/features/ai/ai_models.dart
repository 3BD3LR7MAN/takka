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
  String importance; // normal|important|critical

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

class ProposedUpdate {
  final String matchTitle;
  final String kind;
  String? newTitle;
  String? newCategory;
  String? newImportance;
  String? newLocation;
  DateTime? newStart;
  DateTime? newEnd;
  List<int>? reminders;
  String? matchedId;
  bool selected;

  ProposedUpdate({
    required this.matchTitle,
    this.kind = 'event',
    this.newTitle,
    this.newCategory,
    this.newImportance,
    this.newLocation,
    this.newStart,
    this.newEnd,
    this.reminders,
    this.matchedId,
    this.selected = true,
  });

  bool get matched => matchedId != null;
}

class ProposedDelete {
  final String matchTitle;
  final String kind;
  String? matchedId;
  bool selected;

  ProposedDelete({
    required this.matchTitle,
    this.kind = 'event',
    this.matchedId,
    this.selected = true,
  });

  bool get matched => matchedId != null;
}

class AiExtractionResult {
  final List<ProposedEvent> events;
  final List<ProposedTask> tasks;
  final List<String> ambiguities;
  final List<ProposedUpdate> updates;
  final List<ProposedDelete> deletes;
  const AiExtractionResult(
    this.events,
    this.ambiguities, {
    this.tasks = const [],
    this.updates = const [],
    this.deletes = const [],
  });
}
