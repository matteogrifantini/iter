import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'trip_entity.dart';

class TripRepository {
  TripRepository({this.prefs});

  SharedPreferences? prefs;
  static const String _storageKey = 'iter_saved_trips_v1';

  Future<SharedPreferences> _getPrefs() async {
    return prefs ??= await SharedPreferences.getInstance();
  }


  Future<List<TripEntity>> getAllTrips() async {
    final prefs = await _getPrefs();
    final rawJson = prefs.getString(_storageKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(TripEntity.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<TripEntity?> getTripById(String id) async {
    final all = await getAllTrips();
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTrip(TripEntity trip) async {
    final all = await getAllTrips();
    final index = all.indexWhere((t) => t.id == trip.id);

    if (index >= 0) {
      all[index] = trip;
    } else {
      all.insert(0, trip);
    }

    final prefs = await _getPrefs();
    final encoded = jsonEncode(all.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> deleteTrip(String id) async {
    final all = await getAllTrips();
    all.removeWhere((t) => t.id == id);

    final prefs = await _getPrefs();
    final encoded = jsonEncode(all.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
