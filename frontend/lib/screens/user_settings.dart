import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/app_layout.dart';
import 'add_pet_screen.dart';
import 'edit_pet_popup.dart';
import 'user_settings_dialogs.dart';
import 'launch_screen.dart';
import '../user_provider.dart';
import '../pet_provider.dart' as pet_provider;
import 'dart:io';


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
  // We can access Supabase directly for auth actions like signOut
  final _supabase = Supabase.instance.client;

  String _name = '';
  String _username = '';

  bool _isDirty = false;

  // User tags/roles selection (local state; persisted in future)
  final List<String> _availableTags = const [
    'owner',
    'organizer',
    'foster',
    'visitor'
  ];
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
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context).user;

    if (user != null && !_isDirty) {
      _name = user.name;
      _username = user.username;
      _bio = user.bio;
      _profilePicturePath = user.photoUrl.isNotEmpty ? user.photoUrl : null;

      if (_nameController.text != _name) _nameController.text = _name;
      if (_usernameController.text != _username) {
        _usernameController.text = _username;
      }
      if (_bioController.text != _bio) _bioController.text = _bio;

      final userRoles = user.roles;
      _selectedTags = userRoles
          .map((role) => role.toLowerCase())
          .where((role) => _availableTags.contains(role))
          .toList();
      if (_selectedTags.isEmpty) {
        _selectedTags = ['visitor'];
      }
    }
  }

  List<pet_provider.Pet> get _pets {
    return Provider.of<pet_provider.PetProvider>(context, listen: false).pets;
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

  Future<bool> isUsernameAvailable(String username) async {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    if (currentUser?.username == username) {
      return true; // The username is the user's own, so it's "available"
    }

    // Check if the username exists for any other user
    try {
      final response = await _supabase
          .from('users')
          .select('user_id')
          .eq('username', username)
          .maybeSingle();
      return response == null; // True if available (no user found), false if taken
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      return false; // Fail safely, preventing a user from taking a username that might exist
    }
  }

  /// Uploads the local file to Supabase Storage and returns the Public URL
  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      // Create a unique file path: user_id/timestamp.jpg
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload to the 'avatars' bucket
      await _supabase.storage.from('avatars').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      // Get the Public URL
      final imageUrl =
      _supabase.storage.from('avatars').getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _deleteOldImage(String oldUrl) async {
    try {
      // 1. Parse the URL to find the path relative to the bucket
      final uri = Uri.parse(oldUrl);
      final pathSegments = uri.pathSegments;
      // pathSegments usually looks like: ['storage', 'v1', 'object', 'public', 'avatars', 'user_id', 'filename.jpg']

      // We need everything after 'avatars'
      final avatarIndex = pathSegments.indexOf('avatars');
      if (avatarIndex == -1 || avatarIndex + 1 >= pathSegments.length) return;

      final filePath = pathSegments.sublist(avatarIndex + 1).join('/');

      // 2. Delete the file
      if (filePath.isNotEmpty) {
        await _supabase.storage.from('avatars').remove([filePath]);
        debugPrint('Deleted old image: $filePath');
      }
    } catch (e) {
      // Don't stop the app if deletion fails, just log it
      debugPrint('Error deleting old image: $e');
    }
  }

  // formerly _saveDataOnly
  Future<void> _saveUserProfile({bool shouldPop = false}) async {
    // 1. Validate inputs locally first
    _username = _usernameController.text.trim();
    _name = _nameController.text.trim();
    _bio = _bioController.text.trim();

    // Regex check
    if (_username != _username.replaceAll(RegExp(r'[!@#$%^&*()+=:;,?/<>\s-]'), '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username has special characters. Failed to update.')),
      );
      return;
    }

    try {
      // 2. HANDLE IMAGE UPLOAD)
      String? finalPhotoUrl = _profilePicturePath;

      if (_profilePicturePath != null && !_profilePicturePath!.startsWith('http')) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final String oldPhotoUrl = userProvider.user?.photoUrl ?? '';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...'), duration: Duration(seconds: 1)),
        );

        final file = File(_profilePicturePath!);
        final uploadedUrl = await _uploadProfileImage(file);

        if (uploadedUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image upload failed.'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        // Delete old image if successful
        if (oldPhotoUrl.isNotEmpty && oldPhotoUrl.startsWith('http')) {
          await _deleteOldImage(oldPhotoUrl);
        }
        finalPhotoUrl = uploadedUrl;

        // Update local state to the web URL
        if(mounted) setState(() => _profilePicturePath = finalPhotoUrl);
      }

      // 3. UPDATE DATABASE
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateUserProfile(
        username: _username,
        name: _name,
        roles: _selectedTags,
        photoUrl: finalPhotoUrl,
        bio: _bio,
      );

      if (mounted) {
        setState(() => _isDirty = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Color(0xFF72C9B6)),
        );

        // 4. HANDLE NAVIGATION (Logic from _saveSettings)
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addNewPet() async {
    // 1. Get new pet details from the AddPetScreen
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const AddPetScreen()),
    );

    if (result == null) return;

    try {
      // 2. Create a Pet object (ID will be generated by DB, userId by Provider/DB)
      final newPet = pet_provider.Pet(
        petId: result['id'] as String? ?? '',
        userId: result['userId'] as String? ?? '',
        name: result['name'] as String? ?? '',
        breed: result['breed'] as String? ?? '',
        age: (result['age'] is int)
            ? result['age'] as int
            : int.tryParse(result['age']?.toString() ?? '') ?? 0,
        weight: result['weight'] ?? 0.0,
        imageUrl: result['imageUrl'] as String? ?? '',
        savedMeals: result['saved_meals'] as List<Map<String, dynamic>>? ?? [],
        savedMedications:
        result['saved_medications'] as List<Map<String, dynamic>>? ?? [],
        status: result['status'] as String? ?? 'owned',
      );

      // 3. Use the Provider to save to DB
      // Note: Ensure your PetProvider has the addPet method we defined!
      await context.read<pet_provider.PetProvider>().addPet(newPet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet added successfully!')),
        );
      }
    } catch (e) {
      debugPrint("Error adding pet: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add pet: $e')),
        );
      }
    }
  }


  Future<void> _editPetInfo(pet_provider.Pet originalPet) async {
    print("DEBUG: Original Pet ID: ${originalPet.petId}"); // Check your console

    // 1. Show the Edit Popup and wait for result
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditPetPopup(pet: originalPet),
    );

    // If user canceled, do nothing
    if (result == null) return;

    try {
      String finalImageUrl = result['imageUrl'] ?? originalPet.imageUrl;

      // 2. CHECK: Is this a new local file? (Not http... and not empty)
      if (finalImageUrl.isNotEmpty && !finalImageUrl.startsWith('http')) {
        // It's a local file path. Upload it!
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading pet image...')),
          );
        }

        final File imageFile = File(finalImageUrl);

        final uploadedUrl = await _uploadProfileImage(imageFile);

        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          throw Exception("Image upload failed");
        }
      }

      // 3. Create a new Pet object with the updated info
      final updatedPet = pet_provider.Pet(
        petId: originalPet.petId,
        userId: originalPet.userId,
        name: result['name'] ?? originalPet.name,
        breed: result['breed'] ?? originalPet.breed,
        age: result['age'] ?? originalPet.age,
        weight: result['weight'] ?? originalPet.weight,
        imageUrl: finalImageUrl, // Use the public URL, not local path
        savedMeals: originalPet.savedMeals,
        savedMedications: originalPet.savedMedications,
        status: originalPet.status,
      );
      print("DEBUG: Sending Update for ID: ${updatedPet.petId}"); // Check this too

      // 4. Call the provider to save to DB
      await context.read<pet_provider.PetProvider>().updatePet(updatedPet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet updated successfully!'),
            backgroundColor: Color(0xFF72C9B6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pet: $e')),
        );
      }
    }
  }

  Future<void> _removePet(String petId) async {
    try {
      // Direct DB delete for now, then refresh provider
      await _supabase.from('pets').delete().eq('pet_id', petId);

      if (mounted) {
        // Refresh the list in the provider
        await context.read<pet_provider.PetProvider>().fetchPets();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pet removed")),
        );
      }
    } catch (e) {
      debugPrint("Error removing pet: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to remove pet")),
        );
      }
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
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7496B3)),
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (action == 'save') {
      await _saveUserProfile(shouldPop: true);
      return false; // _saveSettings pops automatically on success
    }

    if (action == 'discard') return true;

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
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.black87),
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

              // Logout
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 190,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: () => _handleLogout(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF7496B3), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout,
                              color: Color(0xFF7496B3), size: 28),
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
        trailing:
            const Icon(Icons.chevron_right, color: Color(0xFF7496B3), size: 42),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  void _showAccountInfoDialog() {
    UserSettingsDialogs.showAccountInfoDialog(
      context: context,
      formKey: GlobalKey<FormState>(), // Use a fresh key for the dialog validation
      nameController: _nameController,
      usernameController: _usernameController,
      onMarkDirty: () => _saveUserProfile(),
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
      onMarkDirty: () => _saveUserProfile(),
    );
  }

  void _showAboutDialog() {
    UserSettingsDialogs.showAboutDialog(
      context: context,
      bioController: _bioController,
      onMarkDirty: () => _saveUserProfile(),
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
      onMarkDirty: () => _saveUserProfile()
    );
  }

  void _showPetsDialog() {
    UserSettingsDialogs.showPetsDialog(
      context: context,
      pets: _pets,
      onAddNewPet: () async {
        await _addNewPet();
      },
      onEditPet: (index) => _editPetInfo(_pets[index]),
      onRemovePet: (index) => _removePet(_pets[index].petId),
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