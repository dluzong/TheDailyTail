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

  // Base colors that will be adjusted based on theme
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

  // Get colors based on current theme
  Map<String, Color> getTabColors(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return colorSchemes.map((key, value) =>
        MapEntry(key, isDarkMode ? value['dark']! : value['light']!));
  }

  // HELPER METHODS - UTILITIES

  /// Convert UI category to database type
  String _getCategoryDbType(String uiCategory) {
    String dbType = uiCategory.toLowerCase();
    if (dbType.endsWith('s')) {
      dbType = dbType.substring(0, dbType.length - 1);
    }
    return dbType;
  }

  /// Get theme-adjusted background colors for UI elements
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
      'backgroundColor': isDarkMode ? darkColor : pastelColor,
      'baseColor': baseColor,
      'isDark': isDarkMode,
    };
  }

  /// Build input field decoration with theme-aware styling
  InputDecoration _buildTextFieldDecoration({
    required String labelText,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.lato(
        color: isDark
            ? const Color(0xFF7FA8C7)
            : const Color(0xFF7496B3),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? const Color(0xFF4A4A4A)
              : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Color(0xFF7496B3), width: 1.5),
      ),
    );
  }

  /// Build theme-aware ColorScheme for date picker
  ColorScheme _buildDatePickerColorScheme(bool isDark) {
    return isDark
        ? const ColorScheme.dark(
            primary: Color(0xFF7496B3),
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          )
        : const ColorScheme.light(
            primary: Color(0xFF7496B3),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF394957),
          );
  }

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

    final newEvent = await showDialog(
      context: context,
      builder: (context) =>
          AddEventPage(selectedDate: _selectedDay ?? DateTime.now()),
    );

    if (newEvent != null) {
      String dbType = _getCategoryDbType(newEvent['category'].toString());

      await context.read<LogProvider>().addLog(
        petId: petId,
        type: dbType,
        date: DateTime.parse(newEvent['date']),
        details: {'title': newEvent['title'], 'desc': newEvent['desc']},
      );
    }
  }

  // --- Show event dialog with edit and delete ---
  void _showEventDialog(Map<String, String> event, String category) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Event Details',
            style: GoogleFonts.inknutAntiqua(
              color: isDark ? const Color(0xFF7FA8C7) : const Color(0xFF7496B3),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title: ${event['title']}',
                style: GoogleFonts.lato(
                  color: isDark ? Colors.white : const Color(0xFF394957),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Description: ${event['desc']}',
                style: GoogleFonts.lato(
                  color: isDark ? Colors.white : const Color(0xFF394957),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${event['date']}',
                style: GoogleFonts.lato(
                  color: isDark ? Colors.white : const Color(0xFF394957),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close details dialog
                _showEditEventDialog(event, category); // open edit dialog
              },
              child: Text(
                'Edit',
                style: GoogleFonts.lato(
                  color: const Color(0xFF7496B3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final petId = context.read<PetProvider>().selectedPetId;
                final logId = event['id']; 

                if (petId != null && logId != null) {
                  await context.read<LogProvider>().deleteLog(logId, petId);
                }

                if (mounted) Navigator.pop(context);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.lato(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.lato(
                  color: const Color(0xFF7496B3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- EDIT EVENT ---
  void _showEditEventDialog(Map<String, String> event, String category) {
    final titleController = TextEditingController(text: event['title']);
    final descController = TextEditingController(text: event['desc']);
    DateTime eventDate = DateTime.parse(event['date']!);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Edit Event',
                style: GoogleFonts.inknutAntiqua(
                  color: isDark
                      ? const Color(0xFF7FA8C7)
                      : const Color(0xFF7496B3),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: GoogleFonts.lato(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: _buildTextFieldDecoration(
                        labelText: 'Title',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: GoogleFonts.lato(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: _buildTextFieldDecoration(
                        labelText: 'Description',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Date: ',
                          style: GoogleFonts.lato(
                            color:
                                isDark ? Colors.white : const Color(0xFF394957),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: eventDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: _buildDatePickerColorScheme(isDark),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setDialogState(() {
                                eventDate = picked;
                              });
                            }
                          },
                          child: Text(
                            '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
                            style: GoogleFonts.lato(
                              color: const Color(0xFF7496B3),
                              fontWeight: FontWeight.w600,
                            ),
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
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.lato(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final petId =
                        this.context.read<PetProvider>().selectedPetId;
                    final logId = event['id'];

                    if (petId != null && logId != null) {
                      // Delete old event
                      await this
                          .context
                          .read<LogProvider>()
                          .deleteLog(logId, petId);

                      // Add new event with updated details
                      String dbType = _getCategoryDbType(category);

                      await this.context.read<LogProvider>().addLog(
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
                  child: Text(
                    'Save',
                    style: GoogleFonts.lato(
                      color: const Color(0xFF7496B3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petId = context.read<PetProvider>().selectedPetId;
      if (petId != null) {
        context.read<LogProvider>().fetchLogs(petId);
      }
    });
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
        color: Theme.of(context).scaffoldBackgroundColor,
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
                            final displayName = p.name.length > 12
                                ? '${p.name.substring(0, 12)}...'
                                : p.name;
                            return DropdownMenuItem(
                              value: p.petId,
                              child: Text(
                                displayName,
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
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    const MealPlanScreen(),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
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
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    const MedicationScreen(),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
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
                      final elementColors = _getElementColors(tab, context);
                      final isDarkMode = elementColors['isDark'] as bool;
                      final lightModeColor =
                          colorSchemes[tab]?['light'] ?? Colors.grey;
                      final selectedBgColor = elementColors['backgroundColor'] as Color;
                      final unselectedBgColor = isDarkMode
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey[200]!;

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
                            color: isSelected
                                ? selectedBgColor
                                : unselectedBgColor,
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
                                  color:
                                      lightModeColor, // always use light mode bright colors
                                  size: 10),
                              const SizedBox(width: 6),
                              Text(tab,
                                  style: GoogleFonts.inknutAntiqua(
                                    fontSize: 10,
                                    color: isDarkMode
                                        ? Colors.white
                                        : (isSelected
                                            ? Colors.black
                                            : Colors.grey[600]),
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
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4A6B85)
                            : const Color(0xFF7496B3),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A5A75)
                            : const Color(0xFFBCD9EC),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF5F8FA8)
                              : const Color(0xFF7496B3),
                          width: 2,
                        ),
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
                            // Use light mode colors for calendar dots (same as tab dots)
                            final dotColor =
                                colorSchemes[category]?['light'] ?? Colors.grey;
                            return Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5, vertical: 2),
                              decoration: BoxDecoration(
                                  color: dotColor, shape: BoxShape.circle),
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
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF4A6B85)
                                  : const Color(0xFF7496B3),
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
                  final elementColors = _getElementColors(category, context);
                  final cardColor = elementColors['backgroundColor'] as Color;
                  final dotColor = elementColors['baseColor'] as Color;
                  final isDarkMode = elementColors['isDark'] as bool;

                  return GestureDetector(
                    onTap: () => _showEventDialog(event, category),
                    child: Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      child: ListTile(
                        leading: Icon(Icons.circle, color: dotColor, size: 12),
                        title: Text(event['title'] ?? '',
                            style: GoogleFonts.inknutAntiqua(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black)),
                        subtitle: Text(event['desc'] ?? '',
                            style: GoogleFonts.inknutAntiqua(
                                fontSize: 12,
                                color: isDarkMode
                                    ? const Color(0xFFB0B0B0)
                                    : const Color(0xFF666666))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 55,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4A6B85) : const Color(0xFFBCD9EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                size: 28,
                color: const Color(0xFF7496B3)),
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
