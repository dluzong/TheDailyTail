import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../shared/starting_widgets.dart';
import '../pet_provider.dart' as pet_provider;

class UserSettingsDialogs {
  // Color Constants
  static const Color darkBg = Color(0xFF2A2A2A);
  static const Color darkBgAlt = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF404040);
  static const Color darkButtonBg = Color(0xFF4A6B85);
  static const Color darkIconColor = Color(0xFF7FA8C7);
  static const Color darkInputBg = Color(0xFF2A2A2A);
  static const Color darkText = Colors.white;
  static const Color lightBg = Colors.white;
  static const Color lightBorder = Color(0xFF5F7C94);
  static const Color lightButtonBg = Color(0xFF7F9CB3);
  static const Color lightIconColor = Color(0xFF7496B3);
  static const Color lightText = Color(0xFF394957);
  
  // Helper getter for dark mode
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Build dialog decoration
  static BoxDecoration _buildDialogDecoration(BuildContext context) {
    final isDark = _isDark(context);
    return BoxDecoration(
      color: isDark ? darkBg : lightBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark ? darkBorder : Colors.grey.shade300,
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 12,
          offset: Offset(0, 6),
        )
      ],
    );
  }

  // Build dialog header
  static Widget _buildDialogHeader(
    BuildContext context,
    String title,
    VoidCallback onClose,
  ) {
    final isDark = _isDark(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.close,
                  color: isDark ? darkIconColor : lightIconColor),
              onPressed: onClose,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inknutAntiqua(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? darkText : lightText,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 4),
        Divider(
          height: 2,
          color: isDark ? darkBorder : lightBorder,
        ),
      ],
    );
  }

  // Build save button
  static Widget _buildSaveButton(
    BuildContext context,
    VoidCallback onSave, {
    String label = 'Save',
  }) {
    final isDark = _isDark(context);
    return Center(
      child: SizedBox(
        width: 160,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? darkButtonBg : lightButtonBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: onSave,
          child: Text(
            label,
            style: GoogleFonts.inknutAntiqua(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
  static void showAccountInfoDialog({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required TextEditingController usernameController,
    required VoidCallback onMarkDirty,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: _buildDialogDecoration(context),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDialogHeader(context, 'Your Account', () => Navigator.of(context).pop()),
                    const SizedBox(height: 20),
                    Center(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 8),
                              child: Text(
                                'Full Name',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _isDark(context) ? darkText : lightText,
                                ),
                              ),
                            ),
                            buildAppTextField(
                              hint: 'Enter your full name',
                              controller: nameController,
                              context: context,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 8),
                              child: Text(
                                'Username',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _isDark(context) ? darkText : lightText,
                                ),
                              ),
                            ),
                            buildAppTextField(
                              hint: 'Enter your username',
                              controller: usernameController,
                              context: context,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSaveButton(context, () {
                      if (formKey.currentState!.validate()) {
                        onMarkDirty();
                        Navigator.pop(context);
                      }
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void showProfilePictureDialog({
    required BuildContext context,
    required ImagePicker picker,
    required String? profilePicturePath,
    required Function(String path) onImagePicked,
    required VoidCallback onMarkDirty,
  }) {
    String? currentDialogPath = profilePicturePath;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: _buildDialogDecoration(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDialogHeader(context, 'Profile Picture', () => Navigator.of(context).pop()),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Upload a photo',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: lightIconColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            onImagePicked(image.path);
                            setDialogState(() {
                              currentDialogPath = image.path;
                            });
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to pick image: $e')),
                            );
                          }
                        }
                      },
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor: lightIconColor,
                        backgroundImage: currentDialogPath != null
                            ? (currentDialogPath!.startsWith('http')
                                    ? NetworkImage(currentDialogPath!)
                                    : FileImage(File(currentDialogPath!)))
                                as ImageProvider
                            : null,
                        child: currentDialogPath == null
                            ? const Icon(Icons.camera_alt,
                                size: 42, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSaveButton(context, () {
                    onMarkDirty();
                    Navigator.pop(context);
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void showAboutDialog({
    required BuildContext context,
    required TextEditingController bioController,
    required VoidCallback onMarkDirty,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: _buildDialogDecoration(context),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDialogHeader(context, 'About', () => Navigator.of(context).pop()),
                    const SizedBox(height: 20),
                    TextField(
                      controller: bioController,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Write something about yourself...',
                        hintStyle: GoogleFonts.lato(
                          color: _isDark(context)
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: _isDark(context)
                            ? darkInputBg
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFBCD9EC)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFBCD9EC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF7496B3), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: _isDark(context) ? darkText : lightText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSaveButton(context, () {
                      onMarkDirty();
                      Navigator.pop(context);
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void showTagsDialog({
    required BuildContext context,
    required List<String> availableTags,
    required List<String> selectedTags,
    required Function(List<String>) onTagsChanged,
    required VoidCallback onMarkDirty,
  }) {
    List<String> tempSelectedTags = List.from(selectedTags);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                decoration: _buildDialogDecoration(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDialogHeader(context, 'Your Tags', () => Navigator.of(context).pop()),
                    const SizedBox(height: 16),
                    Text(
                      'Select all tags that describe you:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: _isDark(context) ? darkText : lightText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: availableTags.map((tag) {
                        final isSelected = tempSelectedTags.contains(tag);
                        final isDark = _isDark(context);
                        
                        Color baseColor;
                        switch (tag.toLowerCase()) {
                          case 'owner':
                            baseColor = isDark
                                ? const Color(0xFF1F4A5F)
                                : const Color(0xFF2C5F7F);
                            break;
                          case 'organizer':
                            baseColor = isDark
                                ? const Color(0xFF3A5A75)
                                : const Color(0xFF5A8DB3);
                            break;
                          case 'foster':
                            baseColor = isDark
                                ? const Color(0xFF5F8FA8)
                                : const Color.fromARGB(255, 118, 178, 230);
                            break;
                          case 'visitor':
                            baseColor = isDark
                                ? const Color(0xFF2A4A65)
                                : const Color.fromARGB(255, 156, 201, 234);
                            break;
                          default:
                            baseColor = isDark
                                ? darkButtonBg
                                : lightButtonBg;
                        }
                        
                        final Color offColor = baseColor.withValues(alpha: 0.12);
                        return FilterChip(
                          label: Text(
                            tag[0].toUpperCase() + tag.substring(1),
                            style: GoogleFonts.lato(
                              color: isSelected ? Colors.white : baseColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: baseColor,
                          checkmarkColor: Colors.white,
                          backgroundColor: offColor,
                          side: BorderSide(color: baseColor.withValues(alpha: 0.6)),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                tempSelectedTags.add(tag);
                              } else {
                                tempSelectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _buildSaveButton(context, () {
                      if (tempSelectedTags.isEmpty) {
                        tempSelectedTags.add('visitor');
                      }
                      onTagsChanged(tempSelectedTags);
                      onMarkDirty();
                      Navigator.pop(context);
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  static void showPetsDialog({
    required BuildContext context,
    required List<pet_provider.Pet> pets,
    required VoidCallback onAddNewPet,
    required Function(int index) onEditPet,
    required Function(int index) onRemovePet,
  }) {
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
              color: _isDark(context) ? darkBgAlt : lightBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: _isDark(context) ? darkBorder : Colors.grey.shade300),
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
                      icon: Icon(Icons.close,
                          color: _isDark(context) ? darkIconColor : lightIconColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'My Pets',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: _isDark(context) ? darkText : lightText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onAddNewPet,
                      icon: Icon(
                        Icons.add_circle,
                        color: _isDark(context) ? darkIconColor : lightIconColor,
                        size: 28,
                      ),
                      tooltip: 'Add New Pet',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(
                    height: 2,
                    color: _isDark(context) ? darkBorder : lightBorder),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      final pet = pets[index];
                      final isDark = _isDark(context);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3A4A5F)
                              : const Color(0xFFEEF7FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark
                                  ? const Color(0xFF4A5A6F)
                                  : const Color(0xFFBCD9EC)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isDark
                                  ? const Color(0xFF5A7A95)
                                  : lightIconColor,
                              backgroundImage: pet.imageUrl.isNotEmpty
                                  ? (pet.imageUrl.startsWith('http')
                                      ? NetworkImage(pet.imageUrl)
                                      : AssetImage(pet.imageUrl) as ImageProvider)
                                  : null,
                              child: pet.imageUrl.isEmpty
                                  ? const Icon(Icons.pets, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pet.name,
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? darkText : lightText,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: isDark ? darkIconColor : lightIconColor),
                              onPressed: () {
                                Navigator.pop(context);
                                onEditPet(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Color.fromARGB(255, 241, 78, 66)),
                              onPressed: () {
                                onRemovePet(index);
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

  static Future<bool?> showLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 325),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: _buildDialogDecoration(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDialogHeader(context, 'Log Out', () => Navigator.of(context).pop(false)),
                const SizedBox(height: 20),
                Text(
                  'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    color: _isDark(context) ? Colors.white70 : lightText,
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
                          side: BorderSide(
                              color: _isDark(context)
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                              width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inknutAntiqua(
                            color: _isDark(context) ? darkText : lightText,
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
                          backgroundColor: lightButtonBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'Log Out',
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
  }
}
