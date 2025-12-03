import 'package:flutter/material.dart';
import 'package:frontend/screens/launch_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../shared/app_layout.dart';
import '../shared/starting_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_pet_screen.dart';
import 'edit_pet_popup.dart';
import 'user_settings_dialogs.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import '../pet_provider.dart' as pet_provider;

class UserSettingsPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const UserSettingsPage({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = 'Your name';
  String _username = 'name123';

  late List<pet_provider.Pet> _pets;

  bool _isDirty = false;

  // User tags/roles selection (local state; persisted in future)
  final List<String> _availableTags = const ['owner', 'organizer', 'foster', 'visitor'];
  List<String> _selectedTags = ['visitor'];
  
  String? _profilePicturePath;
  final ImagePicker _picker = ImagePicker();
  String _bio = '';

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final up = Provider.of<UserProvider>(context, listen: false);
    final user = up.user;
    _name = user?.name ?? _name;
    _username = user?.username ?? _username;
    _profilePicturePath = user?.photoUrl.isNotEmpty == true ? user?.photoUrl : null;
    _bio = user?.bio ?? '';
    
    // Initialize selected tags from user's current roles (normalize to lowercase)
    final userRoles = user?.roles ?? [];
    _selectedTags = userRoles
        .map((role) => role.toLowerCase())
        .where((role) => _availableTags.contains(role))
        .toList();
    if (_selectedTags.isEmpty) {
      _selectedTags = ['visitor']; // Default to visitor if no valid tags
    }

    _pets = List.from(
      Provider.of<pet_provider.PetProvider>(context, listen: false).pets,
    );

    _nameController = TextEditingController(text: _name);
    _usernameController = TextEditingController(text: _username);
    _bioController = TextEditingController(text: _bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _saveSettings() {
    _username = _usernameController.text;
    _name = _nameController.text;
    _bio = _bioController.text;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final petProvider =
        Provider.of<pet_provider.PetProvider>(context, listen: false);

    userProvider.updateUserProfile(
      username: _username,
      name: _name,
      tags: _selectedTags,
      photoUrl: _profilePicturePath,
      bio: _bio,
    )
        .then((_) async {
      // Persist pets locally (local-only for now)
      await petProvider.setPetsLocal(_pets);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings have been saved!'),
            backgroundColor: Color.fromARGB(255, 114, 201, 182),
          ),
        );
        _isDirty = false;
        Navigator.of(context).pop();
      }
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  Future<void> _addNewPet() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const AddPetScreen()),
    );

    if (result == null) return;

    setState(() {
      final newPet = pet_provider.Pet(
        petId: result['id'] as String? ?? '',
        ownerId: result['ownerId'] as String? ?? '',
        name: result['name'] as String? ?? '',
        breed: result['breed'] as String? ?? '',
        age: (result['age'] is int)
            ? result['age'] as int
            : int.tryParse(result['age']?.toString() ?? '') ?? 0,
        weight: result['weight'] ?? 0.0,
        imageUrl: result['imageUrl'] as String? ?? '',
        logsIds: result['logIds'] as List<String>,
        savedMeals: result['savedMeals'] as List<String>,     
        status: result['status'] as String? ?? 'Owned',
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
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must have at least one pet.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final action = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('You have unsaved changes. Save before leaving?'),
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

    if (action == 'save') {
      // _saveSettings will call Navigator.pop() after saving, so return false to avoid double-pop
      _saveSettings();
      return false;
    }

    if (action == 'discard') {
      // allow pop and discard changes
      return true;
    }

    // cancel or null -> don't pop
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 0,
      onTabSelected: widget.onTabSelected,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 80,
                child: Stack(
                  children: [
                    Positioned(
                      left: 10,
                      top: 2,
                      bottom: 0,
                      child: IconButton(
                        iconSize: 32.0,
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back',
                      ),
                    ),
                    // Settings header
                    Center(
                      child: Text(
                        'Settings',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
              const SizedBox(height: 12),

              // Settings Tiles

              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Account Information',
                onTap: () => _showAccountInfoDialog(),
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.account_circle,
                title: 'Profile Picture',
                onTap: () => _showProfilePictureDialog(),
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.note_outlined,
                title: 'Edit About',
                onTap: () => _showAboutDialog(),
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.label_outlined,
                title: 'User Tags',
                onTap: () => _showTagsDialog(),
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.pets,
                title: 'My Pets',
                onTap: () => _showPetsDialog(),
              ),

              const SizedBox(height: 16),

              // Logout button
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 190,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: () => _handleLogout(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7496B3), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Color(0xFF7496B3), size: 28),
                          const SizedBox(width: 16),
                          Text(
                            'Log Out',
                            style: GoogleFonts.lato(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7496B3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBCD9EC)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF7496B3), size: 32),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 18,
            color: const Color(0xFF394957),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF7496B3), size: 42),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  void _showAccountInfoDialog() {
    UserSettingsDialogs.showAccountInfoDialog(
      context: context,
      formKey: _formKey,
      nameController: _nameController,
      usernameController: _usernameController,
      onMarkDirty: _markDirty,
    );
  }

  void _showProfilePictureDialog() {
    UserSettingsDialogs.showProfilePictureDialog(
      context: context,
      picker: _picker,
      profilePicturePath: _profilePicturePath,
      onImagePicked: (path) {
        setState(() {
          _profilePicturePath = path;
        });
      },
      onMarkDirty: _markDirty,
    );
  }

  void _showAboutDialog() {
    UserSettingsDialogs.showAboutDialog(
      context: context,
      bioController: _bioController,
      onMarkDirty: _markDirty,
    );
  }

  void _showTagsDialog() {
    UserSettingsDialogs.showTagsDialog(
      context: context,
      availableTags: _availableTags,
      selectedTags: _selectedTags,
      onTagsChanged: (tags) {
        setState(() {
          _selectedTags = tags;
        });
      },
      onMarkDirty: _markDirty,
    );
  }

  void _showPetsDialog() {
    UserSettingsDialogs.showPetsDialog(
      context: context,
      pets: _pets,
      onAddNewPet: () async {
        await _addNewPet();
      },
      onEditPet: _showEditPetDialog,
      onRemovePet: _removePet,
    );
  }

  void _showEditPetDialog(int index) {
    final pet = _pets[index];

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => EditPetPopup(
        pet: pet,
        onSave: (updatedPet) {
          setState(() {
            _pets[index] = updatedPet;
            _markDirty();
          });
          _showPetsDialog();
        },
      ),
    );
  }

  // Logs out user and sends them back to the launch screen
  Future<void> _handleLogout() async {
    final should = await UserSettingsDialogs.showLogoutDialog(context);

    if (should == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Logged out')));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LaunchScreen()),
          (route) => false,
        );
      }
    }
  }


}
