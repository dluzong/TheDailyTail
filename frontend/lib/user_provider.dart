import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// User Data Model
class AppUser {
  final String userId;
  final String name;
  final String username;
  final List<String> roles;
  final String bio;
  final String photoUrl;
  final List<String> following;

  AppUser({
    required this.userId,
    required this.name,
    required this.username,
    required this.roles,
    required this.bio,
    required this.photoUrl,
    required this.following,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      roles: List<String>.from(map['role'] ?? []),
      bio: map['bio'] ?? '',
      photoUrl: map['photo_url'] ?? '',
      following: List<String>.from(map['following'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'username': username,
      'roles': roles,
      'bio': bio,
      'photo_url': photoUrl,
      'following': following
    };
  }
}

class UserProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  AppUser? _user;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  // Cache keys
  static const _cacheKey = 'cached_app_user';

  UserProvider() {
    // Load cached user eagerly
    _loadFromCache();

    // React to auth changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        // Optionally fetch fresh user on sign-in
        await fetchUser();
      } else if (event == AuthChangeEvent.signedOut) {
        clearUser();
      }
    });
  }

  // fetch user data (public.users) from Supabase and update _user
  Future<void> fetchUser() async {
    debugPrint('Fetching user data from Supabase');
    final session = _supabase.auth.currentSession;

    // check if no user is logged in
    if (session == null) {
      _user = null;
      notifyListeners();
      return;
    }

    debugPrint("User logged in");
    // if logged in, get user id
    final userId = session.user.id;

    debugPrint("User id retrieved");

    // get user data from 'users' table in supabase
    final response = await _supabase
        .from('users')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      debugPrint("No user row found for user_id: $userId");
      _user = null;
      notifyListeners();
      return;
    }

    _user = AppUser.fromMap(response);
    debugPrint("saved user data");
    await _saveToCache();
    notifyListeners();
  }

  // Clears the user data on sign out.
  void clearUser() {
    _user = null;
    _clearCache();
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return;
      final Map<String, dynamic> map = json.decode(jsonStr);
      _user = AppUser.fromMap(map);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load cached user: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      if (_user == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_user!.toMap()));
    } catch (e) {
      debugPrint('Failed to cache user: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }

  Future<void> updateUserProfile({
    required String username,
    required String name,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) return;

    final userId = session.user.id;
    try {
      await _supabase.from('users').update({
        'username': username,
        'name': name,
      }).eq('user_id', userId);

      _user = AppUser(
        userId: userId,
        username: username,
        name: name,
        roles: _user?.roles ?? ['User'],
        bio: _user?.bio ?? '',
        photoUrl: _user?.photoUrl ?? '',
        following: _user?.following ?? [],
      );
      await _saveToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
      rethrow;
    }
  }
}
