import 'package:flutter/material.dart' show ThemeMode;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_config.dart';
import '../../models/trip_models.dart' show JourneyRoute;
import 'chat_first_models.dart'
    show
        ChatMessage,
        ChatMessageKind,
        ChatRole,
        Conversation,
        ConversationRow,
        DestinationPoint,
        ProfileRow,
        TripSnapshot;
import 'data_source.dart';

/// Live source backed by the Supabase `iter` project. Only used when the build
/// was started with `--dart-define=ITER_BACKEND=supabase` plus a URL and key.
class SupabaseDataSource implements IterDataSource {
  SupabaseDataSource({required this.config, SupabaseClient? client})
    : _providedClient = client;

  final AppConfig config;
  final SupabaseClient? _providedClient;

  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<void> init() async {
    if (_providedClient != null) return;
    if (Supabase.instance.isInitialized) return;
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
  }

  @override
  Future<List<JourneyRoute>> fetchJourneys() async {
    try {
      final rows = await _client
          .from('destinations')
          .select()
          .order('match_score', ascending: false);
      return rows.map(_fromRow).toList();
    } catch (_) {
      return const <JourneyRoute>[];
    }
  }

  @override
  Future<List<DestinationPoint>> fetchPois(String destinationSlug) async {
    try {
      final client = _client;
      final destination = await client
          .from('destinations')
          .select('id')
          .eq('slug', destinationSlug)
          .maybeSingle();
      if (destination == null) return const <DestinationPoint>[];
      final rows = await client
          .from('pois')
          .select('id, name, category, emoji, why_fits')
          .eq('destination_id', destination['id'])
          .order('name');
      return rows.map(_fromPoiRow).toList();
    } catch (_) {
      return const <DestinationPoint>[];
    }
  }

  @override
  Future<List<ConversationRow>> fetchConversations() async {
    try {
      final rows = await _client
          .from('conversations')
          .select()
          .order('updated_at', ascending: false);
      return rows.map(ConversationRow.fromDbRow).toList();
    } catch (_) {
      return const <ConversationRow>[];
    }
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    try {
      final rows = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('sent_at');
      return rows
          .map((row) => ChatMessage.fromJson(
              (row['content'] as Map?)?.cast<String, dynamic>() ??
                  const <String, dynamic>{}))
          .where((message) => message.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const <ChatMessage>[];
    }
  }

  @override
  Future<void> insertMessage(String conversationId, ChatMessage message) async {
    try {
      await _client.from('messages').insert(<String, dynamic>{
        'conversation_id': conversationId,
        'role': _roleColumn(message.role),
        'kind': _kindColumn(message),
        'text': message.text.isEmpty ? null : message.text,
        'proposal': message.proposal?.toJson(),
        'content': message.toJson(),
        'sent_at': message.sentAt.toIso8601String(),
      });
    } catch (_) {
      // Keep the in-memory thread authoritative; persistence is best effort.
    }
  }

  @override
  Future<void> setConversationRead(String conversationId) async {
    try {
      await _client
          .from('conversations')
          .update(<String, dynamic>{'unread': 0})
          .eq('id', conversationId);
    } catch (_) {}
  }

  @override
  Future<void> incrementUnread(String conversationId) async {
    try {
      final client = _client;
      final rows = await client
          .from('conversations')
          .select('unread')
          .eq('id', conversationId)
          .maybeSingle();
      if (rows == null) return;
      final unread = ((rows['unread'] as num?)?.toInt() ?? 0) + 1;
      await client
          .from('conversations')
          .update(<String, dynamic>{'unread': unread})
          .eq('id', conversationId);
    } catch (_) {}
  }

  @override
  Future<ConversationRow?> createConversation(Conversation summary) async {
    try {
      final rows = await _client
          .from('conversations')
          .insert(<String, dynamic>{
            'user_id': _client.auth.currentUser?.id,
            'title': summary.title,
            'avatar_asset': summary.avatar.asset,
            'unread': summary.unread,
            'summary': summary.toJson(),
          })
          .select();
      if (rows.isEmpty) return null;
      return ConversationRow.fromDbRow(rows.first);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PlanSaveResult> saveTripVersion({
    required String conversationId,
    required Conversation conversation,
    required TripSnapshot snapshot,
  }) async {
    try {
      final client = _client;
      final conversationRows = await client
          .from('conversations')
          .select('trip_id')
          .eq('id', conversationId)
          .limit(1);
      if (conversationRows.isEmpty) {
        return const PlanSaveResult.failure('conversation_not_found');
      }
      final conversationRow = conversationRows.first;

      String? tripId = conversationRow['trip_id'] as String?;
      final status = snapshot.statusLabel == 'In viaggio' ? 'active' : 'draft';
      if (tripId == null) {
        final rows = await client
            .from('trips')
            .insert(<String, dynamic>{
              'user_id': client.auth.currentUser?.id,
              'title': conversation.title,
              'status': status,
              'snapshot': snapshot.toJson(),
            })
            .select('id');
        if (rows.isEmpty) {
          return const PlanSaveResult.failure('trip_not_created');
        }
        tripId = rows.first['id'] as String;
        await client
            .from('conversations')
            .update(<String, dynamic>{'trip_id': tripId})
            .eq('id', conversationId);
      } else {
        await client
            .from('trips')
            .update(<String, dynamic>{
              'title': conversation.title,
              'status': status,
              'snapshot': snapshot.toJson(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', tripId);
      }

      final existing = await client
          .from('trip_versions')
          .select('version_number')
          .eq('trip_id', tripId)
          .eq('version_number', snapshot.revision)
          .limit(1);
      if (existing.isEmpty) {
        await client.from('trip_versions').insert(<String, dynamic>{
          'trip_id': tripId,
          'version_number': snapshot.revision,
          'draft': snapshot.toJson(),
        });
      }
      await client
          .from('conversations')
          .update(<String, dynamic>{'summary': conversation.toJson()})
          .eq('id', conversationId);
      return const PlanSaveResult.success();
    } on PostgrestException catch (error) {
      return PlanSaveResult.failure(error.code);
    } catch (_) {
      return const PlanSaveResult.failure('unexpected');
    }
  }

  @override
  Future<ProfileRow?> fetchProfile() async {
    try {
      final client = _client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;
      final row = await client
          .from('profiles')
          .select('theme_mode, memory_tags')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;
      return ProfileRow(
        themeMode: _themeModeFromColumn(row['theme_mode']),
        memoryTags: (row['memory_tags'] as List<dynamic>?)
                ?.whereType<String>()
                .toList(growable: false) ??
            const <String>[],
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsertProfile({ThemeMode? themeMode, List<String>? memoryTags}) async {
    try {
      final client = _client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      final themeModeColumn = themeMode == null ? null : _themeModeColumn(themeMode);
      final payload = <String, dynamic>{
        'id': userId,
        'theme_mode': ?themeModeColumn,
        'memory_tags': ?memoryTags,
      };
      if (payload.length == 1) return;
      await client.from('profiles').upsert(payload);
    } catch (_) {
      // Best effort: the in-memory profile stays authoritative.
    }
  }

  /// Maps a message role onto the `messages.role` check constraint
  /// (`'user' | 'assistant'`); the travel-first [ChatRole] enums collapse onto
  /// the assistant bucket for divider/system rows.
  String _roleColumn(ChatRole role) => switch (role) {
        ChatRole.traveler => 'user',
        ChatRole.assistant || ChatRole.system => 'assistant',
      };

  /// Maps a message kind onto the `messages.kind` check constraint. The full
  /// kind is also stored inside `content` so round-trips stay lossless even
  /// when the coarse column value differs (choices -> 'choice').
  String _kindColumn(ChatMessage message) {
    if (message.kind == ChatMessageKind.media && message.media?.isVideo == true) {
      return 'video';
    }
    return switch (message.kind) {
      ChatMessageKind.text => 'text',
      ChatMessageKind.choices => 'choice',
      ChatMessageKind.media => 'image',
      ChatMessageKind.audio => 'audio',
      ChatMessageKind.tripSummary => 'tripSummary',
      ChatMessageKind.operational => 'operational',
      ChatMessageKind.planProposal => 'planProposal',
      ChatMessageKind.placeCard => 'placeCard',
      ChatMessageKind.transport => 'transport',
      ChatMessageKind.stayZone => 'stayZone',
      ChatMessageKind.system => 'system',
    };
  }

  /// Maps a `profiles.theme_mode` column onto [ThemeMode]; unknown values
  /// degrade to the app default light theme.
  ThemeMode _themeModeFromColumn(Object? value) => switch (value) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };

  /// Maps [ThemeMode] onto the `profiles.theme_mode` check constraint.
  String _themeModeColumn(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
      };

  /// Maps a `pois` row to the light preview-sheet shape. Missing cosmetic
  /// fields degrade to friendly defaults so the sheet never breaks.
  DestinationPoint _fromPoiRow(Map<String, dynamic> row) => DestinationPoint(
        id: (row['id'] as String),
        name: (row['name'] as String?) ?? '',
        category: (row['category'] as String?) ?? '',
        emoji: (row['emoji'] as String?) ?? '📍',
        whyFits: (row['why_fits'] as String?) ?? '',
      );

  /// Maps a `destinations` row (city or route) to the shared journey model.
  /// A city without stops falls back to its own name and slug so the Home
  /// posters and "Organizza un viaggio" entry keep working.
  JourneyRoute _fromRow(Map<String, dynamic> row) {
    final id = row['slug'] as String;
    final name = row['name'] as String;
    final stops = (row['stops'] as List<dynamic>?)?.cast<String>();
    final destinationIds =
        (row['destination_ids'] as List<dynamic>?)?.cast<String>();
    return JourneyRoute(
      id: id,
      title: name,
      summary: (row['description'] as String?) ?? name,
      durationLabel: (row['duration_label'] as String?) ?? '',
      stops: stops != null && stops.isNotEmpty ? stops : <String>[name],
      destinationIds: destinationIds != null && destinationIds.isNotEmpty
          ? destinationIds
          : <String>[id],
      whyItFits: (row['why_it_fits'] as String?) ?? '',
      season: (row['season'] as String?) ?? '',
      travelMode: (row['travel_mode'] as String?) ?? '',
      videoAssets: (row['video_assets'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      matchScore: (row['match_score'] as int?) ?? 0,
    );
  }
}
