import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealEntry {
  final String name;
  final String amount;
  final DateTime time;

  MealEntry({
    required this.name,
    required this.amount,
    required this.time
  });

  // Used when sending 'log_details' to Supabase
  Map<String, dynamic> toDetailsMap() => {
    'name': name,
    'amount': amount,
    'time': time.toIso8601String(),
  };

  // Factory to create an entry from Supabase row data
  factory MealEntry.fromSupabaseRow(Map<String, dynamic> row) {
    final logDetails = row['log_details'];

    // Handle if log_details comes back as a JSON string or a Map
    final Map<String, dynamic> details = logDetails is String
        ? json.decode(logDetails)
        : logDetails ?? {};

    return MealEntry(
      name: (details['name'] ?? '') as String,
      amount: (details['amount'] ?? '') as String,
      time: DateTime.tryParse((details['time'] ?? '')) ?? DateTime.now(),
    );
  }
}

class MealsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final Map<String, List<MealEntry>> _mealsByDate = {};

  String _keyForDate(DateTime date) => '${DateFormat('yyyy-MM-dd').format(date)}';

  List<MealEntry> getMealsForDate(DateTime date) {
    final key = _keyForDate(date);
    final list = _mealsByDate[key];
    return list == null ? [] : List.unmodifiable(list);
  }

  /*
  Future<void> loadDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForDate(date);
    final jsonStr = prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) {
      _mealsByDate.remove(key);
      notifyListeners();
      return;
    }

    try {
      final decoded = json.decode(jsonStr) as List;
      _mealsByDate[key] = decoded.map((e) => MealEntry.fromMap(e as Map)).toList();
    } catch (_) {
      _mealsByDate.remove(key);
    }

    notifyListeners();
  }
  */

  Future<void> _saveDateKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _mealsByDate[key] ?? [];
    final encoded = json.encode(list.map((m) => m.toDetailsMap()).toList());
    await prefs.setString(key, encoded);
  }

  /// FETCH: Load meals for a specific Pet ID
  Future<void> loadDate(DateTime date, String petId) async {
    final dateStr = _keyForDate(date);

    try {
      final response = await _supabase
          .from('logs')
          .select()
          .eq('pet_id', petId) // Use the passed petId
          .eq('log_date', dateStr)
          .eq('log_type', 'meal')
          .order('log_date', ascending: true);

      final data = response as List<dynamic>;
      debugPrint('Loaded meals: $data');
      _mealsByDate[dateStr] = data
          .map((row) => MealEntry.fromSupabaseRow(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading meals: $e');
      _mealsByDate[dateStr] = [];
    }
    notifyListeners();
  }

  /// INSERT: Add a meal for a specific Pet ID
  Future<void> addMeal(DateTime date, String name, String amount, String petId) async {
    final dateStr = _keyForDate(date);
    final details = {
      'name': name,
      'amount': amount,
      'time': DateTime.now().toIso8601String(),
    };

    try {
      final response = await _supabase
          .from('logs')
          .insert({
        'pet_id': petId, // Use the passed petId
        'log_date': dateStr,
        'log_type': 'meal',
        'log_details': details,
      })
          .select()
          .single();

      // ... update local state ...
      if (response != null) {
        final newEntry = MealEntry.fromSupabaseRow(response);

        // Initialize list for this date if it doesn't exist yet
        if (_mealsByDate[dateStr] == null) {
          _mealsByDate[dateStr] = [];
        }

        // Add the new meal to the local list
        _mealsByDate[dateStr]!.add(newEntry);
      }
    } catch (e) {
      debugPrint('Error adding meal: $e');
    }
    notifyListeners();
  }

  Future<void> removeMealAt(DateTime date, int index) async {
    final key = _keyForDate(date);
    final list = _mealsByDate[key];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _saveDateKey(key);
    notifyListeners();
  }

  Future<void> clearDate(DateTime date) async {
    final key = _keyForDate(date);
    _mealsByDate.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    notifyListeners();
  }
}
