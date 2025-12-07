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

  // Social
  final List<String> following;
  final List<String> followers;

  // Organization Roles: Maps Organization ID -> Role (e.g., 'admin', 'member')
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
    // 1. Parse Following
    List<String> parsedFollowing = [];
    if (map['following'] != null) {
      final List<dynamic> data = map['following'];
      parsedFollowing =
          data.map((item) => item['followee_id'] as String).toList();
    } else if (map['follows'] != null) {
      // Legacy cache support
      final List<dynamic> data = map['follows'];
      parsedFollowing =
          data.map((item) => item['followee_id'] as String).toList();
    }

    // 2. Parse Followers
    List<String> parsedFollowers = [];
    if (map['followers'] != null) {
      final List<dynamic> data = map['followers'];
      parsedFollowers =
          data.map((item) => item['follower_id'] as String).toList();
    }

    // 3. Parse Organization Roles
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
      // Store IDs for cache
      'following': following.map((id) => {'followee_id': id}).toList(),
      'followers': followers.map((id) => {'follower_id': id}).toList(),
      'organization_roles': organizationRoles,
    };
  }

  // User Equivalence Operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    bool listEquals(List a, List b) {
      if (a.length != b.length) return false;
      return a.toSet().containsAll(b);
    }

    bool mapsEqual(Map a, Map b) {
      if (a.length != b.length) return false;
      return a.keys.every((k) => b.containsKey(k) && a[k] == b[k]);
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
  bool isAdminOf(String orgId) => organizationRoles[orgId] == 'admin';
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
      // Fetches:
      // 1. Basic Info
      // 2. Organization Memberships (via organization_members)
      // 3. Following (via follows!follower_id)
      // 4. Followers (via follows!followee_id)
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
        debugPrint('WARNING: No user data found in database');
        _user = null;
      } else {
        final newUser = AppUser.fromMap(response);
        debugPrint('INFO: User data fetched successfully');
        debugPrint('DEBUG: User roles: ${newUser.roles}');
        debugPrint('DEBUG: User bio: ${newUser.bio}');
        debugPrint('DEBUG: User photo URL: ${newUser.photoUrl}');

        if (_user != newUser) {
          _user = newUser;
          _lastFetchTime = DateTime.now();
          await _saveToCache();
          notifyListeners();
          debugPrint('INFO: User state updated and listeners notified');
        }
      }
    } catch (e) {
      debugPrint('ERROR: Error fetching user: $e');
    } finally {
      _isFetching = false;
    }
  }

  // Fetch a public profile by username
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

      if (response == null) return null;
      return AppUser.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching public profile: $e');
      return null;
    }
  }

  // Fetch basic details for a list of user IDs (for follower/following lists)
  Future<List<Map<String, dynamic>>> fetchUsersByIds(
      List<String> userIds) async {
    if (userIds.isEmpty) return [];
    try {
      final response = await _supabase
          .from('users')
          .select('user_id, name, username, photo_url')
          .inFilter('user_id', userIds);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user profiles: $e');
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
      // Refresh my profile to update 'following' list
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
    // TODO: Implement photo upload functionality
    String? photoUrl,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      debugPrint('ERROR: No active session, cannot update profile');
      return;
    }

    try {
      final updateData = <String, dynamic>{
        'username': username,
        'name': name,
      };

      if (bio != null) {
        updateData['bio'] = bio;
        debugPrint('DEBUG: Updating bio');
      }

      if (roles != null) {
        updateData['role'] = roles;
        debugPrint('DEBUG: Updating roles to: $roles');
      }

      // TODO: Implement photo upload to storage and store URL
      if (photoUrl != null) {
        updateData['photo_url'] = photoUrl;
        debugPrint('DEBUG: Updating photo URL');
      }

      debugPrint('INFO: Updating user profile with data: $updateData');
      await _supabase
          .from('users')
          .update(updateData)
          .eq('user_id', session.user.id);
      debugPrint('INFO: Database update successful');

      await fetchUser(force: true);
    } catch (e) {
      debugPrint('ERROR: Failed to update user profile: $e');
      rethrow;
    }
  }
}
