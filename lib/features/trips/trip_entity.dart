import 'package:flutter/foundation.dart';
import '../ai/gemini_models.dart';

enum TripStatus {
  planning,
  ready,
  completed,
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.planDraft,
    this.timestamp,
  });

  final String role; // 'user' | 'assistant'
  final String text;
  final GeminiTripPlanDraft? planDraft;
  final DateTime? timestamp;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawDraft = json['planDraft'];
    return ChatMessage(
      role: json['role']?.toString() ?? 'user',
      text: json['text']?.toString() ?? '',
      planDraft: rawDraft is Map<String, dynamic> ? GeminiTripPlanDraft.fromJson(rawDraft) : null,
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'text': text,
    'planDraft': planDraft?.toJson(),
    'timestamp': timestamp?.toIso8601String(),
  };
}

@immutable
class TripEntity {
  const TripEntity({
    required this.id,
    required this.destination,
    required this.durationDays,
    required this.status,
    required this.coverImageUrl,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.messages = const [],
    this.latestPlan,
  });

  final String id;
  final String destination;
  final int durationDays;
  final TripStatus status;
  final String coverImageUrl;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ChatMessage> messages;
  final GeminiTripPlanDraft? latestPlan;

  TripEntity copyWith({
    String? id,
    String? destination,
    int? durationDays,
    TripStatus? status,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    List<ChatMessage>? messages,
    GeminiTripPlanDraft? latestPlan,
  }) {
    return TripEntity(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      durationDays: durationDays ?? this.durationDays,
      status: status ?? this.status,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      messages: messages ?? this.messages,
      latestPlan: latestPlan ?? this.latestPlan,
    );
  }

  factory TripEntity.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString();
    final status = TripStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => TripStatus.planning,
    );

    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages.whereType<Map<String, dynamic>>().map(ChatMessage.fromJson).toList()
        : <ChatMessage>[];

    final rawPlan = json['latestPlan'];
    final latestPlan = rawPlan is Map<String, dynamic> ? GeminiTripPlanDraft.fromJson(rawPlan) : null;

    return TripEntity(
      id: json['id']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 3,
      status: status,
      coverImageUrl: json['coverImageUrl']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      messages: messages,
      latestPlan: latestPlan,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'destination': destination,
    'durationDays': durationDays,
    'status': status.name,
    'coverImageUrl': coverImageUrl,
    'createdAt': createdAt.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
    'latestPlan': latestPlan?.toJson(),
  };
}
