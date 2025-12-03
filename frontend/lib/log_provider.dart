import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PetLog {
  final String logId;
  final String petId;
  final DateTime date;
  final String
      type; // 'meal', 'medication', 'event', 'appointment', 'vaccination'
  final Map<String, dynamic> details;

  PetLog({
    required this.logId,
    required this.petId,
    required this.date,
    required this.type,
    required this.details,
  });

  factory PetLog.fromMap(Map<String, dynamic> map) {
    return PetLog(
      logId: map['log_id'] ?? '',
      petId: map['pet_id'] ?? '',
      date: DateTime.parse(map['log_date']),
      type: map['log_type'] ?? 'general',
      details: map['log_details'] ?? {},
    );
  }
}

class LogProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Cache: Map<PetId, List<Log>>
  final Map<String, List<PetLog>> _logs = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- FETCHING ---

  Future<void> fetchLogs(String petId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('logs')
          .select()
          .eq('pet_id', petId)
          .order('log_date', ascending: false);

      _logs[petId] = List<Map<String, dynamic>>.from(response)
          .map((data) => PetLog.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- GENERIC ADD/DELETE ---

  Future<void> addLog({
    required String petId,
    required String type,
    required DateTime date,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _supabase.from('logs').insert({
        'pet_id': petId,
        'log_type': type,
        'log_date': date.toIso8601String(),
        'log_details': details,
      });
      await fetchLogs(petId); // Refresh local state
    } catch (e) {
      debugPrint('Error adding log: $e');
      rethrow;
    }
  }

  Future<void> deleteLog(String logId, String petId) async {
    try {
      await _supabase.from('logs').delete().eq('log_id', logId);
      _logs[petId]?.removeWhere((l) => l.logId == logId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting log: $e");
    }
  }

  // --- UI HELPERS (Bridging the gap for your existing screens) ---

  // For MealPlanScreen: Get meals for a specific date
  List<PetLog> getMealsForDate(String petId, DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return (_logs[petId] ?? [])
        .where((l) =>
            l.type == 'meal' &&
            DateFormat('yyyy-MM-dd').format(l.date) == dateStr)
        .toList();
  }

  // For MedicationScreen: Get all medication logs
  List<PetLog> getMedications(String petId) {
    return (_logs[petId] ?? []).where((l) => l.type == 'medication').toList();
  }

  // For DailyLogScreen (Calendar): Get events mapped by category
  // This mimics the structure your DailyLogScreen expects
  Map<String, List<Map<String, String>>> getEventsForCalendar(String petId) {
    final Map<String, List<Map<String, String>>> result = {
      'Appointments': [],
      'Vaccinations': [],
      'Events': [],
      'Other': [],
    };

    final logs = _logs[petId] ?? [];

    for (var log in logs) {
      // Map DB types to UI Categories
      String category = 'Other';
      if (['appointment', 'vaccination', 'event'].contains(log.type)) {
        // Capitalize for UI
        category = "${log.type[0].toUpperCase()}${log.type.substring(1)}s";
      }

      if (result.containsKey(category)) {
        result[category]!.add({
          'id': log.logId, // useful for delete
          'date': DateFormat('yyyy-MM-dd').format(log.date),
          'title': log.details['title'] ?? 'No Title',
          'desc': log.details['desc'] ?? '',
        });
      }
    }
    return result;
  }
}
