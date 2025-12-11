import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/app_layout.dart';
import 'add_event.dart';
import 'meal_plan_screen.dart';
import 'medication_screen.dart';
import '../pet_provider.dart';
import '../log_provider.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<String> _selectedTabs = {};

  final Map<String, Color> tabColors = {
    'Appointments': const Color(0xFF34D399),
    'Vaccinations': const Color(0xFF8B5CF6),
    'Events': const Color(0xFF60A5FA),
    'Other': const Color(0xFFFBBF24),
  };

  // --- GET EVENTS FROM DB ---
  Map<String, List<Map<String, String>>> get _events {
    final petId = context.watch<PetProvider>().selectedPetId;
    if (petId == null) return {};
    // This returns the events organized by category ('Appointments', 'Other', etc.)
    return context.watch<LogProvider>().getEventsForCalendar(petId);
  }

  List<Map<String, String>> _getVisibleMarkersForDay(DateTime day) {
    final dateKey =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    // If no tabs selected, show all. Otherwise show selected.
    final activeTabs = _selectedTabs.isEmpty ? _events.keys : _selectedTabs;

    List<Map<String, String>> markers = [];

    for (var tab in activeTabs) {
      final eventsInTab = _events[tab];
      if (eventsInTab != null) {
        for (var event in eventsInTab) {
          if (event['date'] == dateKey) {
            markers.add({...event, 'category': tab});
          }
        }
      }
    }
    return markers;
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) =>
      _getVisibleMarkersForDay(day);

  // --- ADD EVENT ---
  void _navigateToAddEvent() async {
    final petId = context.read<PetProvider>().selectedPetId;
    if (petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet first.')),
      );
      return;
    }

    final newEvent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEventPage(selectedDate: _selectedDay ?? DateTime.now()),
      ),
    );

    if (newEvent != null) {
      // Convert UI category (e.g. 'Events') to DB type (e.g. 'event')
      // Simple logic: lowercase and remove trailing 's' if present
      String uiCategory = newEvent['category'].toString();
      String dbType = uiCategory.toLowerCase();
      if (dbType.endsWith('s')) {
        dbType = dbType.substring(0, dbType.length - 1);
      }

      await context.read<LogProvider>().addLog(
        petId: petId,
        type: dbType,
        date: DateTime.parse(newEvent['date']),
        details: {'title': newEvent['title'], 'desc': newEvent['desc']},
      );
    }
  }

  // --- SHOW DETAILS / DELETE ---
  void _showEventDialog(Map<String, String> event, String category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Event Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: ${event['title']}'),
              const SizedBox(height: 8),
              Text('Description: ${event['desc']}'),
              const SizedBox(height: 8),
              Text('Date: ${event['date']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close details dialog
                _showEditEventDialog(event, category); // open edit dialog
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () async {
                final petId = context.read<PetProvider>().selectedPetId;
                final logId = event['id']; // This comes from LogProvider now

                if (petId != null && logId != null) {
                  await context.read<LogProvider>().deleteLog(logId, petId);
                }

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // --- EDIT EVENT ---
  // Since we don't have an 'updateLog' yet, we will Delete Old + Add New
  void _showEditEventDialog(Map<String, String> event, String category) {
    final titleController = TextEditingController(text: event['title']);
    final descController = TextEditingController(text: event['desc']);
    DateTime eventDate = DateTime.parse(event['date']!);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Date: '),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: eventDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          // Update local state for the dialog only
                          // (In a real app, use a StatefulBuilder for dialog content)
                          eventDate = picked;
                        }
                      },
                      child: Text(
                        '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final petId = context.read<PetProvider>().selectedPetId;
                final logId = event['id'];

                if (petId != null && logId != null) {
                  // 1. Delete old
                  await context.read<LogProvider>().deleteLog(logId, petId);

                  // 2. Add new
                  // Map UI Category back to DB type
                  String dbType = category.toLowerCase();
                  if (dbType.endsWith('s')) {
                    dbType = dbType.substring(0, dbType.length - 1);
                  }

                  await context.read<LogProvider>().addLog(
                    petId: petId,
                    type: dbType,
                    date: eventDate,
                    details: {
                      'title': titleController.text,
                      'desc': descController.text
                    },
                  );
                }

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets;
    final selectedPetId = petProvider.selectedPetId;

    return AppLayout(
      currentIndex: 0,
      onTabSelected: (index) {},
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ---- Pet Dropdown ----
                  Row(
                    children: [
                      const Text('Pet: ', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      // Only show dropdown if we have pets
                      if (pets.isEmpty)
                        const Text("No pets")
                      else
                        DropdownButton<String>(
                          value: selectedPetId,
                          items: pets.map((p) {
                            return DropdownMenuItem(
                              value: p.petId,
                              child: Text(
                                p.name,
                                style: GoogleFonts.lato(
                                    fontSize: 20, fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId == null) return;
                            // Update both providers
                            context.read<PetProvider>().selectPet(newId);
                            context.read<LogProvider>().fetchLogs(newId);
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ---- Top Buttons ----
                  Row(
                    children: [
                      Expanded(
                        child: _topButton(
                          icon: Icons.restaurant_menu,
                          label: 'Meal Plan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MealPlanScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _topButton(
                          icon: Icons.medication,
                          label: 'Medication',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MedicationScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ---- Category Tabs ----
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'Events',
                      'Appointments',
                      'Vaccinations',
                      'Other'
                    ].map((tab) {
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
                            color: isSelected ? tabColors[tab] : Colors.grey[200],
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
                                        : Colors.grey[600],
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

            // ---- Event List with Edit/Delete ----
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final eventList =
                      _getEventsForDay(_selectedDay ?? DateTime.now());
                  final event = eventList[index];
                  final category = event['category']!;
                  final baseColor = tabColors[category] ?? Colors.grey;
                  final pastelColor = Color.alphaBlend(
                    baseColor.withValues(alpha: 0.2),
                    Colors.white,
                  );

                  return GestureDetector(
                    onTap: () => _showEventDialog(event, category),
                    child: Card(
                      color: pastelColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      child: ListTile(
                        leading: Icon(Icons.circle, color: baseColor, size: 12),
                        title: Text(event['title'] ?? '',
                            style: GoogleFonts.inknutAntiqua(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(event['desc'] ?? '',
                            style: GoogleFonts.inknutAntiqua(fontSize: 12)),
                      ),
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
}
