import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../shared/starting_widgets.dart';
import '../pet_provider.dart' as pet_provider;

class UserSettingsDialogs {
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
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF404040)
                    : Colors.grey.shade300,
              ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  )
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF7FA8C7)
                              : const Color(0xFF7496B3)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Your Account',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF394957),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(
                  height: 2,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF404040)
                      : const Color(0xFF5F7C94),
                ),
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
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF394957),
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
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF394957),
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
                Center(
                  child: SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4A6B85)
                            : const Color(0xFF7F9CB3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          onMarkDirty();
                          Navigator.pop(context);
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
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF404040)
                      : Colors.grey.shade300,
                ),
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
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF7FA8C7)
                                : const Color(0xFF7496B3)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Profile Picture',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inknutAntiqua(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF394957),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Divider(
                    height: 2,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF404040)
                        : const Color(0xFF5F7C94),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Upload a photo',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7496B3),
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
                            // 1. Update the parent state
                            onImagePicked(image.path);

                            // 2. Update the DIALOG state immediately to show the new preview
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
                        backgroundColor: const Color(0xFF7496B3),
                        backgroundImage: currentDialogPath != null
                            ? (currentDialogPath!.startsWith('http')
                                    // If it is a web URL (old image)
                                    ? NetworkImage(currentDialogPath!)
                                    // If it is a local path (new image)
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
                  Center(
                    child: SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF4A6B85)
                              : const Color(0xFF7F9CB3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          // Trigger the save when clicking "Save"
                          onMarkDirty();
                          Navigator.pop(context);
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
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF404040)
                    : Colors.grey.shade300,
              ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  )
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF7FA8C7)
                              : const Color(0xFF7496B3)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'About',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF394957),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(
                  height: 2,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF404040)
                      : const Color(0xFF5F7C94),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: bioController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Write something about yourself...',
                    hintStyle: GoogleFonts.lato(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF394957),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4A6B85)
                            : const Color(0xFF7F9CB3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        onMarkDirty();
                        Navigator.pop(context);
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
        ),
      ),
    );
  }

  // In user_settings_dialogs.dart

  static void showTagsDialog({
    required BuildContext context,
    required List<String> availableTags,
    required List<String> selectedTags,
    required Function(List<String>) onTagsChanged,
    required VoidCallback onMarkDirty,
  }) {
    const Map<String, Color> tagColors = {
      'owner': Color(0xFF2C5F7F), // deep navy blue
      'organizer': Color(0xFF5A8DB3), // medium blue
      'foster': Color(0xFF76B2E6), // light sky blue
      'visitor': Color(0xFF9CC9EA), // pale blue
    };

    // Create a local copy so we don't modify the parent state until "Save" is clicked
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
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF404040)
                    : Colors.grey.shade300,
              ),
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
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.close,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF7FA8C7)
                                  : const Color(0xFF7496B3)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            'Your Tags',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inknutAntiqua(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF394957),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the close button
                      ],
                    ),
                    const SizedBox(height: 4),
                    Divider(
                      height: 2,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF404040)
                          : const Color(0xFF5F7C94),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select all tags that describe you:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF394957),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: availableTags.map((tag) {
                        final isSelected = tempSelectedTags.contains(tag);
                        final Color baseColor =
                            tagColors[tag] ?? const Color(0xFF7496B3);
                        final Color offColor = baseColor.withValues(alpha: 0.12);
                        return FilterChip(
                          label: Text(
                            tag[0].toUpperCase() + tag.substring(1), // Capitalize
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

                    // Save Button
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
                            // Validate: Ensure at least one tag is selected if required
                            if (tempSelectedTags.isEmpty) {
                              // Default to visitor if they try to save empty
                              tempSelectedTags.add('visitor');
                            }

                            onTagsChanged(tempSelectedTags);
                            onMarkDirty();
                            Navigator.pop(context);
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
                      onPressed: () {
                        onAddNewPet();
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
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      final pet = pets[index];
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
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFF7496B3)),
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
                        'Log Out',
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
                          side: BorderSide(
                              color: Colors.grey.shade400, width: 1.5),
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
