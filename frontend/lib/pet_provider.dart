import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// --- PET MODEL ---
class Pet {
  final String petId;
  final String userId;
  final String name;
  final String species; // Added species
  final String breed;
  final String birthday; // mm/dd/yyyy
  final String sex;
  final double weight;
  final String imageUrl;
  final String status;
  final List<Map<String, dynamic>> savedMeals;
  final List<Map<String, dynamic>> savedMedications;

  Pet({
    required this.petId,
    required this.userId,
    required this.name,
    required this.species, // Added species
    required this.breed,
    required this.birthday,
    required this.sex,
    required this.weight,
    required this.imageUrl,
    required this.status,
    required this.savedMeals,
    required this.savedMedications,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      petId: map['pet_id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? 'Unnamed',
      species: map['species'] ?? 'Dog', // Default to Dog if missing
      breed: map['breed'] ?? 'Unknown',
      // Supabase column renamed to 'dob' (date of birth); keep fallback for legacy payloads
      birthday: map['dob'] ?? map['birthday'] ?? '',
      sex: map['sex'] ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url'] ?? '',
      status: map['status'] ?? 'owned',
      // Safe Parsing for Arrays (Handles both List<String> and List<JSON>)
      savedMeals: _parseList(map['saved_meals']),
      savedMedications: _parseList(map['saved_medications']),
    );
  }

  // Helper to handle Postgres Arrays safely
  static List<Map<String, dynamic>> _parseList(dynamic input) {
    if (input == null) return [];
    if (input is List) {
      return input.map((item) {
        // If it's already a map (JSONB), use it
        if (item is Map) return Map<String, dynamic>.from(item);
        // If it's a string (Text Array), wrap it in a map
        if (item is String) return {'name': item};
        return {'name': item.toString()};
      }).toList();
    }
    return [];
  }
}

// --- PROVIDER ---
class PetProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;

  List<Pet> _pets = [];
  List<Pet> get pets => _pets;

  String? _selectedPetId;
  String? get selectedPetId => _selectedPetId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- STATE MANAGEMENT ---

  PetProvider() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedOut:
          _clearState();
          break;
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
          await _loadSelectedPet();
          await fetchPets();
          break;
        default:
          // no-op
          break;
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _clearState() {
    _pets = [];
    _selectedPetId = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectPet(String petId) async {
    _selectedPetId = petId;
    notifyListeners();
    await _persistSelectedPet();
  }

  String _prefsKeyForUser(String userId) => 'selected_pet_' + userId;

  Future<void> _persistSelectedPet() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _selectedPetId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyForUser(user.id), _selectedPetId!);
  }

  Future<void> _loadSelectedPet() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKeyForUser(user.id));
    if (saved != null && saved.isNotEmpty) {
      _selectedPetId = saved;
      notifyListeners();
    }
  }

  Future<void> fetchPets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _supabase.from('pets').select().eq('user_id', user.id);

      _pets = List<Map<String, dynamic>>.from(response)
          .map((data) => Pet.fromMap(data))
          .toList();

      if (_pets.isNotEmpty) {
        final hasSelected = _selectedPetId != null &&
            _pets.any((p) => p.petId == _selectedPetId);
        if (!hasSelected) {
          _selectedPetId = _pets.first.petId;
          await _persistSelectedPet();
        }
      } else {
        _selectedPetId = null;
      }
    } catch (e) {
      debugPrint('Error fetching pets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- UPDATE PET LOGIC ---
  Future<void> updatePet(Pet updatedPet) async {
    final supabase = Supabase.instance.client;

    try {
      // 1. Update Supabase
      await supabase.from('pets').update({
        'name': updatedPet.name,
        'species': updatedPet.species,
        'breed': updatedPet.breed,
        'dob': updatedPet.birthday,
        'sex': updatedPet.sex,
        'weight': updatedPet.weight,
        'image_url': updatedPet.imageUrl,
        'status': updatedPet.status,
        'saved_meals': updatedPet.savedMeals,
        'saved_medications': updatedPet.savedMedications,
      }).eq('pet_id', updatedPet.petId); // CRITICAL: Use the ID to find the row

      // 2. Update Local State
      final index = _pets.indexWhere((p) => p.petId == updatedPet.petId);
      if (index != -1) {
        _pets[index] = updatedPet;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating pet: $e');
      rethrow; // Pass error back to UI
    }
  }

  // --- DELETE PET LOGIC ---
  Future<void> deletePet(String petId) async {
    try {
      // 1. Delete from Supabase
      await _supabase.from('pets').delete().eq('pet_id', petId);

      // 2. Update Local State
      _pets.removeWhere((p) => p.petId == petId);

      // If the selected pet was deleted, clear selection or select another
      if (_selectedPetId == petId) {
        _selectedPetId = _pets.isNotEmpty ? _pets.first.petId : null;
        await _persistSelectedPet();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      rethrow;
    }
  }

  // --- ADD PET LOGIC ---

  Future<void> addPet(Pet newPet) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Insert the new pet into the database
      // We exclude 'pet_id' so Postgres can generate a fresh UUID
      await _supabase.from('pets').insert({
        'user_id': user.id,
        'name': newPet.name,
        'species': newPet.species,
        'breed': newPet.breed,
        'dob': newPet.birthday,
        'sex': newPet.sex,
        'weight': newPet.weight,
        'image_url': newPet.imageUrl,
        'status': newPet.status,
        // Initialize empty arrays if not provided
        'saved_meals': newPet.savedMeals.isEmpty ? [] : newPet.savedMeals,
        'saved_medications':
            newPet.savedMedications.isEmpty ? [] : newPet.savedMedications,
      });

      // Refresh the list so the new pet appears in the app immediately
      await fetchPets();
    } catch (e) {
      debugPrint('Error adding pet: $e');
      rethrow;
    }
  }

  // --- SAVED MEALS LOGIC ---

  Future<void> addSavedMeal(String petId, Map<String, dynamic> mealData) async {
    try {
      // 1. Get current list
      final pet = _pets.firstWhere((p) => p.petId == petId);
      final updatedList = List<Map<String, dynamic>>.from(pet.savedMeals);

      // 2. Add new item
      updatedList.add(mealData);

      // 3. Update Database
      await _supabase
          .from('pets')
          .update({'saved_meals': updatedList}).eq('pet_id', petId);

      // 4. Refresh local state
      await fetchPets();
    } catch (e) {
      debugPrint("Error saving meal: $e");
      rethrow;
    }
  }

  Future<void> removeSavedMeal(String petId, int index) async {
    try {
      final pet = _pets.firstWhere((p) => p.petId == petId);
      final updatedList = List<Map<String, dynamic>>.from(pet.savedMeals);
      if (index < 0 || index >= updatedList.length) return;
      updatedList.removeAt(index);

      await _supabase
          .from('pets')
          .update({'saved_meals': updatedList}).eq('pet_id', petId);

      await fetchPets();
    } catch (e) {
      debugPrint("Error removing meal: $e");
      rethrow;
    }
  }

  // --- SAVED MEDICATIONS LOGIC ---

  Future<void> addSavedMedication(
      String petId, Map<String, dynamic> medData) async {
    try {
      final pet = _pets.firstWhere((p) => p.petId == petId);
      final updatedList = List<Map<String, dynamic>>.from(pet.savedMedications);
      updatedList.add(medData);

      await _supabase
          .from('pets')
          .update({'saved_medications': updatedList}).eq('pet_id', petId);

      await fetchPets();
    } catch (e) {
      debugPrint("Error saving medication: $e");
      rethrow;
    }
  }

  Future<void> removeSavedMedication(String petId, int index) async {
    try {
      final pet = _pets.firstWhere((p) => p.petId == petId);
      final updatedList = List<Map<String, dynamic>>.from(pet.savedMedications);
      if (index < 0 || index >= updatedList.length) return;
      updatedList.removeAt(index);

      await _supabase
          .from('pets')
          .update({'saved_medications': updatedList}).eq('pet_id', petId);

      await fetchPets();
    } catch (e) {
      debugPrint("Error removing medication: $e");
      rethrow;
    }
  }
}
