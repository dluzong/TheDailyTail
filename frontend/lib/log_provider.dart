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
  final DateTime? loggedAt; // precise timestamp when the log was created

  PetLog({
    required this.logId,
    required this.petId,
    required this.date,
    required this.type,
    required this.details,
    this.loggedAt,
  });

  factory PetLog.fromMap(Map<String, dynamic> map) {
    final details = Map<String, dynamic>.from(map['log_details'] ?? {});
    final loggedAtRaw = details['logged_at'];
    DateTime? loggedAt;
    if (loggedAtRaw is String) {
      loggedAt = DateTime.tryParse(loggedAtRaw);
    } else if (loggedAtRaw is DateTime) {
      loggedAt = loggedAtRaw;
    }

    return PetLog(
      logId: map['log_id'] ?? '',
      petId: map['pet_id'] ?? '',
      date: DateTime.parse(map['log_date']),
      type: map['log_type'] ?? 'general',
      details: details,
      loggedAt: loggedAt,
    );
  }
}

class LogProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

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
      final enrichedDetails = {
        ...details,
        'logged_at': date.toIso8601String(),
      };

      await _supabase.from('logs').insert({
        'pet_id': petId,
        'log_type': type,
        'log_date': date.toIso8601String(),
        'log_details': enrichedDetails,
      });
      await fetchLogs(petId);
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
      await fetchLogs(petId);
    }
  }

  // --- GETTERS FOR SCREENS ---
  List<PetLog> getLogsForPet(String petId) {
    return _logs[petId] ?? [];
  }

  List<PetLog> getMealsForDate(String petId, DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return (_logs[petId] ?? [])
        .where((l) =>
            l.type == 'meal' &&
            DateFormat('yyyy-MM-dd').format(l.date) == dateStr)
        .toList();
  }

  List<PetLog> getMedications(String petId) {
    return (_logs[petId] ?? []).where((l) => l.type == 'medication').toList();
  }

  Map<String, List<Map<String, String>>> getEventsForCalendar(String petId) {
    final Map<String, List<Map<String, String>>> result = {
      'Appointments': [],
      'Vaccinations': [],
      'Events': [],
      'Other': [],
    };

    final logs = _logs[petId] ?? [];

    for (var log in logs) {
      String category = 'Other';
      String title = log.details['title'] ?? 'No Title';
      String desc = log.details['desc'] ?? '';

      if (['appointment', 'vaccination', 'event'].contains(log.type)) {
        category = "${log.type[0].toUpperCase()}${log.type.substring(1)}s";
      } else if (log.type == 'meal') {
        title = "Meal: ${log.details['name'] ?? 'Unknown'}";
        desc = "Amount: ${log.details['amount'] ?? ''}";
      } else if (log.type == 'medication') {
        title = "Meds: ${log.details['name'] ?? 'Unknown'}";
        desc = "${log.details['dose'] ?? ''} ${log.details['frequency'] ?? ''}";
      }

      if (result.containsKey(category)) {
        result[category]!.add({
          'id': log.logId,
          'date': DateFormat('yyyy-MM-dd').format(log.date),
          'title': title,
          'desc': desc,
        });
      }
    }
    return result;
  }
}
