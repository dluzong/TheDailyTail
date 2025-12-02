import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --------- MODELS ---------

class Pet {
  final String petId;
  final String userId;
  final String name;
  final String breed;
  final int age;
  final double weight;
  final String imageUrl;
  final String status;

  Pet({
    required this.petId,
    required this.userId,
    required this.name,
    required this.breed,
    required this.age,
    required this.weight,
    required this.imageUrl,
    required this.status,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      petId: map['pet_id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? 'Unnamed',
      breed: map['breed'] ?? 'Unknown',
      age: map['age'] ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url'] ?? '',
      status: map['status'] ?? 'owned',
    );
  }
}

class PetLog {
  final String logId;
  final String petId;
  final DateTime date;
  final String type; // 'meal', 'medication', 'event'
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

// ---------- PROVIDERS ----------

class PetProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Pet> _pets = [];
  final Map<String, List<PetLog>> _petLogs = {};

  List<Pet> get pets => _pets;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- PETS Methods ---

  Future<void> fetchPets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _pets = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _supabase.from('pets').select().eq('user_id', user.id);

      _pets = List<Map<String, dynamic>>.from(response)
          .map((data) => Pet.fromMap(data))
          .toList();

      for (var pet in _pets) {
        fetchLogsForPet(pet.petId);
      }
    } catch (e) {
      debugPrint('Error fetching pets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- LOGS Methods ---

  List<PetLog> getLogsForPet(String petId, {String? type}) {
    final logs = _petLogs[petId] ?? [];
    if (type == null) return logs;
    return logs.where((l) => l.type == type).toList();
  }

  Future<void> fetchLogsForPet(String petId) async {
    try {
      final response = await _supabase
          .from('logs')
          .select()
          .eq('pet_id', petId)
          .order('log_date', ascending: false);

      _petLogs[petId] = List<Map<String, dynamic>>.from(response)
          .map((data) => PetLog.fromMap(data))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching logs for $petId: $e');
    }
  }

  Future<void> addLog({
    required String petId,
    required String type, // 'meal', 'medication', or 'event'
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
      // perform refresh
      await fetchLogsForPet(petId);
    } catch (e) {
      debugPrint('Error adding log: $e');
      rethrow;
    }
  }
}
