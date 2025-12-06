import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allOrgs = [];
  List<Map<String, dynamic>> get allOrgs => _allOrgs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchOrganizations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('organizations')
          .select()
          .order('name', ascending: true);

      _allOrgs = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching orgs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinOrg(String orgId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('organization_members').insert({
        'organization_id': orgId,
        'user_id': userId,
        'role': 'member',
      });

    } catch (e) {
      debugPrint('Error joining org: $e');
      rethrow;
    }
  }

  Future<void> leaveOrg(String orgId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('organization_members').delete().match({
        'organization_id': orgId,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint('Error leaving org: $e');
      rethrow;
    }
  }
}
