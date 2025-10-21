import 'package:flutter/material.dart';
import '../shared/app_layout.dart';
import '../shared/starting_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class Pet {
  final String id;
  final String name;
  final String type;
  final String breed;
  final int age;
  final String imageUrl;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    this.imageUrl = '',
  });

  Pet copyWith({
    String? id,
    String? name,
    String? type,
    String? breed,
    int? age,
    String? imageUrl,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Pet toPetListPet() {
    return Pet(
      id: id,
      name: name,
      type: type,
      breed: breed,
      age: age,
      imageUrl: imageUrl,
    );
  }
}

class UserSettingsPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<Pet> initialPets;
  final ValueChanged<List<Pet>> onPetsUpdated;

  const UserSettingsPage({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.initialPets,
    required this.onPetsUpdated,
  });

  @override
  // ignore: library_private_types_in_public_api
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = 'Your name';
  String _username = 'name123';
  
  late List<Pet> _pets;

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  List<TextEditingController> _petNameControllers = [];
  List<TextEditingController> _petTypeControllers = [];
  List<TextEditingController> _petBreedControllers = [];
  List<TextEditingController> _petAgeControllers = [];

  @override
  void initState() {
    super.initState();
    _pets = List.from(widget.initialPets);
    _nameController = TextEditingController(text: _name);
    _usernameController = TextEditingController(text: _username);
    _initializePetControllers();
  }

  void _initializePetControllers() {
    _petNameControllers = _pets.map((pet) => TextEditingController(text: pet.name)).toList();
    _petTypeControllers = _pets.map((pet) => TextEditingController(text: pet.type)).toList();
    _petBreedControllers = _pets.map((pet) => TextEditingController(text: pet.breed)).toList();
    _petAgeControllers = _pets.map((pet) => TextEditingController(text: pet.age.toString())).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    for (var controller in _petNameControllers) {
      controller.dispose();
    }
    for (var controller in _petTypeControllers) {
      controller.dispose();
    }
    for (var controller in _petBreedControllers) {
      controller.dispose();
    }
    for (var controller in _petAgeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _name = _nameController.text;
        _username = _usernameController.text;
        
        for (int i = 0; i < _pets.length; i++) {
          _pets[i] = _pets[i].copyWith(
            name: _petNameControllers[i].text,
            type: _petTypeControllers[i].text,
            breed: _petBreedControllers[i].text,
            age: int.tryParse(_petAgeControllers[i].text) ?? _pets[i].age,
          );
        }
        
        // add code to update the pet list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _addNewPet() {
    setState(() {
      final newPet = Pet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'pet name',
        type: 'pet type',
        breed: 'pet breed',
        age: 0,
      );
      _pets.add(newPet);
      _petNameControllers.add(TextEditingController(text: newPet.name));
      _petTypeControllers.add(TextEditingController(text: newPet.type));
      _petBreedControllers.add(TextEditingController(text: newPet.breed));
      _petAgeControllers.add(TextEditingController(text: newPet.age.toString()));
      
      // add functionality back to pet_list
    });
  }

  void _removePet(int index) {
    if (_pets.length > 1) {
      setState(() {
        _pets.removeAt(index);
        _petNameControllers.removeAt(index);
        _petTypeControllers.removeAt(index);
        _petBreedControllers.removeAt(index);
        _petAgeControllers.removeAt(index);
        
        // add functionality back to pet_list
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must have at least one pet.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: widget.currentIndex,
      onTabSelected: widget.onTabSelected,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.0),
                    ),
                  ),
                  
                  _buildSectionHeader('Profile Information'),
                  SizedBox(height: 16),
                  Center(
                    child: buildAppTextField(
                      hint: 'Enter your full name',
                      controller: _nameController,
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: buildAppTextField(
                      hint: 'Enter your username',
                      controller: _usernameController,
                    ),
                  ),
                  
                  SizedBox(height: 32),

                  _buildPetsSection(),
                  
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: buildAppButton(
                text: 'Save Settings',
                onPressed: _saveSettings,
                width: 200,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.inknutAntiqua(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7496B3),
          ),
        ),
      ),
    );
  }

  Widget _buildPetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: _buildSectionHeader('My Pets'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                onPressed: _addNewPet,
                icon: Icon(Icons.add_circle, color: Color(0xFF7496B3), size: 32),
                tooltip: 'Add New Pet',
              ),
            ),
          ],
        ),
        
        ...List.generate(_pets.length, (index) {
          return _buildPetCard(index);
        }),
      ],
    );
  }

  Widget _buildPetCard(int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pet ${index + 1}',
                  style: GoogleFonts.inknutAntiqua(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF7496B3),
                  ),
                ),
                if (_pets.length > 1)
                  IconButton(
                    onPressed: () => _removePet(index),
                    icon: Icon(Icons.delete, color: Colors.black, size: 24),
                    tooltip: 'Remove Pet',
                  ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: buildAppTextField(
                hint: 'Pet Name',
                controller: _petNameControllers[index],
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 140,
                      child: buildAppTextField(
                        hint: 'Type',
                        controller: _petTypeControllers[index],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 140,
                      child: buildAppTextField(
                        hint: 'Age',
                        controller: _petAgeControllers[index],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: buildAppTextField(
                hint: 'Breed',
                controller: _petBreedControllers[index],
              ),
            ),
          ],
        ),
      ),
    );
  }
}