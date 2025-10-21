import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// User Data Model
class AppUser {
  final String userId;
  final String username;
  final String firstName;
  final String lastName;

  AppUser({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['user_id'],
      username: map['username'],
      firstName: map['first_name'],
      lastName: map['last_name'],
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

    // if logged in, get user id
    final userId = session.user.id;

    // get user data from 'users' table in supabase
    final response =
        await _supabase.from('users').select().eq('user_id', userId).single();

    // save user data to _user
    _user = AppUser.fromMap(response);
    notifyListeners();
  }

  // Clears the user data on sign out.
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
