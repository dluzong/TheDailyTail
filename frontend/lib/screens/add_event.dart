import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddEventPage extends StatefulWidget {
  final DateTime selectedDate;
  const AddEventPage({super.key, required this.selectedDate});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _desc = '';
  late DateTime _selectedDate;
  String _selectedCategory = 'Appointments';

  final Map<String, Color> tabColors = {
    'Appointments': const Color(0xFF34D399), // Green
    'Vaccinations': const Color(0xFF8B5CF6), // Purple
    'Events': const Color(0xFF60A5FA), // Blue
    'Other': const Color(0xFFFBBF24), // Yellow/Orange
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
        backgroundColor: const Color(0xFF7496B3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                onSaved: (val) => _title = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (val) => _desc = val ?? '',
              ),
              const SizedBox(height: 20),

              // --- Date Selector ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                    style: GoogleFonts.inknutAntiqua(fontSize: 12),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7496B3),
                    ),
                    onPressed: _pickDate,
                    child: const Text('Select Date',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Category Tabs ---
              Text('Category',
                  style: GoogleFonts.inknutAntiqua(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: tabColors.keys.map((category) {
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tabColors[category]
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: tabColors[category]!.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 10,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              // --- Save Button ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7496B3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pop(context, {
                      'title': _title,
                      'desc': _desc,
                      'category': _selectedCategory,
                      'date':
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    });
                  }
                },
                child: Text('Save Event',
                    style: GoogleFonts.inknutAntiqua(
                        fontSize: 12, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
