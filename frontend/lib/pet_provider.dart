import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pet Data Model
class Pet {
  final String petId;
  final String name;
  final String breed;
  final int age;
  final double weight;

  Pet({
    required this.petId,
    required this.name,
    required this.breed,
    required this.age,
    required this.weight,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      petId: map['pet_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Pet',
      breed: map['breed'] as String? ?? 'Unknown',
      age: map['age'] as int? ?? 0,
      weight: map['weight'] as double? ?? 0.0,
    );
  }
}

// Pet Activity Model
class PetActivity {
  final String activityId;
  final String description;
  final DateTime logDate;

  PetActivity({
    required this.activityId,
    required this.description,
    required this.logDate,
  });

  // unused ?
  factory PetActivity.fromMap(Map<String, dynamic> map) {
    return PetActivity(
      activityId: map['activity_id'] as String? ?? '',
      description: map['description'] as String? ?? 'No description',
      logDate:
          DateTime.tryParse(map['log_date'] as String? ?? '') ?? DateTime.now(),
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
    } catch (e) {
      debugPrint("Error fetching pets: $e");
      _setError("Failed to fetch pets. Please try again.");
      _pets = [];
    } finally {
      _setLoading(false);
    }
  }

  // Fetch Pet Activities for a specific pet
  Future<List<PetActivity>> fetchPetActivities(String petId) async {
    debugPrint('Fetching pet activities for petId: $petId');
    final session = _supabase.auth.currentSession;

    if (session == null) {
      debugPrint("No user logged in. Failed to fetch pet activities.");
      return [];
    }

    try {
      // 1. Get all activity rows for this pet
      final response = await _supabase
          .from('pet_activities')
          .select()
          .eq('pet_id', petId)
          .order('log_date', ascending: false);

      final List<PetActivity> allActivities = response.expand((row) {
        final List<PetActivity> activitiesFromThisRow = [];

        final String rowActivityId = row['activity_id'] as String? ?? '';
        final DateTime rowLogDate =
            DateTime.tryParse(row['log_date'] as String? ?? '') ??
                DateTime.now();

        try {
          // food entries
          if (row['food_entries'] != null && row['food_entries'] is List) {
            final List<dynamic> foods = row['food_entries'];
            for (var food in foods) {
              if (food is Map<String, dynamic>) {
                activitiesFromThisRow.add(
                  PetActivity(
                    activityId: rowActivityId,
                    logDate: rowLogDate,
                    description: 'Ate ${food['item']} at ${food['time']}.',
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
                activitiesFromThisRow.add(
                  PetActivity(
                    activityId: rowActivityId,
                    logDate: rowLogDate,
                    description:
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
                activitiesFromThisRow.add(
                  PetActivity(
                    activityId: rowActivityId,
                    logDate: rowLogDate,
                    description:
                        'Took ${med['Medication']} (${med['Dosage']}).',
                  ),
                );
              }
            }
          }
        } catch (e) {
          debugPrint("Error parsing activity JSON for row $rowActivityId: $e");
          activitiesFromThisRow.add(
            PetActivity(
              activityId: rowActivityId,
              logDate: rowLogDate,
              description: "Recorded an activity with corrupted data.",
            ),
          );
        }

        return activitiesFromThisRow;
      }).toList();

      debugPrint(
          "Fetched ${allActivities.length} activities for petId: $petId");

      return allActivities;
    } catch (e) {
      debugPrint("Error fetching pet activities: $e");
      return []; // Return an empty list on failure
    }
  }

  void clearPets() {
    _pets = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
