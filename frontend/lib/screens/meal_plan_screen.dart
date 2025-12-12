import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../log_provider.dart';
import '../pet_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_layout.dart';
import 'add_meal.dart';
import 'dailylog_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  DateTime selectedDate = DateTime.now();

  final int totalDays = 20000;
  late int todayIndex;
  late FixedExtentScrollController _scrollController;

  final List<Map<String, String>> recentMeals = [
    {"name": "Chicken", "amount": "5 grams"},
    {"name": "Salmon", "amount": "2 pounds"},
    {"name": "Dry Kibble", "amount": "1 cup"},
  ];

  @override
  void initState() {
    super.initState();
    todayIndex = totalDays ~/ 2;
    _scrollController = FixedExtentScrollController(initialItem: todayIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petId =
          Provider.of<PetProvider>(context, listen: false).selectedPetId;
      if (petId != null) {
        Provider.of<LogProvider>(context, listen: false).fetchLogs(petId);
      }
    });
  }

  DateTime dateFromIndex(int index) {
    return DateTime.now().add(Duration(days: index - todayIndex));
  }

  void _openMealPopup() {
    final petId = context.read<PetProvider>().selectedPetId;
    if (petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a pet first.')),
      );
      return;
    }
    // Get the actual Pet object to access savedMeals
    final currentPet =
        context.read<PetProvider>().pets.firstWhere((p) => p.petId == petId);

    // Convert savedMeals (List<Map>) to List<Map<String, String>> for the UI
    final recentMeals = currentPet.savedMeals
        .map((m) => {
              "name": m['name'].toString(),
              "amount": (m['amount'] ?? '').toString()
            })
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // ...
      builder: (context) {
        return AddMeal(
          recentMeals: recentMeals,
          // 1. Standard "Log Meal" button
          onSave: (name, amount) {
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
            Provider.of<LogProvider>(context, listen: false).addLog(
              petId: petId,
              type: 'meal',
              date: logDate,
              details: {'name': name, 'amount': amount},
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Logged $name")),
            );
          },
          // 2. New "Save List" button
          onSaveToFavorites: (name, amount) async {
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
            // Log it for the day
            Provider.of<LogProvider>(context, listen: false).addLog(
              petId: petId,
              type: 'meal',
              date: logDate,
              details: {'name': name, 'amount': amount},
            );

            // AND save it to the DB list
            await Provider.of<PetProvider>(context, listen: false)
                .addSavedMeal(petId, {'name': name, 'amount': amount});

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$name saved to favorites and logged!")),
            );
          },
          onDeleteRecent: (index) async {
            await context.read<PetProvider>().removeSavedMeal(petId, index);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 0,
      onTabSelected: (_) {},
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 6),

                  /// MONTH + YEAR + BACK BUTTON
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  const DailyLogScreen(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 12.0),
                          child: Icon(Icons.arrow_back,
                              size: 26, 
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat('MMMM yyyy').format(selectedDate),
                          style: GoogleFonts.inknutAntiqua(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// DATE SCROLLER
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
                                        ? (Theme.of(context).brightness == Brightness.dark
                                            ? const Color(0xFF4A6B85)
                                            : const Color(0xFF7AA9C8))
                                        : (Theme.of(context).brightness == Brightness.dark
                                            ? const Color(0xFF2A2A2A)
                                            : const Color(0xFFEDF7FF)),
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
                                              : (Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white70
                                                  : Colors.black87),
                                        ),
                                      ),
                                      Text(
                                        DateFormat('E').format(date),
                                        style: GoogleFonts.inknutAntiqua(
                                          fontSize: 12,
                                          color: selected
                                              ? Colors.white
                                              : (Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white70
                                                  : Colors.black87),
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

                  /// MEAL LIST
                  Expanded(
                    child: Consumer<LogProvider>(
                      builder: (context, logProvider, child) {
                        final petId =
                            context.watch<PetProvider>().selectedPetId;
                        if (petId == null)
                          return const Center(
                              child: Text('Select a pet first'));

                        final meals =
                            logProvider.getMealsForDate(petId, selectedDate);

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: meals.length + 1,
                          itemBuilder: (context, i) {
                            if (i == meals.length) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 30),
                                child: Center(
                                  child: meals.isEmpty
                                      ? Column(
                                          children: [
                                            Text(
                                              'No meals logged yet!',
                                              style: GoogleFonts.inknutAntiqua(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Tap the + button to add one.',
                                              style: GoogleFonts.inknutAntiqua(
                                                fontSize: 14,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Total meals: ${meals.length}',
                                          style: GoogleFonts.inknutAntiqua(
                                            fontSize: 14,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        ),
                                ),
                              );
                            }

                            final log = meals[i];

                            //swipe to delete
                            return Dismissible(
                              key: ValueKey(log.logId),
                              direction: DismissDirection.endToStart,

                              // Confirm deletion
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: const Color(0xFF7496B3),
                                      title: Text(
                                        'Delete meal?',
                                        style: GoogleFonts.inknutAntiqua(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      content: Text(
                                        "Remove '${log.details['name'] ?? 'meal'}' from this day?",
                                        style: GoogleFonts.inknutAntiqua(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                                color: Colors.black87),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },

                              onDismissed: (direction) async {
                                await logProvider.deleteLog(log.logId, petId);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Deleted ${log.details['name'] ?? 'meal'}')),
                                );
                              },

                              // Swipe background
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.delete,
                                    color: Colors.white, size: 28),
                              ),

                              child: SizedBox(
                                width: double.infinity,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF4A6B85)
                                        : const Color(0xFFD9E8F5),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.12),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.details['name']?.toString() ??
                                            'Meal',
                                        style: GoogleFonts.inknutAntiqua(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if ((log.details['amount'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text(
                                          log.details['amount']?.toString() ??
                                              '',
                                          style: GoogleFonts.inknutAntiqua(
                                              fontSize: 14),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Logged at: ${DateFormat('h:mm a').format(log.loggedAt ?? log.date)}',
                                        style: GoogleFonts.inknutAntiqua(
                                          fontSize: 12,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white70
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            /// ADD BUTTON
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: FloatingActionButton(
                onPressed: _openMealPopup,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF4A6B85)
                    : const Color(0xFF7AA9C8),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
