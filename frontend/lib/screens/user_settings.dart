import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'add_pet_screen.dart';
import 'edit_pet_popup.dart';
import 'user_settings_dialogs.dart';
import 'launch_screen.dart';
import '../user_provider.dart';
import '../pet_provider.dart' as pet_provider;
import '../theme_provider.dart';
import 'dart:io';


class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  _UserSettingsScreenState createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen>
    with SingleTickerProviderStateMixin {
  // We can access Supabase directly for auth actions like signOut
  final _supabase = Supabase.instance.client;
  
  late AnimationController _fadeController;

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
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    Future.microtask(() {
      if (mounted) {
        _fadeController.forward();
      }
    });
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
    _fadeController.dispose();
    super.dispose();
  }

  Future<bool> _isUsernameTaken(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking username: $e');
      // Default to true to prevent accidental overwrites on error
      return true;
    }
  }

  /// Uploads the local file to Supabase Storage and returns the Public URL
  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      // Create a unique file path: user_id/timestamp.jpg
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload to the 'avatars' bucket
      await _supabase.storage.from('avatars').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get the Public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

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



    // Regex check, check if username exists
    if (_username != _username.replaceAll(RegExp(r'[!@#$%^&*()+=:;,?/<>\s-]'), '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username has special characters. Failed to update.')),
      );
      return;
    }

    if (_usernameController.text.toString() != _username) {
      if (await _isUsernameTaken(_usernameController.text.toString())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username is already taken.')),
        );
        return;
      }
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
      if (!mounted) return;
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
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Color(0xFF72C9B6), duration: Duration(seconds: 1)),
        );

        // 4. HANDLE NAVIGATION (Logic from _saveSettings)
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addNewPet() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const AddPetScreen()),
    );

    if (result == null) return;

    try {
      final newPet = pet_provider.Pet(
        petId: result['id'] as String? ?? '',
        userId: result['userId'] as String? ?? '',
        name: result['name'] as String? ?? '',
        species: result['type'] as String? ?? 'Dog', // Map 'type' to 'species'
        breed: result['breed'] as String? ?? '',
        birthday: result['dob'] as String? ?? '',
        weight: (result['weight'] is num)
          ? (result['weight'] as num).toDouble()
          : double.tryParse(result['weight']?.toString() ?? '') ?? 0.0,
        imageUrl: result['imageUrl'] as String? ?? '',
        savedMeals: result['saved_meals'] as List<Map<String, dynamic>>? ?? [],
        savedMedications:
        result['saved_medications'] as List<Map<String, dynamic>>? ?? [],
        status: result['status'] as String? ?? 'owned',
      );

      await context.read<pet_provider.PetProvider>().addPet(newPet);

      if (mounted) {
        // ignore: use_build_context_synchronously
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
    debugPrint(
        "DEBUG: Original Pet ID: ${originalPet.petId}"); // Check your console

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => EditPetPopup(pet: originalPet),
    );

    if (result == null) return;

    try {
      String finalImageUrl = result['imageUrl'] ?? originalPet.imageUrl;

      if (finalImageUrl.isNotEmpty && !finalImageUrl.startsWith('http')) {
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

      final updatedPet = pet_provider.Pet(
        petId: originalPet.petId,
        userId: originalPet.userId,
        name: result['name'] ?? originalPet.name,
        species: originalPet.species, // Preserve existing species
        breed: result['breed'] ?? originalPet.breed,
        birthday: result['dob'] as String? ?? originalPet.birthday,
        weight: (result['weight'] is num)
            ? (result['weight'] as num).toDouble()
            : double.tryParse(result['weight']?.toString() ?? '') ??
                originalPet.weight,
        imageUrl: finalImageUrl, // Use the public URL, not local path
        savedMeals: originalPet.savedMeals,
        savedMedications: originalPet.savedMedications,
        status: originalPet.status,
      );
      debugPrint(
          "DEBUG: Sending Update for ID: ${updatedPet.petId}"); // Check this too


      await context.read<pet_provider.PetProvider>().updatePet(updatedPet);

      if (mounted) {
        // ignore: use_build_context_synchronously
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
      debugPrint("Removing pet: $petId");

      await context.read<pet_provider.PetProvider>().deletePet(petId);

      debugPrint("Pet deleted via provider");

      if (mounted) {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white,
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A4A65)
              : const Color(0xFF7496B3),
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 90,
          title: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Text(
              'Settings',
              style: GoogleFonts.inknutAntiqua(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: IconButton(
              icon: const Icon(Icons.close),
              iconSize: 28,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          centerTitle: true,
        ),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Body content
              Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF5F9FB),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              const SizedBox(height: 8),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFBCD9EC),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF7FA8C7)
                            : const Color(0xFF7496B3),
                        size: 32,
                      ),
                      title: Text(
                        themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF394957),
                        ),
                      ),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4A6B85)
                            : const Color(0xFF7496B3),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  );
                },
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
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF7FA8C7)
                              : const Color(0xFF7496B3),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF7FA8C7)
                                : const Color(0xFF7496B3),
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Log Out',
                            style: GoogleFonts.lato(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF7FA8C7)
                                  : const Color(0xFF7496B3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
                    const SizedBox(height: 150),
                  ],
                ),
              ),
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
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFBCD9EC),
        ),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF7FA8C7)
                : const Color(0xFF7496B3),
            size: 32),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 18,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF394957),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF7FA8C7)
              : const Color(0xFF7496B3),
          size: 42,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _showAccountInfoDialog() {
    UserSettingsDialogs.showAccountInfoDialog(
      context: context,
      formKey: _formKey,
      nameController: _nameController,
      usernameController: _usernameController,
      onMarkDirty: () {
        setState(() => _isDirty = true);
        _saveUserProfile();
      },
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
          _isDirty = true;
        });
      },
      onMarkDirty: () async {
        // Ensure state update completes before saving
        await Future.microtask(() {});
        if (mounted) _saveUserProfile();
      },
    );
  }

  void _showAboutDialog() {
    UserSettingsDialogs.showAboutDialog(
      context: context,
      bioController: _bioController,
      onMarkDirty: () {
        setState(() => _isDirty = true);
        _saveUserProfile();
      },
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
          _isDirty = true;
        });
      },
      onMarkDirty: () async {
        // Ensure state update completes before saving
        await Future.microtask(() {});
        if (mounted) _saveUserProfile();
      },
    );
  }

  void _showPetsDialog() {
    UserSettingsDialogs.showPetsDialog(
      context: context,
      pets: _pets,
      onAddNewPet: () async {
        Navigator.pop(context); // Close dialog to navigate
        await _addNewPet();
        if (mounted) {
          _showPetsDialog(); // Re-open dialog to show updated list
        }
      },
      onEditPet: (index) => _editPetInfo(_pets[index]),
      onRemovePet: (index) async {
        Navigator.pop(context); // Close dialog
        await _removePet(_pets[index].petId);
        if (mounted) {
          _showPetsDialog(); // Re-open dialog to show updated list
        }
      },
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
