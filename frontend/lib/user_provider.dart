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
  final List<String> following;
  final List<String> followers;
  final Map<String, String> organizationRoles;

  AppUser({
    required this.userId,
    required this.name,
    required this.username,
    required this.roles,
    required this.bio,
    required this.photoUrl,
    required this.following,
    required this.followers,
    required this.organizationRoles,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    List<String> parsedFollowing = [];
    if (map['following'] != null) {
      final List<dynamic> data = map['following'];
      parsedFollowing =
          data.map((item) => item['followee_id'] as String).toList();
    } else if (map['follows'] != null) {
      final List<dynamic> data = map['follows'];
      parsedFollowing =
          data.map((item) => item['followee_id'] as String).toList();
    }

    List<String> parsedFollowers = [];
    if (map['followers'] != null) {
      final List<dynamic> data = map['followers'];
      parsedFollowers =
          data.map((item) => item['follower_id'] as String).toList();
    }

    Map<String, String> parsedOrgRoles = {};
    if (map['organization_members'] != null) {
      final List<dynamic> membersData = map['organization_members'];
      for (var m in membersData) {
        if (m['organization_id'] != null) {
          parsedOrgRoles[m['organization_id']] = m['role'] ?? 'member';
        }
      }
    } else if (map['organization_roles'] != null) {
      // Handle cache restoration
      parsedOrgRoles = Map<String, String>.from(map['organization_roles']);
    }

    return AppUser(
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      roles: List<String>.from(map['role'] ?? []),
      bio: map['bio'] ?? '',
      photoUrl: map['photo_url'] ?? '',
      following: parsedFollowing,
      followers: parsedFollowers,
      organizationRoles: parsedOrgRoles,
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
      'following': following.map((id) => {'followee_id': id}).toList(),
      'followers': followers.map((id) => {'follower_id': id}).toList(),
      'organization_roles': organizationRoles,
    };
  }

  // User Equivalence Operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    bool mapsEqual(Map a, Map b) {
      if (a.length != b.length) return false;
      return a.keys.every((k) => b.containsKey(k) && a[k] == b[k]);
    }

    bool listEquals(List a, List b) {
      if (a.length != b.length) return false;
      return a.toSet().containsAll(b);
    }

    return other is AppUser &&
        other.userId == userId &&
        other.username == username &&
        other.name == name &&
        other.bio == bio &&
        other.photoUrl == photoUrl &&
        listEquals(other.following, following) &&
        listEquals(other.followers, followers) &&
        mapsEqual(other.organizationRoles, organizationRoles);
  }

  @override
  int get hashCode => userId.hashCode ^ username.hashCode;

  // --- HELPER METHODS ---
  bool isMemberOf(String orgId) => organizationRoles.containsKey(orgId);
  bool isAdminOf(String orgId) {
    final role = organizationRoles[orgId];
    return role == 'admin' || role == 'owner';
  }
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

  Future<void> fetchUser({bool force = false}) async {
    if (_isFetching) {
      debugPrint('WARNING: Fetch skipped: Already fetching.');
      return;
    }

    if (!force && _lastFetchTime != null) {
      final difference = DateTime.now().difference(_lastFetchTime!);
      if (difference.inSeconds < 2) return;
    }

    final session = _supabase.auth.currentSession;
    if (session == null) {
      if (_user != null) {
        clearUser();
      }
      return;
    }

    _isFetching = true;

    try {
      // Fetches user profile + follows + followers + org memberships
      final response = await _supabase.from('users').select('''
            user_id, 
            username, 
            name, 
            bio, 
            photo_url, 
            role, 
            organization_members(organization_id, role),
            following:follows!follower_id(followee_id),
            followers:follows!followee_id(follower_id)
          ''').eq('user_id', session.user.id).maybeSingle();

      if (response == null) {
        // If the auth session exists but profile row was deleted, recreate a minimal profile.
        try {
          await _supabase.from('users').insert({
            'user_id': session.user.id,
            'username': session.user.userMetadata?['username'] ??
                session.user.email?.split('@').first ??
                'user_${session.user.id.substring(0, 6)}',
            'name': session.user.userMetadata?['name'] ?? '',
            'photo_url': session.user.userMetadata?['avatar_url'] ?? '',
            'role': <String>[],
            'bio': '',
          });
          // Refetch after insert
          final recreated = await _supabase.from('users').select('''
                user_id,
                username,
                name,
                bio,
                photo_url,
                role,
                organization_members(organization_id, role),
                following:follows!follower_id(followee_id),
                followers:follows!followee_id(follower_id)
              ''').eq('user_id', session.user.id).maybeSingle();
          if (recreated != null) {
            final newUser = AppUser.fromMap(recreated);
            _user = newUser;
            _lastFetchTime = DateTime.now();
            await _saveToCache();
            notifyListeners();
          }
        } catch (e) {
          debugPrint('ERROR: Failed to recreate user profile: $e');
          _user = null;
        }
      } else {
        final newUser = AppUser.fromMap(response);

        if (_user != newUser || force) {
          _user = newUser;
          _lastFetchTime = DateTime.now();
          await _saveToCache();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('ERROR: Error fetching user: $e');
    } finally {
      _isFetching = false;
    }
  }

  // Fetch a public profile by username (for viewing other users)
  Future<AppUser?> fetchPublicProfile(String username) async {
    try {
      final response = await _supabase.from('users').select('''
            user_id, 
            username, 
            name, 
            bio, 
            photo_url, 
            role, 
            organization_members(organization_id, role),
            following:follows!follower_id(followee_id),
            followers:follows!followee_id(follower_id)
          ''').eq('username', username).maybeSingle();

      if (response == null) {
        return null;
      }
      return AppUser.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching public profile: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsersByIds(
      List<String> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }
    try {
      final response = await _supabase
          .from('users')
          .select('user_id, name, username, photo_url')
          .inFilter('user_id', userIds);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching users by IDs: $e');
      return [];
    }
  }

  // search users by username or name
  Future<List<Map<String, dynamic>>> searchUsers(String term,
      {int limit = 10, bool excludeSelf = true}) async {
    final query = term.trim();
    if (query.isEmpty) return [];
    try {
      final currentId = _supabase.auth.currentUser?.id;
      final filter = 'username.ilike.%$query%,name.ilike.%$query%';
      final res = await _supabase
          .from('users')
          .select('user_id, username, name, photo_url')
          .or(filter)
          .limit(limit);

      var results = List<Map<String, dynamic>>.from(res);
      if (excludeSelf && currentId != null) {
        results = results.where((u) => u['user_id'] != currentId).toList();
      }
      return results;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Fetch other user's pets by user ID
  Future<List<Map<String, dynamic>>> fetchOtherUserPets(String userId) async {
    try {
      final response =
          await _supabase.from('pets').select().eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching other user pets: $e');
      return [];
    }
  }

  // Follow/Unfollow logic
  Future<void> toggleFollow(String targetUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final isFollowing = _user?.following.contains(targetUserId) ?? false;

      if (isFollowing) {
        await _supabase.from('follows').delete().match({
          'follower_id': currentUserId,
          'followee_id': targetUserId,
        });
      } else {
        await _supabase.from('follows').insert({
          'follower_id': currentUserId,
          'followee_id': targetUserId,
        });
      }
      await fetchUser(force: true);
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      rethrow;
    }
  }

  void clearUser() {
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
      }
    } catch (e) {
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
    String? bio,
    List<String>? roles,
    String? photoUrl,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      debugPrint('ERROR: No active session, cannot update profile');
      return;
    }

    try {
      final Map<String, dynamic> updates = {
        'username': username,
        'name': name,
      };

      if (bio != null) updates['bio'] = bio;
      if (roles != null) updates['role'] = roles;
      if (photoUrl != null) updates['photo_url'] = photoUrl;

      await _supabase
          .from('users')
          .update(updates)
          .eq('user_id', session.user.id);

      await fetchUser(force: true);
    } catch (e) {
      debugPrint('ERROR: Failed to update user profile: $e');
      rethrow;
    }
  }
}
