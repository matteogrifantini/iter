import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_config.dart';
import 'profile_models.dart';


/// Manages local offline persistence for traveler preferences, theme mode,
/// and availability slots via [SharedPreferences].
class LocalPreferencesService {
  const LocalPreferencesService();

  static const String _keyThemeMode = 'iter_local_theme_mode';
  static const String _keyAvailability = 'iter_local_availability';
  static const String _keyMemoryTags = 'iter_local_memory_tags';

  Future<ThemeMode?> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyThemeMode);
      if (raw == null) return null;
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == raw,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, mode.name);
    } catch (_) {}
  }

  Future<List<AvailabilityEntry>?> loadAvailability() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyAvailability);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (item) => AvailabilityEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAvailability(List<AvailabilityEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
      await prefs.setString(_keyAvailability, raw);
    } catch (_) {}
  }

  Future<List<String>?> loadMemoryTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keyMemoryTags);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMemoryTags(List<String> tags) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyMemoryTags, tags);
    } catch (_) {}
  }

  static const String _keyDepartureCity = 'iter_local_departure_city';

  static const String _keyTravelStyle = 'iter_local_travel_style';
  static const String _keyBudget = 'iter_local_budget';
  static const String _keyGeminiApiKey = 'iter_local_gemini_api_key';

  static String _cachedDepartureCity = 'Roma';
  static String _cachedTravelStyle = 'Cultura & Gastronomia';
  static String _cachedBudget = 'Medio';
  static String? _cachedGeminiApiKey;

  String get departureCity => _cachedDepartureCity;
  String get travelStyle => _cachedTravelStyle;
  String get budget => _cachedBudget;
  String? get geminiApiKey {

    if (_cachedGeminiApiKey != null &&
        _cachedGeminiApiKey!.trim().isNotEmpty &&
        _cachedGeminiApiKey!.trim() != 'YOUR_GEMINI_API_KEY') {
      return _cachedGeminiApiKey!.trim();
    }
    return AppConfig.geminiApiKey.isNotEmpty ? AppConfig.geminiApiKey : null;
  }

  Future<void> initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedDepartureCity = prefs.getString(_keyDepartureCity) ?? 'Roma';

      _cachedTravelStyle = prefs.getString(_keyTravelStyle) ?? 'Cultura & Gastronomia';
      _cachedBudget = prefs.getString(_keyBudget) ?? 'Medio';
      _cachedGeminiApiKey = prefs.getString(_keyGeminiApiKey);
      if (_cachedGeminiApiKey == 'YOUR_GEMINI_API_KEY') {
        _cachedGeminiApiKey = AppConfig.geminiApiKey;
        await prefs.setString(_keyGeminiApiKey, AppConfig.geminiApiKey);
      }
    } catch (_) {}
  }


  Future<void> saveDepartureCity(String city) async {
    _cachedDepartureCity = city;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDepartureCity, city);
    } catch (_) {}
  }

  Future<void> saveTravelStyle(String style) async {
    _cachedTravelStyle = style;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTravelStyle, style);
    } catch (_) {}
  }

  Future<void> saveBudget(String b) async {
    _cachedBudget = b;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBudget, b);
    } catch (_) {}
  }

  Future<void> saveGeminiApiKey(String? key) async {
    _cachedGeminiApiKey = key;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (key == null || key.trim().isEmpty) {
        await prefs.remove(_keyGeminiApiKey);
      } else {
        await prefs.setString(_keyGeminiApiKey, key.trim());
      }
    } catch (_) {}
  }
}

