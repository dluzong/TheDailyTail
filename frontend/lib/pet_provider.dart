import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Pet Data Model
class Pet {
  final String petId;
  final String ownerId;
  final String name;
  final String breed;
  final int age;
  final double weight;
  final String imageUrl;
  final List<String> logsIds;
  final List<String> savedMeals;
  final String status;

  Pet({
    required this.petId,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.age,
    required this.weight,
    required this.imageUrl,
    required this.logsIds,
    required this.savedMeals,
    required this.status,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      petId: map['pet_id'] as String? ?? '',
      ownerId: map['owner_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Pet',
      breed: map['breed'] as String? ?? 'Unknown',
      age: map['age'] as int? ?? 0,
      weight: map['weight'] as double? ?? 0.0,
      imageUrl: map['image_url'] as String? ?? '',
      logsIds: List<String>.from(map['logs_ids'] ?? []),
      savedMeals: List<String>.from(map['saved_meals'] ?? []),
      status: map['status'] as String? ?? 'Owned' // Assume pets are owned by default?
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pet_id': petId,
      'owner_id': ownerId,
      'name': name,
      'breed': breed,
      'age': age,
      'weight': weight,
      'image_url': imageUrl,
      'logs_ids': logsIds,
      'saved_meals': savedMeals,
      'status': status,
    };
  }
}

// Pet Log Model
class PetLog {
  final String logId;
  final String petId;
  final DateTime logDate;
  final String logType;
  final String logDetails;

  PetLog({
    required this.logId,
    required this.petId,
    required this.logDate,
    required this.logType,
    required this.logDetails
  });

  // unused ?
  factory PetLog.fromMap(Map<String, dynamic> map) {
    return PetLog(
      logId: map['log_id'] as String? ?? '',
      petId: map['pet_id'] as String? ?? '',
      logDate:
          DateTime.tryParse(map['log_date'] as String? ?? '') ?? DateTime.now(),
      logType: map['log_type'] as String? ?? '',
      logDetails: map['log_details'] as String? ?? '',
    );
  }
}

// PetProvider
class PetProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Pet> _pets = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Pet> get pets => _pets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const _cacheKey = 'cached_pets';

  PetProvider() {
    _loadFromCache();

    // Clear pets on sign-out
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        clearPets();
      }
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

// Fetch Pets for the authenticated user
  Future<void> fetchPets() async {
    debugPrint('Fetching pets data from Supabase');
    _setLoading(true);
    _setError(null);

    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        _pets = [];
        _setLoading(false);
        return;
      }

      final userId = session.user.id;
      final response =
          await _supabase.from('pets').select().eq('user_id', userId);

      _pets = response.map<Pet>((petData) => Pet.fromMap(petData)).toList();
      debugPrint("Saved pets data. Count: ${_pets.length}");
      await _saveToCache();
    } catch (e) {
      debugPrint("Error fetching pets: $e");
      _setError("Failed to fetch pets. Please try again.");
      _pets = [];
    } finally {
      _setLoading(false);
    }
  }

  // Fetch Pet Logs for a specific pet
  Future<List<PetLog>> fetchPetLogs(String petId) async {
    debugPrint('Fetching pet logs for petId: $petId');
    final session = _supabase.auth.currentSession;

    if (session == null) {
      debugPrint("No user logged in. Failed to fetch pet logs.");
      return [];
    }

    try {
      // 1. Get all log rows for this pet
      final response = await _supabase
          .from('logs')
          .select()
          .eq('pet_id', petId)
          .order('log_date', ascending: false);

      final List<PetLog> allLogs = response.expand((row) {
        final List<PetLog> logsFromThisRow = [];

        final String rowLogId = row['log_id'] as String? ?? '';
        final DateTime rowLogDate =
            DateTime.tryParse(row['log_date'] as String? ?? '') ??
                DateTime.now();

        try {
          // food entries
          if (row['food_entries'] != null && row['food_entries'] is List) {
            final List<dynamic> foods = row['food_entries'];
            for (var food in foods) {
              if (food is Map<String, dynamic>) {
                logsFromThisRow.add(
                  PetLog (
                    petId: petId,
                    logId: rowLogId,
                    logType: 'meal',
                    logDate: rowLogDate,
                    logDetails: 'Ate ${food['item']} at ${food['time']}.',
                  ),
                );
              }
            }
          }

          // walk entries
          if (row['walk_entries'] != null && row['walk_entries'] is List) {
            final List<dynamic> walks = row['walk_entries'];
            for (var walk in walks) {
              if (walk is Map<String, dynamic>) {
                logsFromThisRow.add(
                  PetLog(
                    petId: petId,
                    logId: rowLogId,
                    logType: 'walk',
                    logDate: rowLogDate,
                    logDetails:
                        'Walked for ${walk['duration']} at ${walk['time']}.',
                  ),
                );
              }
            }
          }

          // medication entries
          if (row['medication_entries'] != null &&
              row['medication_entries'] is List) {
            final List<dynamic> meds = row['medication_entries'];
            for (var med in meds) {
              if (med is Map<String, dynamic>) {
                logsFromThisRow.add(
                  PetLog(
                    petId: petId,
                    logId: rowLogId,
                    logType: 'medication',
                    logDate: rowLogDate,
                    logDetails:
                        'Took ${med['Medication']} (${med['Dosage']}).',
                  ),
                );
              }
            }
          }
        } catch (e) {
          debugPrint("Error parsing log JSON for row $rowLogId: $e");
          logsFromThisRow.add(
            PetLog(
              petId: petId,
              logId: rowLogId,
              logType: 'corrupted',
              logDate: rowLogDate,
              logDetails: "Recorded log with corrupted data.",
            ),
          );
        }

        return logsFromThisRow;
      }).toList();

      debugPrint(
          "Fetched ${allLogs.length} logs for petId: $petId");

      return allLogs;
    } catch (e) {
      debugPrint("Error fetching pet logs: $e");
      return []; // Return an empty list on failure
    }
  }

  void clearPets() {
    _pets = [];
    _errorMessage = null;
    _isLoading = false;
    _clearCache();
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return;
      final List<dynamic> list = json.decode(jsonStr);
      _pets = list
          .whereType<Map<String, dynamic>>()
          .map((m) => Pet.fromMap(m))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load cached pets: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        json.encode(_pets.map((p) => p.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('Failed to cache pets: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }

  Future<void> setPetsLocal(List<Pet> pets) async {
    _pets = List.from(pets);
    await _saveToCache();
    notifyListeners();
  }
}
