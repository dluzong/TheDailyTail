import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _orgMembersChannel;

  final Set<String> _pendingJoin = <String>{};
  final Set<String> _pendingLeave = <String>{};

  List<Map<String, dynamic>> _allOrgs = [];
  List<Map<String, dynamic>> get allOrgs => _allOrgs;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  OrganizationProvider() {
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    if (_orgMembersChannel != null) {
      try {
        _orgMembersChannel!.unsubscribe();
      } catch (_) {}
      try {
        _supabase.removeChannel(_orgMembersChannel!);
      } catch (_) {}
      _orgMembersChannel = null;
    }
    super.dispose();
  }

  Future<void> fetchOrganizations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('organizations')
          .select('*, organization_members(count)')
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
      _pendingJoin.add(orgId);
      _adjustMemberCount(orgId, 1);
      notifyListeners();

      await _supabase.from('organization_members').insert({
        'organization_id': orgId,
        'user_id': userId,
        'role': 'member',
      });
    } catch (e) {
      debugPrint('ERROR: Error joining org: $e');
      if (_pendingJoin.remove(orgId)) {
        _adjustMemberCount(orgId, -1);
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> leaveOrg(String orgId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _pendingLeave.add(orgId);
      _adjustMemberCount(orgId, -1);
      notifyListeners();

      await _supabase.from('organization_members').delete().match({
        'organization_id': orgId,
        'user_id': userId,
      });
    } catch (e) {
      debugPrint('ERROR: Error leaving org: $e');
      if (_pendingLeave.remove(orgId)) {
        _adjustMemberCount(orgId, 1);
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> createOrganization({
    required String name,
    required String description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase.from('organizations').insert({
        'name': name,
        'description': description,
      }).select();

      if (response.isNotEmpty) {
        final newOrg = Map<String, dynamic>.from(response[0]);
        final String orgId = newOrg['organization_id'] as String;

        // 2) Add creator as owner in organization_members
        try {
          await _supabase.from('organization_members').insert({
            'organization_id': orgId,
            'user_id': userId,
            'role': 'owner',
          });
        } catch (e) {
          // If membership insert fails, still add org but with 0 count
          debugPrint('Warning: failed to add owner membership: $e');
        }

        newOrg['name'] = newOrg['name'] ?? name;
        newOrg['description'] = newOrg['description'] ?? description;

        // Seed local member count as 1 (creator)
        newOrg['organization_members'] = [
          {'count': 1}
        ];
        _allOrgs.add(newOrg);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error creating org: $e');
      rethrow;
    }
  }

  Future<void> updateOrganization(
    String orgId, {
    String? name,
    String? description,
  }) async {
    final Map<String, dynamic> updates = {};

    if (name != null) {
      updates['name'] = name;
    }
    if (description != null) {
      updates['description'] = description;
    }
    if (updates.isEmpty) return;

    try {
      final List<dynamic> result = await _supabase
          .from('organizations')
          .update(updates)
          .eq('organization_id', orgId)
          .select();

      if (result.isEmpty) {
        throw Exception('Update did not affect any rows');
      }
    } catch (e) {
      debugPrint('Error updating organization $orgId: $e');
      rethrow;
    }

    // Update local cache
    final idx =
        _allOrgs.indexWhere((o) => (o['organization_id'] as String?) == orgId);
    if (idx != -1) {
      final org = Map<String, dynamic>.from(_allOrgs[idx]);
      org.addAll(updates);
      _allOrgs[idx] = org;
      notifyListeners();
    }
  }

  void _adjustMemberCount(String orgId, int delta) {
    final idx =
        _allOrgs.indexWhere((o) => (o['organization_id'] as String?) == orgId);
    if (idx == -1) return;
    final org = _allOrgs[idx];
    int current = 0;
    if (org['organization_members'] is List &&
        (org['organization_members'] as List).isNotEmpty) {
      current = (org['organization_members'][0]['count'] as int?) ?? 0;
    }
    final next = (current + delta).clamp(0, 1 << 30);
    org['organization_members'] = [
      {'count': next}
    ];
    _allOrgs[idx] = org;
  }

  void _subscribeToRealtime() {
    // keep counts in sync with server using realtime DB changes
    _orgMembersChannel = _supabase
        .channel('realtime:organization_members')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'organization_members',
          callback: (payload) {
            final data = payload.newRecord;
            final String? orgId = data['organization_id'] as String?;
            if (orgId == null) return;
            // If we already applied optimistic update for this join, skip
            if (_pendingJoin.remove(orgId)) return;
            _adjustMemberCount(orgId, 1);
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'organization_members',
          callback: (payload) {
            final data = payload.oldRecord;
            final String? orgId = data['organization_id'] as String?;
            if (orgId == null) return;
            if (_pendingLeave.remove(orgId)) return;
            _adjustMemberCount(orgId, -1);
            notifyListeners();
          },
        )
        .subscribe();
  }
}
