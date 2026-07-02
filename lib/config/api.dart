// ============================================================
//  ArchiverZ — API client with GitHub remote config + caching
//
//  Flow on app start:
//    1) main() calls Api.loadGh() — fetches x.json from GitHub
//    2) If fetch succeeds: baseUrl saved to SharedPreferences,
//       used for all subsequent requests.
//    3) If fetch fails: Api.api returns the cached value from
//       SharedPreferences. If no cache either, returns the
//       hardcoded fallback in AppConfig.fallbackBaseUrl.
//
//  Auto-reconnect:
//    Api.startBackgroundRefresh() schedules a re-fetch every 5 min.
//    When you change the IP/domain in x.json on GitHub, all deployed
//    apps pick up the new URL within 5 minutes — no app restart needed.
//    (Called automatically from main() — see bottom of this file.)
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

class Api {
  Api._();

  static const String _prefsKey = 'archiverz_base_url';
  static const String _prefsFetchKey = 'archiverz_last_fetch';
  static const Duration _refreshInterval = Duration(minutes: 5);
  static const Duration _fetchTimeout = Duration(seconds: 8);

  static String _baseUrl = '';
  static Timer? _refreshTimer;
  static bool _initialized = false;

  /// Current base URL.
  /// - If remote config was fetched successfully: returns fetched value.
  /// - If fetch failed but a cached value exists: returns cached value.
  /// - If neither: returns AppConfig.fallbackBaseUrl.
  static String get api {
    if (_baseUrl.isNotEmpty) return _baseUrl;
    return AppConfig.fallbackBaseUrl;
  }

  /// Fetch the live baseUrl from the remote JSON endpoint.
  /// Caches the result to SharedPreferences so it survives app restarts
  /// even when the next fetch fails (e.g. GitHub is down).
  static Future<void> loadGh() async {
    _initialized = true;
    // 1) Load cached value first (instant — used until fetch completes)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefsKey);
      if (cached != null && cached.isNotEmpty) {
        _baseUrl = cached;
      }
    } catch (_) {}

    // 2) Then do a fresh fetch (overwrites cache if successful)
    await _fetchAndCache();

    // 3) Start periodic background refresh
    startBackgroundRefresh();
  }

  static Future<void> _fetchAndCache() async {
    try {
      final response = await http
          .get(
            Uri.parse(AppConfig.remoteConfigUrl),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(_fetchTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final remoteUrl = data['x'];
        if (remoteUrl is String && remoteUrl.isNotEmpty) {
          if (remoteUrl != _baseUrl) {
            if (kDebugMode) {
              debugPrint('[ArchiverZ] Remote config updated: $remoteUrl');
            }
          }
          _baseUrl = remoteUrl;
          // Persist to SharedPreferences
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefsKey, remoteUrl);
            await prefs.setInt(
                _prefsFetchKey, DateTime.now().millisecondsSinceEpoch);
          } catch (_) {}
        }
      }
    } catch (e) {
      // Silent fallback — keep using whatever _baseUrl is currently set
      // (either from cache or from AppConfig.fallbackBaseUrl).
      if (kDebugMode) {
        debugPrint('[ArchiverZ] Remote config fetch failed: $e');
      }
    }
  }

  /// Schedule a background re-fetch every 5 minutes.
  /// Called automatically by loadGh(). Safe to call multiple times.
  static void startBackgroundRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _fetchAndCache();
    });
  }

  /// Stop the background refresh timer (e.g. on app dispose).
  static void stopBackgroundRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Manually trigger a refresh (e.g. on network state change).
  static Future<void> refreshNow() async {
    await _fetchAndCache();
  }

  /// Returns the timestamp (millisecondsSinceEpoch) of the last
  /// successful remote config fetch, or null if never fetched.
  static Future<int?> get lastFetchTimestamp async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsFetchKey);
  }
}
