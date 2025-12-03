import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

// User Data Model
class AppUser {
  final String userId;
  final String name;
  final String username;
  final List<String> roles;
  final String bio;
  final String photoUrl;

  AppUser({
    required this.userId,
    required this.name,
    required this.username,
    required this.roles,
    required this.bio,
    required this.photoUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      roles: List<String>.from(map['role'] ?? []),
      bio: map['bio'] ?? '',
      photoUrl: map['photo_url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'username': username,
      'role': roles,
      'bio': bio,
      'photo_url': photoUrl,
    };
  }

  // User Equivalence Opperator (check if user == user)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.userId == userId &&
        other.username == username &&
        other.name == name &&
        other.bio == bio &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode => userId.hashCode ^ username.hashCode;
}

class UserProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  bool _isFetching = false;
  DateTime? _lastFetchTime;
  StreamSubscription<AuthState>? _authSubscription;

  static const _cacheKey = 'cached_app_user';

  UserProvider() {
    _init();
  }

  void _init() {
    _loadFromCache();

    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      // only fetch or clear on sign in/out or initial session
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession) {
        fetchUser();
      } else if (event == AuthChangeEvent.signedOut) {
        clearUser();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Fetch user data
  Future<void> fetchUser({bool force = false}) async {
    if (_isFetching) {
      debugPrint('WARNING: Fetch skipped: Already fetching.');
      return;
    }

    if (!force && _lastFetchTime != null) {
      final difference = DateTime.now().difference(_lastFetchTime!);
      if (difference.inSeconds < 2) {
        debugPrint('WARNING: Fetch skipped: Debounced (too soon).');
        return;
      }
    }

    final session = _supabase.auth.currentSession;
    if (session == null) {
      if (_user != null) clearUser();
      return;
    }

    _isFetching = true;

    try {
      debugPrint('INFO: Fetching user profile for: ${session.user.id}');

      final response = await _supabase
          .from('users')
          .select(
              'user_id, username, name, bio, photo_url, role, organizations')
          .eq('user_id', session.user.id)
          .maybeSingle();

      if (response == null) {
        debugPrint("ERROR: No public profile found.");
        _user = null;
      } else {
        final newUser = AppUser.fromMap(response);

        // only notify if data was changed
        if (_user != newUser) {
          _user = newUser;
          _lastFetchTime = DateTime.now();
          await _saveToCache();
          notifyListeners();
          debugPrint("SUCCESS: User data updated and listeners notified.");
        } else {
          debugPrint("INFO: User data unchanged. Notification skipped.");
        }
      }
    } catch (e) {
      debugPrint('ERROR: Error fetching user: $e');
    } finally {
      _isFetching = false;
    }
  }

  void clearUser() {
    debugPrint("INFO: User signed out. Clearing state.");
    _user = null;
    _clearCache();
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr != null) {
        final Map<String, dynamic> map = json.decode(jsonStr);
        _user = AppUser.fromMap(map);
        notifyListeners();
        debugPrint("SUCCESS: Loaded user from cache.");
      }
    } catch (e) {
      debugPrint('ERROR: Failed to load cached user: $e');
      _clearCache();
    }
  }

  Future<void> _saveToCache() async {
    if (_user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_user!.toMap()));
    } catch (e) {
      debugPrint('Failed to cache user: $e');
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  Future<void> updateUserProfile({
    required String username,
    required String name,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) return;

    try {
      await _supabase.from('users').update({
        'username': username,
        'name': name,
      }).eq('user_id', session.user.id);

      // Force a refresh to get the official data from DB
      await fetchUser(force: true);
    } catch (e) {
      debugPrint('ERROR: Failed to update user profile: $e');
      rethrow;
    }
  }
}
