import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_layout.dart';
import 'add_event.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Set<String> _selectedTabs = {};

//Dummy event data
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
    List<Map<String, String>> visibleEvents = [];

    final activeTabs = _selectedTabs.isEmpty ? _events.keys : _selectedTabs;

    for (var tab in activeTabs) {
      for (var event in _events[tab]!) {
        if (event['date'] == dateKey) {
          visibleEvents.add({...event, 'category': tab});
        }
      }
    }

    return visibleEvents;
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final dateKey =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    List<Map<String, String>> visibleEvents = [];

    final activeTabs = _selectedTabs.isEmpty ? _events.keys : _selectedTabs;

    for (var tab in activeTabs) {
      final list = _events[tab]!;
      visibleEvents.addAll(list
          .where((e) => e['date'] == dateKey)
          .map((e) => {...e, 'category': tab}));
    }
    return visibleEvents;
  }

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
        child: Column(
          children: [
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                    child: _topButton(
                        icon: Icons.restaurant_menu,
                        label: 'Meal Plan',
                        onTap: () {})),
                const SizedBox(width: 8),
                Expanded(
                    child: _topButton(
                        icon: Icons.medication,
                        label: 'Medication',
                        onTap: () {})),
              ],
            ),

            const SizedBox(height: 16),

            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Events', 'Appointments', 'Medication', 'Other']
                    .map((tab) {
                  final isSelected = _selectedTabs.contains(tab);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTabs.remove(tab);
                          } else {
                            _selectedTabs.add(tab);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (tabColors[tab] ?? Colors.grey)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
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
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            //calendar
            Flexible(
              flex: 3,
              child: TableCalendar(
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
                  markerDecoration: const BoxDecoration(shape: BoxShape.circle),
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
                        final Color color = tabColors[category] ?? Colors.grey;
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
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7496B3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _navigateToAddEvent,
              child: const Text('Add Event',
                  style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: _getEventsForDay(_selectedDay ?? DateTime.now())
                    .map((event) {
                  final category = event['category']!;
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(Icons.circle,
                          color: tabColors[category], size: 12),
                      title: Text(event['title']!,
                          style: GoogleFonts.inknutAntiqua(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text(event['desc']!,
                          style: GoogleFonts.inknutAntiqua(fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
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
}
