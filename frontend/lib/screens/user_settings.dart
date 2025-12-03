import 'package:flutter/material.dart';
import 'package:frontend/screens/launch_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/app_layout.dart';
import '../shared/starting_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_pet_screen.dart';
import 'edit_pet_popup.dart';
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

  bool _notifyEmail = true;
  bool _notifyPush = true;

  // User tags/roles selection (local state; persisted in future)
  final List<String> _availableTags = const ['owner', 'organizer', 'foster', 'visitor'];
  List<String> _selectedTags = ['owner'];

  late TextEditingController _nameController;
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    final up = Provider.of<UserProvider>(context, listen: false);
    final user = up.user;
    _name = user?.name ?? _name;
    _username = user?.username ?? _username;
    
    // Initialize selected tags from user's current roles (normalize to lowercase)
    final userRoles = user?.roles ?? [];
    _selectedTags = userRoles
        .map((role) => role.toLowerCase())
        .where((role) => _availableTags.contains(role))
        .toList();
    if (_selectedTags.isEmpty) {
      _selectedTags = ['owner']; // Default to owner if no valid tags
    }

    _pets = List.from(
      Provider.of<pet_provider.PetProvider>(context, listen: false).pets,
    );

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
    _username = _usernameController.text;
    _name = _nameController.text;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final petProvider =
        Provider.of<pet_provider.PetProvider>(context, listen: false);

    userProvider.updateUserProfile(
      username: _username,
      name: _name,
      tags: _selectedTags,
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
            //DateTime.now().millisecondsSinceEpoch.toString(),
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
      currentIndex: widget.currentIndex,
      onTabSelected: widget.onTabSelected,
      showBackButton: true,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Settings header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Settings',
                  style: GoogleFonts.inknutAntiqua(
                    fontSize: 32,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
              ),
              const SizedBox(height: 12),

              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Account Information',
                onTap: () => _showAccountInfoDialog(),
              ),

              // New: User Tags tile
              _buildSettingsTile(
                icon: Icons.label_outlined,
                title: 'User Tags',
                onTap: () => _showTagsDialog(),
              ),

              _buildSettingsTile(
                icon: Icons.pets,
                title: 'My Pets',
                onTap: () => _showPetsDialog(),
              ),

              const SizedBox(height: 32),

              // Logout button
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 200,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => _handleLogout(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7496B3), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Log out',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7496B3),
                        ),
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
        leading: Icon(icon, color: const Color(0xFF7496B3), size: 24),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: const Color(0xFF394957),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF7496B3)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  void _showAccountInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF7496B3)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Account Information',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF394957),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(height: 2, color: Color(0xFF5F7C94)),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildAppTextField(
                        hint: 'Enter your full name',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 16),
                      buildAppTextField(
                        hint: 'Enter your username',
                        controller: _usernameController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7F9CB3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _markDirty();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Remember to save your changes!')),
                          );
                        }
                      },
                      child: Text(
                        'Save',
                        style: GoogleFonts.inknutAntiqua(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _showTagsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF7496B3)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'User Tags',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inknutAntiqua(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF394957),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 2, color: Color(0xFF5F7C94)),
                  const SizedBox(height: 16),
                  Text(
                    'Select all tags that describe you:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: const Color(0xFF394957),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _availableTags.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tag = entry.value;
                      final selected = _selectedTags.contains(tag);
                      
                      // Dramatic different shades of blue for each tag
                      final tagColors = [
                        const Color(0xFF2C5F7F), // owner - deep navy blue
                        const Color(0xFF5A8DB3), // organizer - medium blue
                        const Color.fromARGB(255, 118, 178, 230), // foster - light sky blue
                        const Color.fromARGB(255, 156, 201, 234), // visitor - pale blue
                      ];
                      
                      return FilterChip(
                        label: Text(
                          tag[0].toUpperCase() + tag.substring(1),
                          style: TextStyle(
                            color: selected ? tagColors[index] : Colors.white,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        selected: selected,
                        onSelected: (value) {
                          setDialogState(() {
                            setState(() {
                              if (value) {
                                _selectedTags = {..._selectedTags, tag}.toList();
                              } else {
                                _selectedTags = _selectedTags.where((t) => t != tag).toList();
                              }
                              _markDirty();
                            });
                          });
                        },
                        selectedColor: tagColors[index].withOpacity(0.2),
                        checkmarkColor: tagColors[index],
                        backgroundColor: tagColors[index],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F9CB3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Remember to save your changes!')),
                          );
                        },
                        child: Text(
                          'Done',
                          style: GoogleFonts.inknutAntiqua(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPetsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF7496B3)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'My Pets',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF394957),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _addNewPet();
                      },
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF7496B3),
                        size: 28,
                      ),
                      tooltip: 'Add New Pet',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(height: 2, color: Color(0xFF5F7C94)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _pets.length,
                    itemBuilder: (context, index) {
                      final pet = _pets[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF7FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBCD9EC)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFF7496B3),
                              child: Icon(Icons.pets, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pet.name,
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF394957),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF7496B3)),
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditPetDialog(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Color.fromARGB(255, 241, 78, 66)),
                              onPressed: () {
                                _removePet(index);
                                Navigator.pop(context);
                                _showPetsDialog();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
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

  Future<void> _handleLogout() async {
    final should = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF7496B3)),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    Expanded(
                      child: Text(
                        'Log out',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF394957),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(height: 2, color: Color(0xFF5F7C94)),
                const SizedBox(height: 20),
                Text(
                  'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    color: const Color(0xFF394957),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inknutAntiqua(
                            color: const Color(0xFF394957),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F9CB3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'Log out',
                          style: GoogleFonts.inknutAntiqua(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (should == true) {
      await Supabase.instance.client.auth.signOut();
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
