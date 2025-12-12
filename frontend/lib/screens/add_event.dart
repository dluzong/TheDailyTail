import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddEventPage extends StatefulWidget {
  final DateTime? selectedDate;
  const AddEventPage({super.key, this.selectedDate});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _desc = '';
  DateTime? _selectedDate;
  String _selectedCategory = 'Appointments';

  final Map<String, Color> tabColors = {
    'Appointments': const Color(0xFF34D399),
    'Vaccinations': const Color(0xFF8B5CF6),
    'Events': const Color(0xFF60A5FA),
    'Other': const Color(0xFFFBBF24),
  };

  final Map<String, Map<String, Color>> colorSchemes = {
    'Appointments': {
      'light': const Color(0xFF34D399), // teal
      'dark': const Color(0xFF059669), // muted teal for dark mode
    },
    'Vaccinations': {
      'light': const Color(0xFF8B5CF6), // purple
      'dark': const Color(0xFF6D28D9), // muted purple for dark mode
    },
    'Events': {
      'light': const Color(0xFF60A5FA), // blue
      'dark': const Color(0xFF2563EB), // muted blue for dark mode
    },
    'Other': {
      'light': const Color(0xFFFBBF24), // yellow/gold
      'dark': const Color(0xFFD97706), // muted yellow for dark mode
    },
  };

  Map<String, Color> getTabColors(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return colorSchemes.map((key, value) =>
        MapEntry(key, isDarkMode ? value['dark']! : value['light']!));
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        // theme to select date in form
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7496B3),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
              surface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7496B3),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date first.')),
        );
        return;
      }

      _formKey.currentState!.save();
      Navigator.pop(context, {
        'title': _title,
        'desc': _desc,
        'category': _selectedCategory,
        'date':
            '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
      });
    }
  }

  InputDecoration _inputDecoration(String label, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.black87,
        fontSize: 12,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          Colors.black.withValues(alpha: 0.4), // semi-transparent overlay
      appBar: AppBar(
        title: const Text('Add Event'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF4A6B85)
            : const Color(0xFF7496B3),
      ),
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  // --- Title ---
                  TextFormField(
                    style: Theme.of(context).brightness == Brightness.dark 
                      ? const TextStyle(color: Colors.white) 
                      : null,
                    decoration: _inputDecoration('Title', context),
                    onSaved: (val) => _title = val ?? '',
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 12),

                  // --- Description ---
                  TextFormField(
                    style: Theme.of(context).brightness == Brightness.dark 
                      ? const TextStyle(color: Colors.white) 
                      : null,
                    decoration: _inputDecoration('Description', context),
                    onSaved: (val) => _desc = val ?? '',
                  ),
                  const SizedBox(height: 20),

                  // --- Date Selector ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'No date selected'
                              : 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                          style: GoogleFonts.inknutAntiqua(fontSize: 12),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF4A6B85)
                              : const Color(0xFF7496B3),
                        ),
                        onPressed: _pickDate,
                        child: const Text(
                          'Select Date',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Category Tabs ---
                  Text(
                    'Category',
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: getTabColors(context).keys.map((category) {
                      final isSelected = _selectedCategory == category;
                      final tabColors = getTabColors(context);
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tabColors[category]
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF2A2A2A)
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: tabColors[category]!
                                      .withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.inknutAntiqua(
                              fontSize: 10,
                              color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  // --- Save Event Button ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4A6B85)
                          : const Color(0xFF7496B3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _onSave,
                    child: Text(
                      'Save Event',
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
