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
    } else {
      // No saved medications, start with an empty list
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
      });
      _nameController.clear();
      _dosageController.clear();
      _selectedFrequency = 'Daily';
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
    final maxHeight = MediaQuery.of(context).size.height * 0.78;
    final maxListHeight =
        maxHeight * 0.5; // list won't exceed half the popup height

    return SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: maxHeight,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Medications',
                    style: GoogleFonts.inknutAntiqua(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                _medications.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'No medications yet — add one below.',
                          style: GoogleFonts.inknutAntiqua(fontSize: 12),
                        ),
                      )
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxListHeight,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _medications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final med = _medications[index];
                            return ListTile(
                              dense: true,
                              title: Text(med['name'],
                                  style:
                                      GoogleFonts.inknutAntiqua(fontSize: 13)),
                              subtitle: Text(
                                'Dosage: ${med['dosage']}  •  ${med['freq']}',
                                style: GoogleFonts.inknutAntiqua(fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeMedication(index),
                              ),
                            );
                          },
                        ),
                      ),

                const Divider(height: 1),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
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
                              fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // Close/save row
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close',
                          style: GoogleFonts.inknutAntiqua(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  // Dropdown that visually matches _inputField
  Widget _dropdownField() {
    return SizedBox(
      width: 150,
      height: 40, // 👈 Force same height as TextField visually
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center, // 👈 Centers the dropdown text
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
