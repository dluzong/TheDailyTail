import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// User Data Model
class AppUser {
  final String userId;
  final String username;
  final String firstName;
  final String lastName;
  final String role;

  AppUser({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['user_id'],
      username: map['username'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      role: map['role'],
    );
  }
}

class UserProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  AppUser? _user;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

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
    notifyListeners();
  }

  // Clears the user data on sign out.
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
