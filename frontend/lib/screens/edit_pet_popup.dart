import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
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
  late TextEditingController birthdayController;
  late TextEditingController weightController;
  String? tempImagePath;
  final ImagePicker _picker = ImagePicker();
  
  static const _dateInputFormatter = _DateSlashFormatter();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.pet.name);
    breedController = TextEditingController(text: widget.pet.breed);
    birthdayController = TextEditingController(text: widget.pet.birthday);
    weightController = TextEditingController(text: widget.pet.weight.toString());
    tempImagePath = widget.pet.imageUrl.isNotEmpty ? widget.pet.imageUrl : null;
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    birthdayController.dispose();
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

  bool _isValidDate(String dateStr) {
    if (dateStr.length != 10) return false;
    
    final parts = dateStr.split('/');
    if (parts.length != 3) return false;
    
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    
    if (month == null || day == null || year == null) return false;
    
    if (month < 1 || month > 12) return false;
    if (year < 1900 || year > DateTime.now().year) return false;
    
    final daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    
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

  void _handleSave() {
    final name = nameController.text.trim();
    final breed = breedController.text.trim();
    final birthday = birthdayController.text.trim();
    final weight = double.tryParse(weightController.text.trim()) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet name is required')),
      );
      return;
    }

    if (birthday.isNotEmpty && birthday.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter birthday as mm/dd/yyyy')),
      );
      return;
    }

    if (birthday.isNotEmpty && !_isValidDate(birthday)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Birthday is not valid. Please enter a valid date.'),
          backgroundColor: Colors.red,
        ));
      return;
    }

    Navigator.of(context).pop({
      'name': name,
      'breed': breed,
      'age': birthday.isNotEmpty ? _calcAgeYears(birthday) : 0,
      'birthday': birthday,
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
                      'Birthday',
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
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: birthdayController,
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
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: weightController,
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

/// Ensures birthday input stays in mm/dd/yyyy with auto-padding and slashes.
class _DateSlashFormatter extends TextInputFormatter {
  const _DateSlashFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    String filtered = text.replaceAll(RegExp(r'[^0-9/]'), '');
    String digits = filtered.replaceAll('/', '');
    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }
    
    bool userTypedSlash = text.endsWith('/') && !oldValue.text.endsWith('/');
    
    StringBuffer buffer = StringBuffer();
    int digitIndex = 0;
    
    if (digitIndex < digits.length) {
      if (digitIndex + 1 < digits.length) {
        buffer.write(digits.substring(digitIndex, digitIndex + 2));
        digitIndex += 2;
      } else {
        if (userTypedSlash || (filtered.contains('/') && filtered.indexOf('/') <= 2)) {
          buffer.write('0${digits[digitIndex]}');
          digitIndex += 1;
        } else {
          buffer.write(digits[digitIndex]);
          digitIndex += 1;
        }
      }
      
      if (digitIndex < digits.length || (userTypedSlash && buffer.length <= 2)) {
        buffer.write('/');
      }
    }
    
    if (digitIndex < digits.length) {
      int dayStart = digitIndex;
      if (digitIndex + 1 < digits.length) {
        buffer.write(digits.substring(digitIndex, digitIndex + 2));
        digitIndex += 2;
      } else {
        int slashCount = filtered.split('/').length - 1;
        if (slashCount >= 2 || (userTypedSlash && buffer.toString().contains('/'))) {
          buffer.write('0${digits[digitIndex]}');
          digitIndex += 1;
        } else {
          buffer.write(digits[digitIndex]);
          digitIndex += 1;
        }
      }
      
      if (digitIndex < digits.length || (userTypedSlash && digitIndex > dayStart)) {
        buffer.write('/');
      }
    }
    
    if (digitIndex < digits.length) {
      buffer.write(digits.substring(digitIndex));
    }

    final formatted = buffer.toString();
    int cursorPosition = formatted.length;
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
