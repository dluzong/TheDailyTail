import 'package:flutter/material.dart';
import '../shared/app_layout.dart';
import '../shared/starting_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_pet_screen.dart';

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
  final ValueChanged<Map<String, String>>? onProfileUpdated;

  const UserSettingsPage({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.initialPets,
    required this.onPetsUpdated,
    this.onProfileUpdated,
  });

  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = 'Your name';
  String _username = 'name123';
  
  late List<Pet> _pets;

  bool _isDirty = false;

  // Notification preferences
  bool _notifyEmail = true;
  bool _notifyPush = true;

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  // Settings now only show pet name and photo; no per-pet edit controllers required here.

  @override
  void initState() {
    super.initState();
    _pets = List.from(widget.initialPets);
    _nameController = TextEditingController(text: _name);
    _usernameController = TextEditingController(text: _username);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _name = _nameController.text;
        _username = _usernameController.text;
        // Pets are managed by add/remove; individual per-pet editing is not exposed here.
        // Notify parent about profile (name/username) changes if they provided a callback.
        try {
          widget.onProfileUpdated?.call({'name': _name, 'username': _username});
        } catch (_) {}
        // attempt to update the pet list
        try {
          widget.onPetsUpdated(List<Pet>.from(_pets));
        } catch (_) {
          // parent doesn't update pet list
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings have been saved!'),
          backgroundColor: const Color.fromARGB(255, 114, 201, 182),
        ),
      );
      // close settings and return to previous screen
      _isDirty = false;
      Navigator.of(context).pop();
    }
  }

  Future<void> _addNewPet() async {
    // Push the AddPetScreen and expect a Map<String, dynamic> describing the pet.
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const AddPetScreen()),
    );

    if (result == null) return;

    setState(() {
      final newPet = Pet(
        id: result['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name'] as String? ?? '',
        type: result['type'] as String? ?? '',
        breed: result['breed'] as String? ?? '',
        age: (result['age'] is int)
            ? result['age'] as int
            : int.tryParse(result['age']?.toString() ?? '') ?? 0,
        imageUrl: result['imageUrl'] as String? ?? '',
      );

      _pets.add(newPet);
      _markDirty();
    });
  }

  void _removePet(int index) {
    if (_pets.length > 1) {
      setState(() {
        _pets.removeAt(index);
        _markDirty();
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

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('You have unsaved changes. Save before leaving or discard changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      _saveSettings();
      // leave the page after saving settings
      return false;
    }

    if (result == 'discard') {
      return true; // leave page without saving
    }

    return false; // cancel 'leaving page'
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: widget.currentIndex,
      onTabSelected: widget.onTabSelected,
      child: PopScope(
        child: Stack(
          children: [
          // back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
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

                  const SizedBox(height: 20),
                  _buildNotificationsSection(),

                  const SizedBox(height: 12),
                  _buildLogoutButton(),
                  
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
          final pet = _pets[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: pet.imageUrl.isNotEmpty ? AssetImage(pet.imageUrl) as ImageProvider : null,
                backgroundColor: const Color(0xFFBFD4E6),
                child: pet.imageUrl.isEmpty ? const Icon(Icons.pets, color: Colors.white) : null,
              ),
              title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removePet(index),
                tooltip: 'Remove Pet',
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Notifications'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Email notifications', style: GoogleFonts.inknutAntiqua(fontSize: 16)),
                value: _notifyEmail,
                onChanged: (v) => setState(() {
                  _notifyEmail = v;
                  _markDirty();
                }),
              ),
              SwitchListTile(
                title: Text('Push notifications', style: GoogleFonts.inknutAntiqua(fontSize: 16)),
                value: _notifyPush,
                onChanged: (v) => setState(() {
                  _notifyPush = v;
                  _markDirty();
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: buildAppButton(
          text: 'Log out',
          onPressed: () async {
            final should = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Log out'),
                content: const Text('Are you sure you want to log out?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Log out')),
                ],
              ),
            );

            if (should == true) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
              // Close settings and return to previous screen. Real logout flow can be added later.
              Navigator.of(context).pop();
            }
          },
          width: 200,
        ),
      ),
    );
  }
}