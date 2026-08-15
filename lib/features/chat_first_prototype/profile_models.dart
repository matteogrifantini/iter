import 'package:flutter/foundation.dart';

enum AvailabilityKind { free, work }

@immutable
class AvailabilityEntry {
  factory AvailabilityEntry({
    required String id,
    required DateTime date,
    required AvailabilityKind kind,
    required String timeRange,
    String note = '',
  }) {
    return AvailabilityEntry._(
      id: id,
      date: _dateOnly(date),
      kind: kind,
      timeRange: timeRange,
      note: note,
    );
  }

  const AvailabilityEntry._({
    required this.id,
    required this.date,
    required this.kind,
    required this.timeRange,
    required this.note,
  });

  final String id;
  final DateTime date;
  final AvailabilityKind kind;
  final String timeRange;
  final String note;

  AvailabilityEntry copyWith({
    String? id,
    DateTime? date,
    AvailabilityKind? kind,
    String? timeRange,
    String? note,
  }) {
    return AvailabilityEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      timeRange: timeRange ?? this.timeRange,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'date': date.toIso8601String(),
    'kind': kind.name,
    'timeRange': timeRange,
    'note': note,
  };

  factory AvailabilityEntry.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final parsedDate = rawDate is String ? DateTime.tryParse(rawDate) : null;
    final kindName = json['kind'] as String?;
    return AvailabilityEntry(
      id: (json['id'] as String?) ?? '',
      date: parsedDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      kind: AvailabilityKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => AvailabilityKind.free,
      ),
      timeRange: (json['timeRange'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
    );
  }
}

@immutable
class TravelStats {
  const TravelStats({
    required this.completedTrips,
    required this.visitedPlaces,
    required this.estimatedKilometers,
  });

  final int completedTrips;
  final int visitedPlaces;
  final int estimatedKilometers;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'completedTrips': completedTrips,
    'visitedPlaces': visitedPlaces,
    'estimatedKilometers': estimatedKilometers,
  };

  factory TravelStats.fromJson(Map<String, dynamic> json) => TravelStats(
    completedTrips: (json['completedTrips'] as num?)?.toInt() ?? 0,
    visitedPlaces: (json['visitedPlaces'] as num?)?.toInt() ?? 0,
    estimatedKilometers: (json['estimatedKilometers'] as num?)?.toInt() ?? 0,
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
