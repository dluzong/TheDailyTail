import 'package:flutter/material.dart';
import '../shared/app_layout.dart';
import '../shared/starting_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _bornController = TextEditingController();
  String? _sex;
  final TextEditingController _weightController = TextEditingController();
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _bornController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imagePath = image.path;
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

  void _save() {
    final name = _nameController.text.trim();
    final breed = _breedController.text.trim();
    final born = _bornController.text.trim();
    final weight = _weightController.text.trim();
    if (name.isEmpty || breed.isEmpty || born.isEmpty || weight.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a pet name')));
      return;
    }

    final Map<String, dynamic> petMap = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'type': '',
      'breed': _breedController.text.trim(),
      'age': 0,
      'imageUrl': _imagePath ?? '',
    };

    Navigator.of(context).pop(petMap);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 0,
      onTabSelected: (i) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 56,
              child: Stack(
                children: [
                  // Back button
                  Positioned(
                    left: 0,
                    top: 2,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                  ),
                  // Header
                  Center(
                    child: Text(
                      'Pet Profile',
                      style: GoogleFonts.inknutAntiqua(
                          fontSize: 24,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Insert pet photo (optional)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Center(
                child: Text(
                  'Upload a photo',
                  style: GoogleFonts.inknutAntiqua(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7496B3)),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF7496B3),
                  backgroundImage: _imagePath != null
                      ? (_imagePath!.startsWith('assets/')
                          ? AssetImage(_imagePath!) as ImageProvider
                          : FileImage(File(_imagePath!)))
                      : null,
                  child: _imagePath == null
                      ? const Icon(Icons.camera_alt,
                          size: 36, color: Colors.white)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Insert pet name
            Padding(
              padding: EdgeInsets.only(
                  top: 6.0,
                  bottom: 6.0,
                  left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Pet Name",
                style: GoogleFonts.inknutAntiqua(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(
                widthFactor: 0.9,
                child: buildAppTextField(
                    hint: 'Pet Name', controller: _nameController)),

            const SizedBox(height: 12),

            // Insert breed
            Padding(
              padding: EdgeInsets.only(
                  top: 6.0,
                  bottom: 6.0,
                  left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Breed",
                style: GoogleFonts.inknutAntiqua(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(
                widthFactor: 0.9,
                child: buildAppTextField(
                    hint: 'Breed', controller: _breedController)),

            const SizedBox(height: 12),

            // Insert birthday
            Padding(
              padding: EdgeInsets.only(
                  top: 6.0,
                  bottom: 6.0,
                  left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Birthday",
                style: GoogleFonts.inknutAntiqua(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(
                widthFactor: 0.9,
                child: buildAppTextField(
                    hint: 'Born (mm/dd/yy)', controller: _bornController)),

            const SizedBox(height: 12),

            // Insert sex
            Padding(
              padding: EdgeInsets.only(
                  top: 6.0,
                  bottom: 6.0,
                  left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Sex",
                style: GoogleFonts.inknutAntiqua(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.9,
              child: DropdownButtonFormField<String>(
                initialValue: _sex,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                decoration: InputDecoration(
                  hintText: 'Sex',
                  prefixStyle: GoogleFonts.inknutAntiqua(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7496B3)),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _sex = v),
              ),
            ),

            const SizedBox(height: 12),

            // Insert weight
            Padding(
              padding: EdgeInsets.only(
                  top: 6.0,
                  bottom: 6.0,
                  left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Weight",
                style: GoogleFonts.inknutAntiqua(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(
                widthFactor: 0.9,
                child: buildAppTextField(
                    hint: 'Weight (lbs)', controller: _weightController)),

            const SizedBox(height: 24),
            // Add pet button
            Center(
              child: SizedBox(
                width: 160,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8DB6D9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _save,
                  child: Text('Add Pet',
                      style: GoogleFonts.inknutAntiqua(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
