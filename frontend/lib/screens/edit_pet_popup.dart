import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../pet_provider.dart' as pet_provider;
import '../shared/starting_widgets.dart';

class EditPetPopup extends StatefulWidget {
  final pet_provider.Pet pet;
  final Function(pet_provider.Pet) onSave;

  const EditPetPopup({
    super.key,
    required this.pet,
    required this.onSave,
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

    final updatedPet = pet_provider.Pet(
      petId: widget.pet.petId,
      ownerId: widget.pet.ownerId,
      name: name,
      breed: breed,
      age: age,
      weight: weight,
      imageUrl: tempImagePath ?? '',
      logsIds: widget.pet.logsIds,
      savedMeals: widget.pet.savedMeals,
      status: widget.pet.status,
    );

    try {
      widget.onSave(updatedPet);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet updated!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
          child: SingleChildScrollView(
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
                        'Edit Pet',
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
                Center(
                  child: Text(
                    'Upload a photo',
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7496B3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF7496B3),
                      backgroundImage: tempImagePath != null
                          ? (tempImagePath!.startsWith('assets/')
                              ? AssetImage(tempImagePath!) as ImageProvider
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
                      color: const Color(0xFF7496B3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                buildAppTextField(
                  hint: 'Pet Name',
                  controller: nameController,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Breed',
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7496B3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                buildAppTextField(
                  hint: 'Breed',
                  controller: breedController,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Age',
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7496B3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                buildAppTextField(
                  hint: 'Age',
                  controller: ageController,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Weight (lbs)',
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7496B3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                buildAppTextField(
                  hint: 'Weight',
                  controller: weightController,
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
    );
  }
}
