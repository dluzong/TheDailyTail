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

  // Check if current user is a member of the org
  bool isMember(Map<String, dynamic> org) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    final members = List<String>.from(org['member_id'] ?? []);
    return members.contains(userId);
  }

  // Check if current user is an admin of the org
  bool isAdmin(Map<String, dynamic> org) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    final admins = List<String>.from(org['admin_id'] ?? []);
    return admins.contains(userId);
  }

  Future<void> joinOrg(String orgId) async {
    try {
      // calls supabase/postgress function to join org
      await _supabase.rpc('join_organization', params: {'org_id': orgId});
      await fetchOrganizations(); // Refresh list to update UI button
    } catch (e) {
      debugPrint('Error joining org: $e');
      rethrow;
    }
  }

  Future<void> leaveOrg(String orgId) async {
    try {
      await _supabase.rpc('leave_organization', params: {'org_id': orgId});
      await fetchOrganizations();
    } catch (e) {
      debugPrint('Error leaving org: $e');
      rethrow;
    }
  }
}