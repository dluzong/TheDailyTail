import 'package:flutter/material.dart';
import '../shared/app_layout.dart';
import '../shared/starting_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _bornController = TextEditingController(); // mm/dd/yy
  String? _sex;
  final TextEditingController _weightController = TextEditingController();
  String? _imagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _bornController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    // implement add image aspect
    setState(() {
      _imagePath = _imagePath == null ? 'assets/dog.png' : null;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a pet name')));
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
            // Top row: back button (left) and title aligned with form labels (left-padded)
            Container(
              height: 56,
              child: Stack(
                children: [
                  // Back button at the very left
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                  ),
                  // Centered title (back button stays at left)
                  Center(
                    child: Text(
                      'Pet Profile',
                      style: GoogleFonts.inknutAntiqua(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF7496B3)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Photo field (label)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Center(
                  child: Text(
                    'Upload a photo',
                    style: GoogleFonts.inknutAntiqua(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7496B3)),
                  ),
                ),
              ),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFBFD4E6),
                  backgroundImage: _imagePath != null ? AssetImage(_imagePath!) : null,
                  child: _imagePath == null
                      ? const Icon(Icons.camera_alt, size: 36, color: Colors.white)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pet Name
            Padding(
              padding: EdgeInsets.only(top: 6.0, bottom: 6.0, left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "What's your pet's name?",
                style: GoogleFonts.inknutAntiqua(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(widthFactor: 0.9, child: buildAppTextField(hint: 'Pet Name', controller: _nameController)),

            const SizedBox(height: 12),

            // Breed
            Padding(
              padding: EdgeInsets.only(top: 6.0, bottom: 6.0, left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "What’s your pet’s breed?",
                style: GoogleFonts.inknutAntiqua(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(widthFactor: 0.9, child: buildAppTextField(hint: 'Breed', controller: _breedController)),

            const SizedBox(height: 12),

            // Born
            Padding(
              padding: EdgeInsets.only(top: 6.0, bottom: 6.0, left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "When was your pet born?",
                style: GoogleFonts.inknutAntiqua(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(widthFactor: 0.9, child: buildAppTextField(hint: 'Born (mm/dd/yy)', controller: _bornController)),

            const SizedBox(height: 12),

            // Sex
            Padding(
              padding: EdgeInsets.only(top: 6.0, bottom: 6.0, left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Select your pet’s sex",
                style: GoogleFonts.inknutAntiqua(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7496B3)),
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
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _sex = v),
              ),
            ),

            const SizedBox(height: 12),

            // Weight
            Padding(
              padding: EdgeInsets.only(top: 6.0, bottom: 6.0, left: MediaQuery.of(context).size.width * 0.05),
              child: Text(
                "Select your pet’s weight",
                style: GoogleFonts.inknutAntiqua(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7496B3)),
              ),
            ),
            FractionallySizedBox(widthFactor: 0.9, child: buildAppTextField(hint: 'Weight (lbs)', controller: _weightController)),

            const SizedBox(height: 24),
            // Save button centered
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
                  child: Text('Save Pet', style: GoogleFonts.inknutAntiqua(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
