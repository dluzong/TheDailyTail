import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Medication {
  final String id;
  String name;
  String dose;
  String frequency;
  List<String> loggedDates; // yyyy-MM-dd
  String? loggedAt; 

  Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.frequency,
    List<String>? loggedDates,
    this.loggedAt,
  }) : loggedDates = loggedDates ?? <String>[];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'dose': dose,
        'frequency': frequency,
        'loggedDates': loggedDates,
        'loggedAt': loggedAt ?? '',
      };

  factory Medication.fromMap(Map<String, dynamic> map, {String? fallbackId}) {
    final ld = (map['loggedDates'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    String? la = map['loggedAt']?.toString();
    if (la != null && la.isEmpty) la = null;
    return Medication(
      id: (map['id'] as String?) ?? fallbackId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: (map['name'] as String?) ?? '',
      dose: (map['dose'] as String?) ?? '',
      frequency: (map['frequency'] as String?) ?? '',
      loggedDates: ld,
      loggedAt: la,
    );
  }
}

class MedicationsProvider extends ChangeNotifier {
  static const _storageKey = 'medications_master';

  final List<Medication> _items = [];

  List<Medication> get all => List.unmodifiable(_items);

  List<Medication> forDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return _items.where((m) => m.loggedDates.contains(key)).toList(growable: false);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null) return;
    try {
      final List list = jsonDecode(jsonStr) as List;
      _items
        ..clear()
        ..addAll(list.asMap().entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          // Ensure id exists
          return Medication.fromMap(map, fallbackId: 'm_${e.key}_${DateTime.now().microsecondsSinceEpoch}');
        }));
      notifyListeners();
    } catch (_) {
      // ignore malformed
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_items.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> addMedication({
    required String name,
    required String dose,
    required String frequency,
  }) async {
    final med = Medication(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      dose: dose,
      frequency: frequency,
    );
    _items.add(med);
    await _save();
    notifyListeners();
  }

  Future<void> deleteMedication(String id) async {
    _items.removeWhere((m) => m.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> logForDate(String id, DateTime date) async {
    final med = _items.firstWhere((m) => m.id == id, orElse: () => throw ArgumentError('Medication not found'));
    final key = DateFormat('yyyy-MM-dd').format(date);
    if (!med.loggedDates.contains(key)) med.loggedDates.add(key);
    med.loggedAt = DateTime(
      date.year,
      date.month,
      date.day,
      DateTime.now().hour,
      DateTime.now().minute,
      DateTime.now().second,
      DateTime.now().millisecond,
      DateTime.now().microsecond,
    ).toIso8601String();
    await _save();
    notifyListeners();
  }

  Future<void> removeLogForDate(String id, DateTime date) async {
    final med = _items.firstWhere((m) => m.id == id, orElse: () => throw ArgumentError('Medication not found'));
    final key = DateFormat('yyyy-MM-dd').format(date);
    med.loggedDates.removeWhere((d) => d == key);
    // Update last logged to latest remaining date if any
    if (med.loggedDates.isEmpty) {
      med.loggedAt = null;
    } else {
      med.loggedDates.sort(); // yyyy-MM-dd sorts chronologically
      final latest = med.loggedDates.last;
      // Keep previous time component if present else set current time
      final parts = latest.split('-');
      final latestDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        DateTime.now().hour,
        DateTime.now().minute,
        DateTime.now().second,
        DateTime.now().millisecond,
        DateTime.now().microsecond,
      );
      med.loggedAt = latestDate.toIso8601String();
    }
    await _save();
    notifyListeners();
  }
}
