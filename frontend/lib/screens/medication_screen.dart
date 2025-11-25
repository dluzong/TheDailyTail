import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_layout.dart';

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

  // Placeholder list for medications per selected date
  final Map<String, List<Map<String, String>>> _medicationsByDate = {};

  @override
  void initState() {
    super.initState();
    todayIndex = totalDays ~/ 2;
    _scrollController = FixedExtentScrollController(initialItem: todayIndex);
  }

  DateTime dateFromIndex(int index) =>
      DateTime.now().add(Duration(days: index - todayIndex));

  List<Map<String, String>> get medsForSelected {
    final key = DateFormat('yyyy-MM-dd').format(selectedDate);
    return _medicationsByDate[key] ?? [];
  }

  void _addMedication() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final nameController = TextEditingController();
        final doseController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7AA9C8),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final key = DateFormat('yyyy-MM-dd').format(selectedDate);
                    setState(() {
                      _medicationsByDate.putIfAbsent(key, () => []).add({
                        'name': name,
                        'dose': doseController.text.trim(),
                        'time': DateTime.now().toIso8601String(),
                      });
                    });
                    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 0,
      onTabSelected: (index) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  // MONTH HEADER
                  Text(
                    DateFormat('MMMM yyyy').format(selectedDate),
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // DATE SCROLLER (same style as meal_plan_screen)
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
                          setState(() => selectedDate = dateFromIndex(i));
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            final date = dateFromIndex(index);
                            final selected = date.day == selectedDate.day &&
                                date.month == selectedDate.month &&
                                date.year == selectedDate.year;
                            return RotatedBox(
                              quarterTurns: 1,
                              child: GestureDetector(
                                onTap: () {
                                  _scrollController.animateToItem(
                                    index,
                                    curve: Curves.easeInOut,
                                    duration: const Duration(milliseconds: 250),
                                  );
                                  setState(() => selectedDate = date);
                                },
                                child: Container(
                                  width: 55,
                                  height: 70,
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
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // MEDICATION LIST
                  Expanded(
                    child: medsForSelected.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
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
                                  'Tap + to add one.',
                                  style: GoogleFonts.inknutAntiqua(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: medsForSelected.length,
                            itemBuilder: (context, i) {
                              final med = medsForSelected[i];
                              return Container(
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
                                      med['name'] ?? '',
                                      style: GoogleFonts.inknutAntiqua(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if ((med['dose'] ?? '').isNotEmpty)
                                      Text(
                                        med['dose']!,
                                        style: GoogleFonts.inknutAntiqua(fontSize: 14),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Logged at: ${DateFormat('h:mm a').format(DateTime.parse(med['time']!))}',
                                      style: GoogleFonts.inknutAntiqua(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _addMedication,
                backgroundColor: const Color(0xFF7AA9C8),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
