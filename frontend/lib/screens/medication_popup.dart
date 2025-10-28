import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicationPopup extends StatefulWidget {
  const MedicationPopup({super.key});

  @override
  State<MedicationPopup> createState() => _MedicationPopupState();
}

class _MedicationPopupState extends State<MedicationPopup> {
  final List<Map<String, dynamic>> _medications = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  String _selectedFrequency = 'Daily';
  late SharedPreferences _prefs;
  final String _prefsKey = 'medication_data';

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  Future<void> _loadMeds() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_prefsKey);
    if (raw != null) {
      final decoded = json.decode(raw) as List<dynamic>;
      setState(() {
        _medications.clear();
        _medications.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      });
    }
  }

  Future<void> _saveMeds() async {
    final encoded = json.encode(_medications);
    await _prefs.setString(_prefsKey, encoded);
  }

  void _addMedication() {
    if (_nameController.text.trim().isEmpty ||
        _dosageController.text.trim().isEmpty) return;

    setState(() {
      _medications.add({
        'name': _nameController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'freq': _selectedFrequency,
        'taken': false,
        'lastTaken':
            null, // For tracking and scheduling notifications in future
      });
      _nameController.clear();
      _dosageController.clear();
      _selectedFrequency = 'Daily';
    });
    _saveMeds();
  }

  void _toggleTaken(int index, bool value) {
    setState(() {
      _medications[index]['taken'] = value;
      if (value) {
        _medications[index]['lastTaken'] = DateTime.now().toIso8601String();
      }
    });
    _saveMeds();
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
    _saveMeds();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _medications.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'No medications yet — add one below.',
                      style: GoogleFonts.inknutAntiqua(fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final med = _medications[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          med['name'],
                          style: GoogleFonts.inknutAntiqua(fontSize: 13),
                        ),
                        subtitle: Text(
                          'Dosage: ${med['dosage']}  •  ${med['freq']}',
                          style: GoogleFonts.inknutAntiqua(fontSize: 11),
                        ),
                        leading: Switch(
                          activeColor: const Color(0xFF7496B3),
                          value: med['taken'] ?? false,
                          onChanged: (val) => _toggleTaken(index, val),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeMedication(index),
                        ),
                      );
                    },
                  ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _inputField(_nameController, 'Medication'),
                _inputField(_dosageController, 'Dosage'),
                _dropdownField(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7496B3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _addMedication,
                  child: Text(
                    'Add',
                    style: GoogleFonts.inknutAntiqua(
                        fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: GoogleFonts.inknutAntiqua(fontSize: 13),
        ),
      ),
    );
  }

  Widget _dropdownField() {
    return SizedBox(
      width: 150,
      height: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedFrequency,
            isExpanded: true,
            iconSize: 20,
            dropdownColor: Colors.white,
            style: GoogleFonts.inknutAntiqua(fontSize: 13, color: Colors.black),
            items: const [
              DropdownMenuItem(value: 'Daily', child: Text('Daily')),
              DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'Custom', child: Text('Custom')),
            ],
            onChanged: (val) {
              if (val == null) return;
              setState(() => _selectedFrequency = val);
            },
          ),
        ),
      ),
    );
  }
}
