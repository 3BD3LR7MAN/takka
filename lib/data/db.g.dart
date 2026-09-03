// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startDtMeta =
      const VerificationMeta('startDt');
  @override
  late final GeneratedColumn<int> startDt = GeneratedColumn<int>(
      'start_dt', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endDtMeta = const VerificationMeta('endDt');
  @override
  late final GeneratedColumn<int> endDt = GeneratedColumn<int>(
      'end_dt', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isAllDayMeta =
      const VerificationMeta('isAllDay');
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
      'is_all_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_all_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _importanceMeta =
      const VerificationMeta('importance');
  @override
  late final GeneratedColumn<String> importance = GeneratedColumn<String>(
      'importance', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('normal'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        startDt,
        endDt,
        isAllDay,
        category,
        location,
        importance,
        source,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<Event> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_dt')) {
      context.handle(_startDtMeta,
          startDt.isAcceptableOrUnknown(data['start_dt']!, _startDtMeta));
    } else if (isInserting) {
      context.missing(_startDtMeta);
    }
    if (data.containsKey('end_dt')) {
      context.handle(
          _endDtMeta, endDt.isAcceptableOrUnknown(data['end_dt']!, _endDtMeta));
    } else if (isInserting) {
      context.missing(_endDtMeta);
    }
    if (data.containsKey('is_all_day')) {
      context.handle(_isAllDayMeta,
          isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('importance')) {
      context.handle(
          _importanceMeta,
          importance.isAcceptableOrUnknown(
              data['importance']!, _importanceMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      startDt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_dt'])!,
      endDt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_dt'])!,
      isAllDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_all_day'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      importance: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}importance'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final String id;
  final String title;
  final String? description;
  final int startDt;
  final int endDt;
  final bool isAllDay;
  final String category;
  final String? location;
  final String importance;
  final String source;
  final int createdAt;
  final int updatedAt;
  const Event(
      {required this.id,
      required this.title,
      this.description,
      required this.startDt,
      required this.endDt,
      required this.isAllDay,
      required this.category,
      this.location,
      required this.importance,
      required this.source,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_dt'] = Variable<int>(startDt);
    map['end_dt'] = Variable<int>(endDt);
    map['is_all_day'] = Variable<bool>(isAllDay);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['importance'] = Variable<String>(importance);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startDt: Value(startDt),
      endDt: Value(endDt),
      isAllDay: Value(isAllDay),
      category: Value(category),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      importance: Value(importance),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Event.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startDt: serializer.fromJson<int>(json['startDt']),
      endDt: serializer.fromJson<int>(json['endDt']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      category: serializer.fromJson<String>(json['category']),
      location: serializer.fromJson<String?>(json['location']),
      importance: serializer.fromJson<String>(json['importance']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startDt': serializer.toJson<int>(startDt),
      'endDt': serializer.toJson<int>(endDt),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'category': serializer.toJson<String>(category),
      'location': serializer.toJson<String?>(location),
      'importance': serializer.toJson<String>(importance),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Event copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          int? startDt,
          int? endDt,
          bool? isAllDay,
          String? category,
          Value<String?> location = const Value.absent(),
          String? importance,
          String? source,
          int? createdAt,
          int? updatedAt}) =>
      Event(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        startDt: startDt ?? this.startDt,
        endDt: endDt ?? this.endDt,
        isAllDay: isAllDay ?? this.isAllDay,
        category: category ?? this.category,
        location: location.present ? location.value : this.location,
        importance: importance ?? this.importance,
        source: source ?? this.source,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      startDt: data.startDt.present ? data.startDt.value : this.startDt,
      endDt: data.endDt.present ? data.endDt.value : this.endDt,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      category: data.category.present ? data.category.value : this.category,
      location: data.location.present ? data.location.value : this.location,
      importance:
          data.importance.present ? data.importance.value : this.importance,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startDt: $startDt, ')
          ..write('endDt: $endDt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('category: $category, ')
          ..write('location: $location, ')
          ..write('importance: $importance, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, description, startDt, endDt,
      isAllDay, category, location, importance, source, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.startDt == this.startDt &&
          other.endDt == this.endDt &&
          other.isAllDay == this.isAllDay &&
          other.category == this.category &&
          other.location == this.location &&
          other.importance == this.importance &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> startDt;
  final Value<int> endDt;
  final Value<bool> isAllDay;
  final Value<String> category;
  final Value<String?> location;
  final Value<String> importance;
  final Value<String> source;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startDt = const Value.absent(),
    this.endDt = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.category = const Value.absent(),
    this.location = const Value.absent(),
    this.importance = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required int startDt,
    required int endDt,
    this.isAllDay = const Value.absent(),
    this.category = const Value.absent(),
    this.location = const Value.absent(),
    this.importance = const Value.absent(),
    this.source = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        startDt = Value(startDt),
        endDt = Value(endDt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Event> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? startDt,
    Expression<int>? endDt,
    Expression<bool>? isAllDay,
    Expression<String>? category,
    Expression<String>? location,
    Expression<String>? importance,
    Expression<String>? source,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startDt != null) 'start_dt': startDt,
      if (endDt != null) 'end_dt': endDt,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (category != null) 'category': category,
      if (location != null) 'location': location,
      if (importance != null) 'importance': importance,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<int>? startDt,
      Value<int>? endDt,
      Value<bool>? isAllDay,
      Value<String>? category,
      Value<String?>? location,
      Value<String>? importance,
      Value<String>? source,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return EventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDt: startDt ?? this.startDt,
      endDt: endDt ?? this.endDt,
      isAllDay: isAllDay ?? this.isAllDay,
      category: category ?? this.category,
      location: location ?? this.location,
      importance: importance ?? this.importance,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startDt.present) {
      map['start_dt'] = Variable<int>(startDt.value);
    }
    if (endDt.present) {
      map['end_dt'] = Variable<int>(endDt.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (importance.present) {
      map['importance'] = Variable<String>(importance.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startDt: $startDt, ')
          ..write('endDt: $endDt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('category: $category, ')
          ..write('location: $location, ')
          ..write('importance: $importance, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES events (id) ON DELETE CASCADE'));
  static const VerificationMeta _offsetMinutesMeta =
      const VerificationMeta('offsetMinutes');
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
      'offset_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _notifiedMeta =
      const VerificationMeta('notified');
  @override
  late final GeneratedColumn<bool> notified = GeneratedColumn<bool>(
      'notified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("notified" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, eventId, offsetMinutes, notified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(Insertable<Reminder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
          _offsetMinutesMeta,
          offsetMinutes.isAcceptableOrUnknown(
              data['offset_minutes']!, _offsetMinutesMeta));
    } else if (isInserting) {
      context.missing(_offsetMinutesMeta);
    }
    if (data.containsKey('notified')) {
      context.handle(_notifiedMeta,
          notified.isAcceptableOrUnknown(data['notified']!, _notifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      offsetMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}offset_minutes'])!,
      notified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}notified'])!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final String id;
  final String eventId;
  final int offsetMinutes;
  final bool notified;
  const Reminder(
      {required this.id,
      required this.eventId,
      required this.offsetMinutes,
      required this.notified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['offset_minutes'] = Variable<int>(offsetMinutes);
    map['notified'] = Variable<bool>(notified);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      eventId: Value(eventId),
      offsetMinutes: Value(offsetMinutes),
      notified: Value(notified),
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      offsetMinutes: serializer.fromJson<int>(json['offsetMinutes']),
      notified: serializer.fromJson<bool>(json['notified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'offsetMinutes': serializer.toJson<int>(offsetMinutes),
      'notified': serializer.toJson<bool>(notified),
    };
  }

  Reminder copyWith(
          {String? id, String? eventId, int? offsetMinutes, bool? notified}) =>
      Reminder(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        offsetMinutes: offsetMinutes ?? this.offsetMinutes,
        notified: notified ?? this.notified,
      );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
      notified: data.notified.present ? data.notified.value : this.notified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('notified: $notified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventId, offsetMinutes, notified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.offsetMinutes == this.offsetMinutes &&
          other.notified == this.notified);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<int> offsetMinutes;
  final Value<bool> notified;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.notified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String eventId,
    required int offsetMinutes,
    this.notified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        eventId = Value(eventId),
        offsetMinutes = Value(offsetMinutes);
  static Insertable<Reminder> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<int>? offsetMinutes,
    Expression<bool>? notified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (notified != null) 'notified': notified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith(
      {Value<String>? id,
      Value<String>? eventId,
      Value<int>? offsetMinutes,
      Value<bool>? notified,
      Value<int>? rowid}) {
    return RemindersCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      notified: notified ?? this.notified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (notified.present) {
      map['notified'] = Variable<bool>(notified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('notified: $notified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduledNotificationsTable extends ScheduledNotifications
    with TableInfo<$ScheduledNotificationsTable, ScheduledNotifRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduledNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _reminderIdMeta =
      const VerificationMeta('reminderId');
  @override
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
      'reminder_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES reminders (id) ON DELETE CASCADE'));
  static const VerificationMeta _triggerAtMeta =
      const VerificationMeta('triggerAt');
  @override
  late final GeneratedColumn<int> triggerAt = GeneratedColumn<int>(
      'trigger_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _androidNotifIdMeta =
      const VerificationMeta('androidNotifId');
  @override
  late final GeneratedColumn<int> androidNotifId = GeneratedColumn<int>(
      'android_notif_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, reminderId, triggerAt, androidNotifId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduled_notifications';
  @override
  VerificationContext validateIntegrity(Insertable<ScheduledNotifRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
          _reminderIdMeta,
          reminderId.isAcceptableOrUnknown(
              data['reminder_id']!, _reminderIdMeta));
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
    if (data.containsKey('trigger_at')) {
      context.handle(_triggerAtMeta,
          triggerAt.isAcceptableOrUnknown(data['trigger_at']!, _triggerAtMeta));
    } else if (isInserting) {
      context.missing(_triggerAtMeta);
    }
    if (data.containsKey('android_notif_id')) {
      context.handle(
          _androidNotifIdMeta,
          androidNotifId.isAcceptableOrUnknown(
              data['android_notif_id']!, _androidNotifIdMeta));
    } else if (isInserting) {
      context.missing(_androidNotifIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduledNotifRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduledNotifRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      reminderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reminder_id'])!,
      triggerAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trigger_at'])!,
      androidNotifId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}android_notif_id'])!,
    );
  }

  @override
  $ScheduledNotificationsTable createAlias(String alias) {
    return $ScheduledNotificationsTable(attachedDatabase, alias);
  }
}

class ScheduledNotifRow extends DataClass
    implements Insertable<ScheduledNotifRow> {
  final int id;
  final String reminderId;
  final int triggerAt;
  final int androidNotifId;
  const ScheduledNotifRow(
      {required this.id,
      required this.reminderId,
      required this.triggerAt,
      required this.androidNotifId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reminder_id'] = Variable<String>(reminderId);
    map['trigger_at'] = Variable<int>(triggerAt);
    map['android_notif_id'] = Variable<int>(androidNotifId);
    return map;
  }

  ScheduledNotificationsCompanion toCompanion(bool nullToAbsent) {
    return ScheduledNotificationsCompanion(
      id: Value(id),
      reminderId: Value(reminderId),
      triggerAt: Value(triggerAt),
      androidNotifId: Value(androidNotifId),
    );
  }

  factory ScheduledNotifRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduledNotifRow(
      id: serializer.fromJson<int>(json['id']),
      reminderId: serializer.fromJson<String>(json['reminderId']),
      triggerAt: serializer.fromJson<int>(json['triggerAt']),
      androidNotifId: serializer.fromJson<int>(json['androidNotifId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reminderId': serializer.toJson<String>(reminderId),
      'triggerAt': serializer.toJson<int>(triggerAt),
      'androidNotifId': serializer.toJson<int>(androidNotifId),
    };
  }

  ScheduledNotifRow copyWith(
          {int? id, String? reminderId, int? triggerAt, int? androidNotifId}) =>
      ScheduledNotifRow(
        id: id ?? this.id,
        reminderId: reminderId ?? this.reminderId,
        triggerAt: triggerAt ?? this.triggerAt,
        androidNotifId: androidNotifId ?? this.androidNotifId,
      );
  ScheduledNotifRow copyWithCompanion(ScheduledNotificationsCompanion data) {
    return ScheduledNotifRow(
      id: data.id.present ? data.id.value : this.id,
      reminderId:
          data.reminderId.present ? data.reminderId.value : this.reminderId,
      triggerAt: data.triggerAt.present ? data.triggerAt.value : this.triggerAt,
      androidNotifId: data.androidNotifId.present
          ? data.androidNotifId.value
          : this.androidNotifId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledNotifRow(')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('triggerAt: $triggerAt, ')
          ..write('androidNotifId: $androidNotifId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reminderId, triggerAt, androidNotifId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledNotifRow &&
          other.id == this.id &&
          other.reminderId == this.reminderId &&
          other.triggerAt == this.triggerAt &&
          other.androidNotifId == this.androidNotifId);
}

class ScheduledNotificationsCompanion
    extends UpdateCompanion<ScheduledNotifRow> {
  final Value<int> id;
  final Value<String> reminderId;
  final Value<int> triggerAt;
  final Value<int> androidNotifId;
  const ScheduledNotificationsCompanion({
    this.id = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.triggerAt = const Value.absent(),
    this.androidNotifId = const Value.absent(),
  });
  ScheduledNotificationsCompanion.insert({
    this.id = const Value.absent(),
    required String reminderId,
    required int triggerAt,
    required int androidNotifId,
  })  : reminderId = Value(reminderId),
        triggerAt = Value(triggerAt),
        androidNotifId = Value(androidNotifId);
  static Insertable<ScheduledNotifRow> custom({
    Expression<int>? id,
    Expression<String>? reminderId,
    Expression<int>? triggerAt,
    Expression<int>? androidNotifId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reminderId != null) 'reminder_id': reminderId,
      if (triggerAt != null) 'trigger_at': triggerAt,
      if (androidNotifId != null) 'android_notif_id': androidNotifId,
    });
  }

  ScheduledNotificationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? reminderId,
      Value<int>? triggerAt,
      Value<int>? androidNotifId}) {
    return ScheduledNotificationsCompanion(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      triggerAt: triggerAt ?? this.triggerAt,
      androidNotifId: androidNotifId ?? this.androidNotifId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
    }
    if (triggerAt.present) {
      map['trigger_at'] = Variable<int>(triggerAt.value);
    }
    if (androidNotifId.present) {
      map['android_notif_id'] = Variable<int>(androidNotifId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('triggerAt: $triggerAt, ')
          ..write('androidNotifId: $androidNotifId')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
      'done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
      'due_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, title, done, dueDate, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
          _doneMeta, done.isAcceptableOrUnknown(data['done']!, _doneMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      done: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}done'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}due_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final bool done;
  final int? dueDate;
  final int createdAt;
  const Task(
      {required this.id,
      required this.title,
      required this.done,
      this.dueDate,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['done'] = Variable<bool>(done);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<int>(dueDate);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      done: Value(done),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      createdAt: Value(createdAt),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      done: serializer.fromJson<bool>(json['done']),
      dueDate: serializer.fromJson<int?>(json['dueDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'done': serializer.toJson<bool>(done),
      'dueDate': serializer.toJson<int?>(dueDate),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Task copyWith(
          {String? id,
          String? title,
          bool? done,
          Value<int?> dueDate = const Value.absent(),
          int? createdAt}) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        done: done ?? this.done,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        createdAt: createdAt ?? this.createdAt,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      done: data.done.present ? data.done.value : this.done,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('dueDate: $dueDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, done, dueDate, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.done == this.done &&
          other.dueDate == this.dueDate &&
          other.createdAt == this.createdAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<bool> done;
  final Value<int?> dueDate;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.done = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.done = const Value.absent(),
    this.dueDate = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<bool>? done,
    Expression<int>? dueDate,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (done != null) 'done': done,
      if (dueDate != null) 'due_date': dueDate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<bool>? done,
      Value<int?>? dueDate,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('dueDate: $dueDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $ScheduledNotificationsTable scheduledNotifications =
      $ScheduledNotificationsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [events, reminders, scheduledNotifications, tasks];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('events',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('reminders', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('reminders',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('scheduled_notifications', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  required int startDt,
  required int endDt,
  Value<bool> isAllDay,
  Value<String> category,
  Value<String?> location,
  Value<String> importance,
  Value<String> source,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<int> startDt,
  Value<int> endDt,
  Value<bool> isAllDay,
  Value<String> category,
  Value<String?> location,
  Value<String> importance,
  Value<String> source,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, Event> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
      _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.reminders,
          aliasName: $_aliasNameGenerator(db.events.id, db.reminders.eventId));

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager($_db, $_db.reminders)
        .filter((f) => f.eventId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startDt => $composableBuilder(
      column: $table.startDt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endDt => $composableBuilder(
      column: $table.endDt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAllDay => $composableBuilder(
      column: $table.isAllDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> remindersRefs(
      Expression<bool> Function($$RemindersTableFilterComposer f) f) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableFilterComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startDt => $composableBuilder(
      column: $table.startDt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endDt => $composableBuilder(
      column: $table.endDt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
      column: $table.isAllDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get startDt =>
      $composableBuilder(column: $table.startDt, builder: (column) => column);

  GeneratedColumn<int> get endDt =>
      $composableBuilder(column: $table.endDt, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> remindersRefs<T extends Object>(
      Expression<T> Function($$RemindersTableAnnotationComposer a) f) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableAnnotationComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, $$EventsTableReferences),
    Event,
    PrefetchHooks Function({bool remindersRefs})> {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> startDt = const Value.absent(),
            Value<int> endDt = const Value.absent(),
            Value<bool> isAllDay = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String> importance = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EventsCompanion(
            id: id,
            title: title,
            description: description,
            startDt: startDt,
            endDt: endDt,
            isAllDay: isAllDay,
            category: category,
            location: location,
            importance: importance,
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            required int startDt,
            required int endDt,
            Value<bool> isAllDay = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String> importance = const Value.absent(),
            Value<String> source = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              EventsCompanion.insert(
            id: id,
            title: title,
            description: description,
            startDt: startDt,
            endDt: endDt,
            isAllDay: isAllDay,
            category: category,
            location: location,
            importance: importance,
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EventsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({remindersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (remindersRefs) db.reminders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (remindersRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$EventsTableReferences._remindersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventsTableReferences(db, table, p0)
                                .remindersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.eventId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, $$EventsTableReferences),
    Event,
    PrefetchHooks Function({bool remindersRefs})>;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  required String eventId,
  required int offsetMinutes,
  Value<bool> notified,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<String> eventId,
  Value<int> offsetMinutes,
  Value<bool> notified,
  Value<int> rowid,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) => db.events
      .createAlias($_aliasNameGenerator(db.reminders.eventId, db.events.id));

  $$EventsTableProcessedTableManager get eventId {
    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.id($_item.eventId));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ScheduledNotificationsTable,
      List<ScheduledNotifRow>> _scheduledNotificationsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.scheduledNotifications,
          aliasName: $_aliasNameGenerator(
              db.reminders.id, db.scheduledNotifications.reminderId));

  $$ScheduledNotificationsTableProcessedTableManager
      get scheduledNotificationsRefs {
    final manager = $$ScheduledNotificationsTableTableManager(
            $_db, $_db.scheduledNotifications)
        .filter((f) => f.reminderId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_scheduledNotificationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
      column: $table.offsetMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notified => $composableBuilder(
      column: $table.notified, builder: (column) => ColumnFilters(column));

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> scheduledNotificationsRefs(
      Expression<bool> Function($$ScheduledNotificationsTableFilterComposer f)
          f) {
    final $$ScheduledNotificationsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.scheduledNotifications,
            getReferencedColumn: (t) => t.reminderId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ScheduledNotificationsTableFilterComposer(
                  $db: $db,
                  $table: $db.scheduledNotifications,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
      column: $table.offsetMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notified => $composableBuilder(
      column: $table.notified, builder: (column) => ColumnOrderings(column));

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableOrderingComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
      column: $table.offsetMinutes, builder: (column) => column);

  GeneratedColumn<bool> get notified =>
      $composableBuilder(column: $table.notified, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> scheduledNotificationsRefs<T extends Object>(
      Expression<T> Function($$ScheduledNotificationsTableAnnotationComposer a)
          f) {
    final $$ScheduledNotificationsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.scheduledNotifications,
            getReferencedColumn: (t) => t.reminderId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ScheduledNotificationsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.scheduledNotifications,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$RemindersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemindersTable,
    Reminder,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (Reminder, $$RemindersTableReferences),
    Reminder,
    PrefetchHooks Function({bool eventId, bool scheduledNotificationsRefs})> {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<int> offsetMinutes = const Value.absent(),
            Value<bool> notified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion(
            id: id,
            eventId: eventId,
            offsetMinutes: offsetMinutes,
            notified: notified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String eventId,
            required int offsetMinutes,
            Value<bool> notified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion.insert(
            id: id,
            eventId: eventId,
            offsetMinutes: offsetMinutes,
            notified: notified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RemindersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {eventId = false, scheduledNotificationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (scheduledNotificationsRefs) db.scheduledNotifications
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable:
                        $$RemindersTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$RemindersTableReferences._eventIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scheduledNotificationsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$RemindersTableReferences
                            ._scheduledNotificationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RemindersTableReferences(db, table, p0)
                                .scheduledNotificationsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.reminderId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RemindersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RemindersTable,
    Reminder,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (Reminder, $$RemindersTableReferences),
    Reminder,
    PrefetchHooks Function({bool eventId, bool scheduledNotificationsRefs})>;
typedef $$ScheduledNotificationsTableCreateCompanionBuilder
    = ScheduledNotificationsCompanion Function({
  Value<int> id,
  required String reminderId,
  required int triggerAt,
  required int androidNotifId,
});
typedef $$ScheduledNotificationsTableUpdateCompanionBuilder
    = ScheduledNotificationsCompanion Function({
  Value<int> id,
  Value<String> reminderId,
  Value<int> triggerAt,
  Value<int> androidNotifId,
});

final class $$ScheduledNotificationsTableReferences extends BaseReferences<
    _$AppDatabase, $ScheduledNotificationsTable, ScheduledNotifRow> {
  $$ScheduledNotificationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RemindersTable _reminderIdTable(_$AppDatabase db) =>
      db.reminders.createAlias($_aliasNameGenerator(
          db.scheduledNotifications.reminderId, db.reminders.id));

  $$RemindersTableProcessedTableManager get reminderId {
    final manager = $$RemindersTableTableManager($_db, $_db.reminders)
        .filter((f) => f.id($_item.reminderId));
    final item = $_typedResult.readTableOrNull(_reminderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ScheduledNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get triggerAt => $composableBuilder(
      column: $table.triggerAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get androidNotifId => $composableBuilder(
      column: $table.androidNotifId,
      builder: (column) => ColumnFilters(column));

  $$RemindersTableFilterComposer get reminderId {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.reminderId,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableFilterComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScheduledNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get triggerAt => $composableBuilder(
      column: $table.triggerAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get androidNotifId => $composableBuilder(
      column: $table.androidNotifId,
      builder: (column) => ColumnOrderings(column));

  $$RemindersTableOrderingComposer get reminderId {
    final $$RemindersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.reminderId,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableOrderingComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScheduledNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get triggerAt =>
      $composableBuilder(column: $table.triggerAt, builder: (column) => column);

  GeneratedColumn<int> get androidNotifId => $composableBuilder(
      column: $table.androidNotifId, builder: (column) => column);

  $$RemindersTableAnnotationComposer get reminderId {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.reminderId,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableAnnotationComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScheduledNotificationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScheduledNotificationsTable,
    ScheduledNotifRow,
    $$ScheduledNotificationsTableFilterComposer,
    $$ScheduledNotificationsTableOrderingComposer,
    $$ScheduledNotificationsTableAnnotationComposer,
    $$ScheduledNotificationsTableCreateCompanionBuilder,
    $$ScheduledNotificationsTableUpdateCompanionBuilder,
    (ScheduledNotifRow, $$ScheduledNotificationsTableReferences),
    ScheduledNotifRow,
    PrefetchHooks Function({bool reminderId})> {
  $$ScheduledNotificationsTableTableManager(
      _$AppDatabase db, $ScheduledNotificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduledNotificationsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduledNotificationsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduledNotificationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> reminderId = const Value.absent(),
            Value<int> triggerAt = const Value.absent(),
            Value<int> androidNotifId = const Value.absent(),
          }) =>
              ScheduledNotificationsCompanion(
            id: id,
            reminderId: reminderId,
            triggerAt: triggerAt,
            androidNotifId: androidNotifId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String reminderId,
            required int triggerAt,
            required int androidNotifId,
          }) =>
              ScheduledNotificationsCompanion.insert(
            id: id,
            reminderId: reminderId,
            triggerAt: triggerAt,
            androidNotifId: androidNotifId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ScheduledNotificationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({reminderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (reminderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.reminderId,
                    referencedTable: $$ScheduledNotificationsTableReferences
                        ._reminderIdTable(db),
                    referencedColumn: $$ScheduledNotificationsTableReferences
                        ._reminderIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ScheduledNotificationsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ScheduledNotificationsTable,
        ScheduledNotifRow,
        $$ScheduledNotificationsTableFilterComposer,
        $$ScheduledNotificationsTableOrderingComposer,
        $$ScheduledNotificationsTableAnnotationComposer,
        $$ScheduledNotificationsTableCreateCompanionBuilder,
        $$ScheduledNotificationsTableUpdateCompanionBuilder,
        (ScheduledNotifRow, $$ScheduledNotificationsTableReferences),
        ScheduledNotifRow,
        PrefetchHooks Function({bool reminderId})>;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  Value<bool> done,
  Value<int?> dueDate,
  required int createdAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<bool> done,
  Value<int?> dueDate,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get done => $composableBuilder(
      column: $table.done, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get done => $composableBuilder(
      column: $table.done, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<bool> done = const Value.absent(),
            Value<int?> dueDate = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            title: title,
            done: done,
            dueDate: dueDate,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<bool> done = const Value.absent(),
            Value<int?> dueDate = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            title: title,
            done: done,
            dueDate: dueDate,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$ScheduledNotificationsTableTableManager get scheduledNotifications =>
      $$ScheduledNotificationsTableTableManager(
          _db, _db.scheduledNotifications);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
}
