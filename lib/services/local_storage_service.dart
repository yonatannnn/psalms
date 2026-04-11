import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/reading_preferences_model.dart';
import '../models/sunday_prayers_model.dart';

/// Centralized local storage for offline-first data caching.
/// All user data, reading preferences, and sunday prayers are stored
/// locally via SharedPreferences and synced to Firestore in the background.
class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._();
  LocalStorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sharedPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Keys ──────────────────────────────────────────────────────────────
  static const _keyUser = 'cached_user_data';
  static const _keyReadingPrefs = 'cached_reading_preferences';
  static const _keySundayPrayers = 'cached_sunday_prayers';
  static const _keyDailyOpenCount = 'cached_daily_open_count';
  static const _keyLastOpenDate = 'cached_last_open_date';

  // ── User Data ─────────────────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    final prefs = await _sharedPrefs;
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await _sharedPrefs;
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final prefs = await _sharedPrefs;
    await prefs.remove(_keyUser);
    await prefs.remove(_keyReadingPrefs);
    await prefs.remove(_keySundayPrayers);
    await prefs.remove(_keyDailyOpenCount);
    await prefs.remove(_keyLastOpenDate);
  }

  // ── Reading Preferences ───────────────────────────────────────────────

  Future<void> saveReadingPreferences(ReadingPreferencesModel prefs) async {
    final sp = await _sharedPrefs;
    await sp.setString(_keyReadingPrefs, jsonEncode(prefs.toJson()));
  }

  Future<ReadingPreferencesModel?> getReadingPreferences(String userId) async {
    final sp = await _sharedPrefs;
    final raw = sp.getString(_keyReadingPrefs);
    if (raw == null) return null;
    try {
      final model = ReadingPreferencesModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      // Only return if it belongs to the current user
      if (model.userId == userId) return model;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Sunday Prayers ────────────────────────────────────────────────────

  Future<void> saveSundayPrayers(SundayPrayersModel prayers) async {
    final sp = await _sharedPrefs;
    await sp.setString(_keySundayPrayers, jsonEncode(prayers.toJson()));
  }

  Future<SundayPrayersModel?> getSundayPrayers(String userId) async {
    final sp = await _sharedPrefs;
    final raw = sp.getString(_keySundayPrayers);
    if (raw == null) return null;
    try {
      final model = SundayPrayersModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      if (model.userId == userId) return model;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Daily Open Tracking (local) ───────────────────────────────────────

  Future<void> trackDailyOpen() async {
    final sp = await _sharedPrefs;
    final today = DateTime.now().toIso8601String().split('T').first;
    final lastDate = sp.getString(_keyLastOpenDate);
    if (lastDate != today) {
      final count = sp.getInt(_keyDailyOpenCount) ?? 0;
      await sp.setInt(_keyDailyOpenCount, count + 1);
      await sp.setString(_keyLastOpenDate, today);
    }
  }
}
