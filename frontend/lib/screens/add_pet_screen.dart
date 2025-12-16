import 'package:flutter/material.dart';
import '../shared/app_layout.dart';
import '../shared/starting_widgets.dart';
import '../shared/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _species = 'Dog'; // default species
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _bornController = TextEditingController();
  String? _sex;
  final TextEditingController _weightController = TextEditingController();
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  // Formats birthday as mm/dd/yyyy while the user types digits only
  static const _dateInputFormatter = DateSlashFormatter();

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

  bool _isValidDate(String dateStr) {
    if (dateStr.length != 10) return false;
    
    final parts = dateStr.split('/');
    if (parts.length != 3) return false;
    
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    
    if (month == null || day == null || year == null) return false;
    
    // Check month range
    if (month < 1 || month > 12) return false;
    
    // Check year range (reasonable years for pets)
    if (year < 1900 || year > DateTime.now().year) return false;
    
    // Check day range based on month
    final daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    
    // Adjust for leap year
    if (month == 2) {
      final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      if (isLeapYear && day > 29) return false;
      if (!isLeapYear && day > 28) return false;
    } else {
      if (day < 1 || day > daysInMonth[month - 1]) return false;
    }
    
    return true;
  }

  int _calcAgeYears(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return 0;
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();
      int years = now.year - birthDate.year;
      if (DateTime(now.year, month, day).isAfter(now)) {
        years -= 1;
      }
      return years < 0 ? 0 : years;
    } catch (_) {
      return 0;
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final breed = _breedController.text.trim();
    final born = _bornController.text.trim();
    final weight = _weightController.text.trim();
    if (name.isEmpty || breed.isEmpty || born.isEmpty || weight.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    // Require full mm/dd/yyyy length
    if (born.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter birthday as mm/dd/yyyy')));
      return;
    }

    // Validate date
    if (!_isValidDate(born)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Birthday is not valid. Please enter a valid date.'),
            backgroundColor: Colors.red,
          ));
      return;
    }

    final Map<String, dynamic> petMap = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'type': _species, // Use selected species
      'breed': _breedController.text.trim(),
      'age': _calcAgeYears(born),
      'birthday': born,
      'weight': double.tryParse(weight) ?? 0.0,
      'imageUrl': _imagePath ?? '',
    };

    Navigator.of(context).pop(petMap);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 0,
      onTabSelected: (i) {},
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white,
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
                      icon: Icon(Icons.arrow_back,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
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
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black),
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF7FA8C7)
                          : const Color(0xFF7496B3)),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF5A7A95)
                      : const Color(0xFF7496B3),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF7FA8C7)
                        : const Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(
                widthFactor: 0.9,
                child: buildAppTextField(
                    hint: 'Pet Name', controller: _nameController, context: context)),

            const SizedBox(height: 12),

            // Insert Species
            Padding(
              padding: EdgeInsets.only(
                  top: 6.0,
                  bottom: 6.0,
                  left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Species",
                style: GoogleFonts.inknutAntiqua(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF7FA8C7)
                        : const Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.9,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3A3A3A)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _species,
                    isExpanded: true,
                    items: ['Dog', 'Cat', 'Other']
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s,
                                  style: GoogleFonts.lato(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _species = val);
                    },
                  ),
                ),
              ),
            ),

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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF7FA8C7)
                        : const Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(
                widthFactor: 0.9,
                child: buildAppTextField(
                    hint: 'Breed', controller: _breedController, context: context)),

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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF7FA8C7)
                        : const Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.9,
              child: TextField(
                controller: _bornController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _dateInputFormatter,
                ],
                style: GoogleFonts.inknutAntiqua(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'mm/dd/yyyy',
                  hintStyle: GoogleFonts.inknutAntiqua(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3A3A3A)
                      : Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF7FA8C7)
                        : const Color(0xFF7496B3)),
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
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Sex',
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3A3A3A)
                      : Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF7FA8C7)
                        : const Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.9,
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: GoogleFonts.inknutAntiqua(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Weight (lbs)',
                  hintStyle: GoogleFonts.inknutAntiqua(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3A3A3A)
                      : Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            // Add pet button
            Center(
              child: SizedBox(
                width: 160,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF4A6B85)
                        : const Color(0xFF8DB6D9),
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
      ),
    );
  }
}
