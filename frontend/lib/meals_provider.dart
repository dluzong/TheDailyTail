import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MealEntry {
  final String name;
  final String amount;
  final DateTime time;

  MealEntry({required this.name, required this.amount, required this.time});

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'time': time.toIso8601String(),
      };

  factory MealEntry.fromMap(Map m) => MealEntry(
        name: (m['name'] ?? '') as String,
        amount: (m['amount'] ?? '') as String,
        time: DateTime.parse((m['time'] ?? DateTime.now().toIso8601String()) as String),
      );
}

class MealsProvider extends ChangeNotifier {
  final Map<String, List<MealEntry>> _mealsByDate = {};

  String _keyForDate(DateTime date) => 'meals_${DateFormat('yyyy-MM-dd').format(date)}';

  List<MealEntry> getMealsForDate(DateTime date) {
    final key = _keyForDate(date);
    final list = _mealsByDate[key];
    return list == null ? [] : List.unmodifiable(list);
  }

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

  Future<void> _saveDateKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _mealsByDate[key] ?? [];
    final encoded = json.encode(list.map((m) => m.toMap()).toList());
    await prefs.setString(key, encoded);
  }

  Future<void> addMeal(DateTime date, String name, String amount) async {
    final key = _keyForDate(date);
    final entry = MealEntry(name: name, amount: amount, time: DateTime.now());
    _mealsByDate.putIfAbsent(key, () => []).add(entry);
    await _saveDateKey(key);
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
