import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared/app_layout.dart';
import 'add_event.dart';
import 'meal_plan_popup.dart';
import 'medication_popup.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<String> _selectedTabs = {};

  // ---- Dummy Data ----
  final Map<String, List<Map<String, String>>> _events = {
    'Appointments': [
      {
        'date': '2025-10-02',
        'title': 'Vet Checkup',
        'desc': 'Dental check at Whisker Wellness'
      },
      {
        'date': '2025-10-12',
        'title': 'Follow-up Visit',
        'desc': 'Check recovery progress'
      },
    ],
    'Medication': [
      {
        'date': '2025-10-10',
        'title': 'Heartworm Pill',
        'desc': 'Monthly preventive dose'
      },
      {
        'date': '2025-10-12',
        'title': 'Flea Treatment',
        'desc': 'Apply topical treatment'
      },
    ],
    'Events': [
      {
        'date': '2025-10-04',
        'title': 'Play date with Bella',
        'desc': 'At the dog park, 3 PM'
      },
      {
        'date': '2025-10-12',
        'title': 'Agility Training',
        'desc': 'At Paw Park, 9 AM'
      },
    ],
    'Other': [
      {
        'date': '2025-10-08',
        'title': 'Grooming Day',
        'desc': 'Nail trim & bath'
      },
      {
        'date': '2025-10-12',
        'title': 'Pet Photoshoot',
        'desc': 'Holiday-themed session'
      },
    ],
  };

  final Map<String, Color> tabColors = {
    'Appointments': const Color(0xFF34D399),
    'Medication': const Color(0xFF8B5CF6),
    'Events': const Color(0xFF60A5FA),
    'Other': const Color(0xFFFBBF24),
  };

  List<Map<String, String>> _getVisibleMarkersForDay(DateTime day) {
    final dateKey =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final activeTabs = _selectedTabs.isEmpty ? _events.keys : _selectedTabs;
    return [
      for (var tab in activeTabs)
        for (var event in _events[tab]!)
          if (event['date'] == dateKey) {...event, 'category': tab}
    ];
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) =>
      _getVisibleMarkersForDay(day);

  void _navigateToAddEvent() async {
    final newEvent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEventPage(selectedDate: _selectedDay ?? DateTime.now()),
      ),
    );

    if (newEvent != null) {
      setState(() {
        _events[newEvent['category']]!.add({
          'date': newEvent['date'],
          'title': newEvent['title'],
          'desc': newEvent['desc'],
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 1,
      onTabSelected: (index) {},
      child: Container(
        color: const Color(0xFFEFF6FB),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ---- Top Buttons ----
                  Row(
                    children: [
                      Expanded(
                        child: _topButton(
                          icon: Icons.restaurant_menu,
                          label: 'Meal Plan',
                          onTap: () => _showDialog(
                            'Meal Plan',
                            const Icon(Icons.restaurant_menu,
                                size: 50, color: Color(0xFF7496B3)),
                            const MealPlanPopup(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _topButton(
                          icon: Icons.medication,
                          label: 'Medication',
                          onTap: () => _showDialog(
                            'Medication',
                            const Icon(Icons.medication,
                                size: 50, color: Color(0xFF7496B3)),
                            const MedicationPopup(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ---- Category Tabs ----
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['Events', 'Appointments', 'Medication', 'Other']
                        .map((tab) {
                      final isSelected = _selectedTabs.contains(tab);
                      return GestureDetector(
                        onTap: () {
                          setState(() => isSelected
                              ? _selectedTabs.remove(tab)
                              : _selectedTabs.add(tab));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? tabColors[tab] : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,
                                  color: isSelected
                                      ? Colors.white
                                      : (tabColors[tab] ?? Colors.grey),
                                  size: 10),
                              const SizedBox(width: 6),
                              Text(tab,
                                  style: GoogleFonts.inknutAntiqua(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // ---- Calendar ----
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 4,
                      markerDecoration:
                          const BoxDecoration(shape: BoxShape.circle),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF7496B3),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFFBCD9EC),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF7496B3)),
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.inknutAntiqua(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    eventLoader: (day) => _getVisibleMarkersForDay(day),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return const SizedBox();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.take(4).map((event) {
                            final String category =
                                (event is Map && event['category'] != null)
                                    ? event['category'] as String
                                    : '';
                            final Color color =
                                tabColors[category] ?? Colors.grey;
                            return Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5, vertical: 2),
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---- Add Event Button ----
                  Center(
                    child: SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7496B3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _navigateToAddEvent,
                        child: const Text('Add Event',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ---- Event List ----
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final eventList =
                      _getEventsForDay(_selectedDay ?? DateTime.now());
                  final event = eventList[index];
                  final category = event['category']!;
                  final baseColor = tabColors[category] ?? Colors.grey;
                  final pastelColor = Color.alphaBlend(
                    baseColor.withOpacity(0.2),
                    Colors.white,
                  );
                  return Card(
                    color: pastelColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: ListTile(
                      leading: Icon(Icons.circle, color: baseColor, size: 12),
                      title: Text(event['title']!,
                          style: GoogleFonts.inknutAntiqua(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text(event['desc']!,
                          style: GoogleFonts.inknutAntiqua(fontSize: 12)),
                    ),
                  );
                },
                childCount:
                    _getEventsForDay(_selectedDay ?? DateTime.now()).length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _topButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 55,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFBCD9EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF7496B3)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inknutAntiqua(
                  fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showDialog(String title, Widget front, Widget back) {
    showDialog(
      context: context,
      builder: (context) => FlipCardDialog(
        title: title,
        frontContent: front,
        backContent: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: back,
        ),
      ),
    );
  }
}

// ---- Widget popup animation ----
class FlipCardDialog extends StatefulWidget {
  final String title;
  final Widget frontContent;
  final Widget backContent;

  const FlipCardDialog({
    super.key,
    required this.title,
    required this.frontContent,
    required this.backContent,
  });

  @override
  State<FlipCardDialog> createState() => _FlipCardDialogState();
}

class _FlipCardDialogState extends State<FlipCardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double dialogHeight = MediaQuery.of(context).size.height * 0.7;
    final double dialogWidth = MediaQuery.of(context).size.width * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 3.1416;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          final showingBack = _controller.value > 0.5;
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: showingBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.1416),
                      child: _buildBack(context),
                    )
                  : _buildFront(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.title,
                style: GoogleFonts.inknutAntiqua(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            widget.frontContent,
          ],
        ),
      );

  Widget _buildBack(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(child: widget.backContent),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7496B3)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
}
