import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dailylog_screen.dart';
import '../shared/app_layout.dart';
import '../pet_provider.dart';
import '../log_provider.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  // Color Constants
  static const Color darkBg = Color(0xFF2A2A2A);
  static const Color darkInput = Color(0xFF3A3A3A);
  static const Color darkBorder = Color(0xFF505050);
  static const Color darkCard = Color(0xFF3A5A75);
  static const Color darkCardAlt = Color(0xFF4A6B85);
  static const Color darkBorder2 = Color(0xFF8AB4D5);
  static const Color accentColor = Color(0xFF7AA9C8);
  static const Color lightCard = Color(0xFFD9E8F5);
  static const Color lightBgAlt = Color(0xFFEDF7FF);

  DateTime selectedDate = DateTime.now();
  final int totalDays = 4000;
  late int todayIndex;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    todayIndex = totalDays ~/ 2;
    _scrollController = FixedExtentScrollController(initialItem: todayIndex);
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // Helper to build input field with consistent styling
  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _isDark ? darkInput : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isDark ? darkBorder : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: controller,
        style: _isDark ? const TextStyle(color: Colors.white) : null,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: _isDark ? Colors.white70 : Colors.grey,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  // Helper to build AlertDialog with theme-aware styling
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    String cancelText = 'Cancel',
    String confirmText = 'Yes',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: TextStyle(
              color: _isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: _isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                cancelText,
                style: TextStyle(
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDark ? darkCard : accentColor,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  DateTime dateFromIndex(int index) =>
      DateTime.now().add(Duration(days: index - todayIndex));

  /// Builds a theme-aware calendar date item widget
  /// Returns a container with day and day-of-week, responding to tap gestures
  Widget _buildDateItem({
    required DateTime date,
    required bool selected,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 55,
        height: 70,
        decoration: BoxDecoration(
          color: selected
              ? (_isDark ? darkCardAlt : accentColor)
              : (_isDark ? darkBg : lightBgAlt),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('d').format(date),
              style: GoogleFonts.inknutAntiqua(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.white
                    : (_isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            Text(
              DateFormat('E').format(date),
              style: GoogleFonts.inknutAntiqua(
                fontSize: 12,
                color: selected
                    ? Colors.white
                    : (_isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddMedicationSheet() {
    final petId = context.read<PetProvider>().selectedPetId;

    if (petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a pet in the Dashboard first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        final nameController = TextEditingController();
        final doseController = TextEditingController();
        final freqController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Medication',
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 12),
              _buildInputField(controller: nameController, labelText: 'Medication Name'),
              const SizedBox(height: 12),
              _buildInputField(controller: doseController, labelText: 'Dose / Notes'),
              const SizedBox(height: 12),
              _buildInputField(controller: freqController, labelText: 'Frequency (e.g. 2x/day)'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDark ? darkCardAlt : accentColor,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    // Save to Pet Profile (Definition)
                    await context
                        .read<PetProvider>()
                        .addSavedMedication(petId, {
                      'name': name,
                      'dose': doseController.text.trim(),
                      'frequency': freqController.text.trim(),
                    });

                    if (mounted) Navigator.pop(sheetContext);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _promptLogForToday(Map<String, dynamic> medData) {
    final petId = context.read<PetProvider>().selectedPetId;
    if (petId == null) return;

    final name = medData['name'] ?? 'Medication';
    final friendlyDate = DateFormat('MMM d, yyyy').format(selectedDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Log Medication',
            style: TextStyle(
              color: _isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            "Mark '$name' as taken for $friendlyDate?",
            style: TextStyle(
              color: _isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDark ? darkCardAlt : accentColor,
              ),
              onPressed: () {
                final now = DateTime.now();
                final logDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  now.hour,
                  now.minute,
                  now.second,
                  now.millisecond,
                  now.microsecond,
                );
                // Create Log Entry
                context.read<LogProvider>().addLog(
                  petId: petId,
                  type: 'medication',
                  date: logDate,
                  details: {
                    'name': name,
                    'dose': medData['dose'] ?? '',
                    'frequency': medData['frequency'] ?? ''
                  },
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Logged '$name' for $friendlyDate")),
                );
              },
              child: const Text('Mark as taken',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _removeLog(String logId) {
    final petId = context.read<PetProvider>().selectedPetId;
    if (petId != null) {
      context.read<LogProvider>().deleteLog(logId, petId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch Data
    final petProvider = context.watch<PetProvider>();
    final logProvider = context.watch<LogProvider>();

    final selectedPetId = petProvider.selectedPetId;

    // 1. Get Saved Definitions (From Pet)
    List<Map<String, dynamic>> savedMeds = [];
    if (selectedPetId != null && petProvider.pets.isNotEmpty) {
      try {
        final pet =
            petProvider.pets.firstWhere((p) => p.petId == selectedPetId);
        savedMeds = pet.savedMedications;
      } catch (_) {}
    }

    // 2. Get Logs (History)
    final allLogs = selectedPetId != null
        ? logProvider.getMedications(selectedPetId)
        : <PetLog>[];
    final todayLogs = allLogs
        .where((l) => DateUtils.isSameDay(l.date, selectedDate))
        .toList();

    return AppLayout(
      currentIndex: 0,
      onTabSelected: (index) {},
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const DailyLogScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                      child: Icon(Icons.arrow_back,
                          size: 24, 
                          color: _isDark ? Colors.white : Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM yyyy').format(selectedDate),
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              /// Horizontal date scroller - wheel picker for selecting dates
              SizedBox(
                height: 85,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 60,
                    diameterRatio: 2.2,
                    magnification: 1.1,
                    useMagnifier: true,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) {
                      final date = dateFromIndex(i);
                      setState(() => selectedDate = date);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: totalDays,
                      builder: (context, index) {
                        final date = dateFromIndex(index);
                        final selected = date.day == selectedDate.day &&
                            date.month == selectedDate.month &&
                            date.year == selectedDate.year;

                        return RotatedBox(
                          quarterTurns: 1,
                          child: _buildDateItem(
                            date: date,
                            selected: selected,
                            onTap: () {
                              _scrollController.animateToItem(
                                index,
                                curve: Curves.easeInOut,
                                duration: const Duration(milliseconds: 250),
                              );
                              setState(() => selectedDate = date);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Main Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // SECTION 1: LOGS FOR SELECTED DAY
                    Text(
                      "History for ${DateFormat('MMM d').format(selectedDate)}",
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1.2, color: Colors.black12),
                    const SizedBox(height: 8),

                    if (todayLogs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No medications taken on this day.',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black54,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: todayLogs.map((log) {
                          return Dismissible(
                            key: Key(log.logId),
                            direction: DismissDirection.endToStart,
                            resizeDuration: null,
                            background: Container(
                              alignment: Alignment.centerRight,
                              color: Colors.redAccent,
                              padding: const EdgeInsets.only(right: 16),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return _showConfirmDialog(
                                title: 'Remove Log',
                                message: "Remove this entry from history?",
                                confirmText: 'Yes',
                              );
                            },
                            onDismissed: (_) => _removeLog(log.logId),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _isDark ? darkCardAlt : lightCard,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: _isDark ? Colors.white : accentColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.details['name'] ?? 'Unknown',
                                          style: GoogleFonts.inknutAntiqua(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Taken at ${DateFormat('h:mm a').format(log.loggedAt ?? log.date)}",
                                          style: GoogleFonts.inknutAntiqua(
                                              fontSize: 12,
                                              color: _isDark ? Colors.white70 : Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 24),

                    // SECTION 2: YOUR PRESCRIBED MEDICATIONS
                    Text(
                      'Your Medications',
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1.2, color: Colors.black12),
                    const SizedBox(height: 8),

                    if (savedMeds.isEmpty)
                      const Text("No saved medications. Add one below!")
                    else
                      Column(
                        children: savedMeds.asMap().entries.map((entry) {
                          final med = entry.value;
                          final idx = entry.key;
                          return Dismissible(
                            key: Key("saved_med_${idx}_${med['name'] ?? ''}"),
                            direction: DismissDirection.endToStart,
                            resizeDuration: null,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return _showConfirmDialog(
                                title: 'Delete medication?',
                                message: "Remove '${med['name'] ?? 'medication'}' from your list?",
                                confirmText: 'Delete',
                              );
                            },
                            onDismissed: (_) async {
                              final petId = context.read<PetProvider>().selectedPetId;
                              if (petId != null) {
                                await context
                                    .read<PetProvider>()
                                    .removeSavedMedication(petId, idx);
                              }
                            },
                            child: GestureDetector(
                              onTap: () => _promptLogForToday(med),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _isDark ? darkCard : lightCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: _isDark ? darkBorder2 : const Color(0xFF7496B3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med['name'] ?? 'Medication',
                                            style: GoogleFonts.inknutAntiqua(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (med['dose'] != null)
                                            Text(
                                              'Dose: ${med['dose']}',
                                              style: GoogleFonts.lato(
                                                  fontSize: 12),
                                            ),
                                          if (med['frequency'] != null)
                                            Text(
                                              'Freq: ${med['frequency']}',
                                              style: GoogleFonts.lato(
                                                  fontSize: 12,
                                                  color: _isDark ? Colors.white70 : Colors.grey),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.add_circle_outline,
                                        color: _isDark ? Colors.white : accentColor),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 12),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDark ? darkCardAlt : accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _openAddMedicationSheet,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text(
                          'Add New Medication',
                          style: GoogleFonts.inknutAntiqua(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
