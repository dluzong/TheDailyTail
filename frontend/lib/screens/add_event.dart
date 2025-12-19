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

  final Map<String, Map<String, Color>> colorSchemes = {
    'Appointments': {
      'light': const Color(0xFF34D399),
      'dark': const Color(0xFF059669),
    },
    'Vaccinations': {
      'light': const Color(0xFF8B5CF6),
      'dark': const Color(0xFF6D28D9),
    },
    'Events': {
      'light': const Color(0xFF60A5FA),
      'dark': const Color(0xFF2563EB),
    },
    'Other': {
      'light': const Color(0xFFFBBF24),
      'dark': const Color(0xFFD97706),
    },
  };

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get theme-appropriate colors for all categories
  Map<String, Color> getTabColors(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return colorSchemes.map((key, value) =>
        MapEntry(key, isDarkMode ? value['dark']! : value['light']!));
  }

  /// Get theme-adjusted colors for UI elements
  Map<String, dynamic> _getElementColors(String category, BuildContext context) {
    final tabColors = getTabColors(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = tabColors[category] ?? Colors.grey;

    final pastelColor = Color.alphaBlend(
      baseColor.withValues(alpha: 0.2),
      Colors.white,
    );
    final darkColor = Color.alphaBlend(
      baseColor.withValues(alpha: 0.15),
      const Color(0xFF1A1A1A),
    );

    return {
      'selectedBg': isDarkMode ? darkColor : pastelColor,
      'unselectedBg': isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
      'lightModeColor': colorSchemes[category]?['light'] ?? Colors.grey,
      'isDark': isDarkMode,
    };
  }

  /// Build theme-aware ColorScheme for date picker
  ColorScheme _buildDatePickerColorScheme() {
    return const ColorScheme.light(
      primary: Color(0xFF7496B3),
      onPrimary: Colors.white,
      onSurface: Colors.black87,
      surface: Colors.white,
    );
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: _buildDatePickerColorScheme(),
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
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header with Title and Back Arrow ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Event',
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

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
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                        ),
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
                    final elementColors = _getElementColors(category, context);
                    final isDarkMode = elementColors['isDark'] as bool;
                    final selectedBgColor = elementColors['selectedBg'] as Color;
                    final unselectedBgColor = elementColors['unselectedBg'] as Color;
                    final lightModeColor = elementColors['lightModeColor'] as Color;
                    
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? selectedBgColor : unselectedBgColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                color: lightModeColor,
                                size: 10),
                            const SizedBox(width: 6),
                            Text(
                              category,
                              style: GoogleFonts.inknutAntiqua(
                                fontSize: 10,
                                color: isDarkMode ? Colors.white : (isSelected ? Colors.black : Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),

                // --- Save Event Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4A6B85)
                          : const Color(0xFF7496B3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
