import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Map<String, dynamic> toMap() => {
        'pet_id': petId,
        'user_id': userId,
        'name': name,
        'breed': breed,
        'age': age,
        'weight': weight,
        'image_url': imageUrl,
        'status': status,
      };
}

class PetProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Pet> _pets = [];
  List<Pet> get pets => _pets;

  // Track which pet is currently being viewed in the Dashboard/Logs
  String? _selectedPetId;
  String? get selectedPetId => _selectedPetId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void selectPet(String petId) {
    _selectedPetId = petId;
    notifyListeners();
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

      // Auto-select first pet if none selected
      if (_pets.isNotEmpty && _selectedPetId == null) {
        _selectedPetId = _pets.first.petId;
      }
    } catch (e) {
      debugPrint('Error fetching pets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPet(Pet pet) async {
    // Implement insert logic here matching your add_pet_screen
    // ...
    await fetchPets();
  }
}
