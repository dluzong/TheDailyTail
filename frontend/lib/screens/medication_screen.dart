import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dailylog_screen.dart';
import '../shared/app_layout.dart';
import '../medication_provider.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  DateTime selectedDate = DateTime.now();
  final int totalDays = 4000; // range for scrolling
  late int todayIndex;
  late FixedExtentScrollController _scrollController;

  // Data is sourced from MedicationsProvider

  @override
  void initState() {
    super.initState();
    todayIndex = totalDays ~/ 2;
    _scrollController = FixedExtentScrollController(initialItem: todayIndex);
  }

  DateTime dateFromIndex(int index) =>
      DateTime.now().add(Duration(days: index - todayIndex));

  // Persistence and filtering handled by MedicationsProvider

  // Inline add medication sheet (invoked by the button under Today's Medication)
  void _openAddMedicationSheet() {
    final medsProv = Provider.of<MedicationsProvider>(context, listen: false);
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
                    await medsProv.addMedication(
                          name: name,
                          dose: doseController.text.trim(),
                          frequency: freqController.text.trim(),
                        );
                    Navigator.pop(sheetContext);
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

  void _promptLogForToday(String medId, String name) {
    final friendlyDate = DateFormat('MMM d, yyyy').format(selectedDate);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log Medication'),
          content: Text(
            "Mark '${name.isEmpty ? 'Medication' : name}' as taken for $friendlyDate?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7AA9C8)),
              onPressed: () {
                context.read<MedicationsProvider>().logForDate(medId, selectedDate);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Logged '$name' for $friendlyDate")),
                );
              },
              child: const Text('Mark as taken', style: TextStyle(color: Colors.white)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7AA9C8)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _removeFromToday(String medId) {
    context.read<MedicationsProvider>().removeLogForDate(medId, selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 0,
      onTabSelected: (index) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with back arrow and month
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      child: const Icon(Icons.arrow_back, size: 24, color: Colors.black87),
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
                        final selected = DateUtils.isSameDay(date, selectedDate);
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
                                        color: selected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('E').format(date),
                                      style: GoogleFonts.inknutAntiqua(
                                        fontSize: 12,
                                        color: selected ? Colors.white : Colors.black87,
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

              // Sections
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Today's Medication
                    Text(
                      "Today's Medication",
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1.2, color: Colors.black12),
                    const SizedBox(height: 8),
                    Consumer<MedicationsProvider>(builder: (context, medsProv, _) {
                      final medsForToday = medsProv.forDate(selectedDate);
                      if (medsForToday.isEmpty) {
                        return Column(
                        children: [
                          Text(
                            'No medications for this day.',
                            style: GoogleFonts.inknutAntiqua(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Use the button below to add one.',
                            style: GoogleFonts.inknutAntiqua(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                        );
                      }
                      return Column(
                        children: medsForToday.asMap().entries.map((entry) {
                          final todayIdx = entry.key;
                          final med = entry.value;
                          return Dismissible(
                          key: Key('today_${med.id}_${todayIdx}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            return _confirmDialog(
                              title: 'Remove from Today',
                              message: "Remove this medication from today's list?",
                              confirmText: 'Yes',
                            );
                          },
                          onDismissed: (_) async {
                            _removeFromToday(med.id);
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF7FF),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: GoogleFonts.inknutAntiqua(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (med.dose.isNotEmpty)
                                  Text(
                                    'Dosage: ${med.dose}',
                                    style: GoogleFonts.inknutAntiqua(fontSize: 14),
                                  ),
                                if (med.frequency.isNotEmpty)
                                  Text(
                                    'Frequency: ${med.frequency}',
                                    style: GoogleFonts.inknutAntiqua(fontSize: 14),
                                  ),
                                if ((med.loggedAt ?? '').isNotEmpty)
                                  Text(
                                    "Last logged: ${DateFormat('MMM d, yyyy').format(DateTime.parse(med.loggedAt!))} • ${DateFormat('h:mm a').format(DateTime.parse(med.loggedAt!))}",
                                    style: GoogleFonts.inknutAntiqua(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 20),

                    // Your Medication
                    Text(
                      'Your Medication',
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1.2, color: Colors.black12),
                    const SizedBox(height: 8),
                    Consumer<MedicationsProvider>(builder: (context, medsProv, _) {
                      final all = medsProv.all;
                      if (all.isEmpty) {
                        return Text(
                        'No medications available yet.',
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      );
                      }
                      return Column(
                        children: all.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final med = entry.value;
                          return Dismissible(
                          key: Key('all_${med.id}_$idx'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            return _confirmDialog(
                              title: 'Delete Medication',
                              message: 'Delete this medication from your list?',
                              confirmText: 'Yes',
                            );
                          },
                          onDismissed: (_) async {
                            await context.read<MedicationsProvider>().deleteMedication(med.id);
                          },
                          child: GestureDetector(
                            onTap: () => _promptLogForToday(med.id, med.name),
                            child: Container(
                              width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF7FF),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: GoogleFonts.inknutAntiqua(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (med.dose.isNotEmpty)
                                  Text(
                                    'Dosage: ${med.dose}',
                                    style: GoogleFonts.inknutAntiqua(fontSize: 14),
                                  ),
                                if (med.frequency.isNotEmpty)
                                  Text(
                                    'Frequency: ${med.frequency}',
                                    style: GoogleFonts.inknutAntiqua(fontSize: 14),
                                  ),
                                   if ((med.loggedAt ?? '').isNotEmpty)
                                     Text(
                                       "Last logged: ${DateFormat('MMM d, yyyy').format(DateTime.parse(med.loggedAt!))} • ${DateFormat('h:mm a').format(DateTime.parse(med.loggedAt!))}",
                                       style: GoogleFonts.inknutAntiqua(
                                         fontSize: 12,
                                         color: Colors.black54,
                                       ),
                                     ),
                                  ],
                                ),
                              ),
                            )
                          );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 12),

                    // Add Medication button (moved under "Your Medication")
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
                          'Add Medication',
                          style: GoogleFonts.inknutAntiqua(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
