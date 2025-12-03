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

  DateTime dateFromIndex(int index) =>
      DateTime.now().add(Duration(days: index - todayIndex));

  // 1. Add New Medication Definition (Prescription) to Pet Profile
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
      backgroundColor: Colors.white,
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
                  const Text(
                    'Add Medication',
                    style: TextStyle(
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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: doseController,
                decoration: const InputDecoration(
                  labelText: 'Dose / Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: freqController,
                decoration: const InputDecoration(
                  labelText: 'Frequency (e.g. 2x/day)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7AA9C8),
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

  // 2. Log a Medication as "Taken" for Today
  void _promptLogForToday(Map<String, dynamic> medData) {
    final petId = context.read<PetProvider>().selectedPetId;
    if (petId == null) return;

    final name = medData['name'] ?? 'Medication';
    final friendlyDate = DateFormat('MMM d, yyyy').format(selectedDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log Medication'),
          content: Text(
            "Mark '$name' as taken for $friendlyDate?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7AA9C8)),
              onPressed: () {
                // Create Log Entry
                context.read<LogProvider>().addLog(
                  petId: petId,
                  type: 'medication',
                  date: selectedDate,
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

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    String cancelText = 'Cancel',
    String confirmText = 'Delete',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelText)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7AA9C8)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // 3. Remove a Log Entry
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
        backgroundColor: Colors.white,
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
                      child: const Icon(Icons.arrow_back,
                          size: 24, color: Colors.black87),
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

              // Calendar scroller
              SizedBox(
                height: 94,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    physics: const FixedExtentScrollPhysics(),
                    itemExtent: 72,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedDate = dateFromIndex(index);
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: totalDays,
                      builder: (context, index) {
                        final date = dateFromIndex(index);
                        final selected =
                            DateUtils.isSameDay(date, selectedDate);
                        return RotatedBox(
                          quarterTurns: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _scrollController.animateToItem(
                                  index,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                                setState(() {
                                  selectedDate = date;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF7AA9C8)
                                      : const Color(0xFFEDF7FF),
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
                                            : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('E').format(date),
                                      style: GoogleFonts.inknutAntiqua(
                                        fontSize: 12,
                                        color: selected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                          style: GoogleFonts.inknutAntiqua(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: todayLogs.map((log) {
                          return Dismissible(
                            key: Key(log.logId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              color: Colors.redAccent,
                              padding: const EdgeInsets.only(right: 16),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return _confirmDialog(
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
                                color: const Color(0xFFEDF7FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Color(0xFF7AA9C8)),
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
                                          "Taken at ${DateFormat('h:mm a').format(log.date)}",
                                          style: GoogleFonts.inknutAntiqua(
                                              fontSize: 12),
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
                          // In the future, you can implement 'delete saved med' here
                          return GestureDetector(
                            onTap: () => _promptLogForToday(med),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: const Color(0xFFBCD9EC)),
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
                                            style: GoogleFonts.inknutAntiqua(
                                                fontSize: 12),
                                          ),
                                        if (med['frequency'] != null)
                                          Text(
                                            'Freq: ${med['frequency']}',
                                            style: GoogleFonts.inknutAntiqua(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.add_circle_outline,
                                      color: Color(0xFF7AA9C8)),
                                ],
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
                          backgroundColor: const Color(0xFF7AA9C8),
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
