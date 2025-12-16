import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../pet_provider.dart' as pet_provider;
import '../shared/starting_widgets.dart';

class EditPetPopup extends StatefulWidget {
  final pet_provider.Pet pet;

  const EditPetPopup({
    super.key,
    required this.pet,
  });

  @override
  State<EditPetPopup> createState() => _EditPetPopupState();
}

class _EditPetPopupState extends State<EditPetPopup> {
  late TextEditingController nameController;
  late TextEditingController breedController;
  late TextEditingController ageController;
  late TextEditingController weightController;
  String? tempImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.pet.name);
    breedController = TextEditingController(text: widget.pet.breed);
    ageController = TextEditingController(text: widget.pet.age.toString());
    weightController = TextEditingController(text: widget.pet.weight.toString());
    tempImagePath = widget.pet.imageUrl.isNotEmpty ? widget.pet.imageUrl : null;
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    ageController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          tempImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _handleSave() {
    final name = nameController.text.trim();
    final breed = breedController.text.trim();
    final age = int.tryParse(ageController.text.trim()) ?? 0;
    final weight = double.tryParse(weightController.text.trim()) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet name is required')),
      );
      return;
    }

    Navigator.of(context).pop({
      'name': name,
      'breed': breed,
      'age': age,
      'weight': weight,
      'imageUrl': tempImagePath,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 14,
          ),
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
                      : Colors.grey.shade300),
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
                          'Edit Pet',
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
                          : const Color(0xFF5F7C94)),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Upload a photo',
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF7FA8C7)
                            : const Color(0xFF7496B3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF5A7A95)
                            : const Color(0xFF7496B3),
                        backgroundImage: tempImagePath != null
                            ? (tempImagePath!.startsWith('http') || tempImagePath!.startsWith('assets/')
                            ? (tempImagePath!.startsWith('http')
                            ? NetworkImage(tempImagePath!)
                            : AssetImage(tempImagePath!)) as ImageProvider
                            : FileImage(File(tempImagePath!)))
                            : null,
                        child: tempImagePath == null
                            ? const Icon(Icons.camera_alt, size: 36, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Pet Name',
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF7FA8C7)
                            : const Color(0xFF7496B3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildAppTextField(
                    hint: 'Pet Name',
                    controller: nameController,
                    context: context,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Breed',
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF7FA8C7)
                            : const Color(0xFF7496B3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildAppTextField(
                    hint: 'Breed',
                    controller: breedController,
                    context: context,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Age',
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF7FA8C7)
                            : const Color(0xFF7496B3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildAppTextField(
                    hint: 'Age',
                    controller: ageController,
                    context: context,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Weight (lbs)',
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF7FA8C7)
                            : const Color(0xFF7496B3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildAppTextField(
                    hint: 'Weight',
                    controller: weightController,
                    context: context,
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
                        onPressed: _handleSave,
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
}
