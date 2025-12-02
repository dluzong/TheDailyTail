import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../meals_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_layout.dart';
import 'add_meal.dart';
import 'dailylog_screen.dart';

class MealPlanScreen extends StatefulWidget {
  final String petId;
  const MealPlanScreen({super.key, required this.petId});

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

    // Fetch data immediately when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMealsForSelectedDate();
    });
  }

  // Helper function to handle loading and debugging
  void _loadMealsForSelectedDate() {
    debugPrint("Fetching meals for Pet ID: ${widget.petId}");
    debugPrint("Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}");

    Provider.of<MealsProvider>(context, listen: false)
        .loadDate(selectedDate, widget.petId);
  }


  DateTime dateFromIndex(int index) {
    return DateTime.now().add(Duration(days: index - todayIndex));
  }

  void _openMealPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return AddMeal(
          recentMeals: recentMeals,
          onSave: (name, amount) {
            Provider.of<MealsProvider>(context, listen: false)
                .addMeal(selectedDate, name, amount, widget.petId);
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
        backgroundColor: Colors.white,
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
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8.0, right: 12.0),
                          child: Icon(Icons.arrow_back,
                              size: 26, color: Colors.black87),
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
                          Provider.of<MealsProvider>(context, listen: false)
                              .loadDate(date, widget.petId);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            final date = dateFromIndex(index);
                            final selected =
                                date.day == selectedDate.day &&
                                date.month == selectedDate.month &&
                                date.year == selectedDate.year;

                            return RotatedBox(
                              quarterTurns: 1,
                              child: GestureDetector(
                                onTap: () {
                                  _scrollController.animateToItem(
                                    index,
                                    curve: Curves.easeInOut,
                                    duration:
                                        const Duration(milliseconds: 250),
                                  );
                                  setState(() => selectedDate = date);
                                  Provider.of<MealsProvider>(context,
                                          listen: false)
                                      .loadDate(date, widget.petId);
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

                  /// MEAL LIST (Wrapped in RefreshIndicator)
                  Expanded(
                    child: Consumer<MealsProvider>(
                      builder: (context, provider, child) {
                        final meals =
                        provider.getMealsForDate(selectedDate);

                        return RefreshIndicator(
                          onRefresh: () async {
                            await provider.loadDate(selectedDate, widget.petId);
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            // Always allow scroll so Pull-to-Refresh works even when empty
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: meals.length + 1,
                            itemBuilder: (context, i) {
                              if (i == meals.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8, bottom: 30),
                                  child: Center(
                                    child: meals.isEmpty
                                        ? Column(
                                      children: [
                                        Text(
                                          "No meals found for this date.",
                                          style:
                                          GoogleFonts.inknutAntiqua(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Pull down to refresh",
                                          style:
                                          GoogleFonts.inknutAntiqua(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    )
                                        : Text(
                                      "Total meals: ${meals.length}",
                                      style:
                                      GoogleFonts.inknutAntiqua(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final meal = meals[i];

                              //swipe to delete
                              return Dismissible(
                                key: ValueKey("${meal.name}_${meal.time}"),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor: const Color(0xFFEDF7FF),
                                        title: Text(
                                          "Delete meal?",
                                          style: GoogleFonts.inknutAntiqua(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        content: Text(
                                          "Remove '${meal.name}' from this day?",
                                          style: GoogleFonts.inknutAntiqua(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text("Cancel", style: TextStyle(color: Colors.black87)),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (direction) {
                                  Provider.of<MealsProvider>(context,
                                      listen: false)
                                      .removeMealAt(selectedDate, i);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Deleted ${meal.name}")),
                                  );
                                },
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
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meal.name,
                                          style: GoogleFonts.inknutAntiqua(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (meal.amount.isNotEmpty)
                                          Text(
                                            meal.amount,
                                            style: GoogleFonts.inknutAntiqua(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        Text(
                                          DateFormat('h:mm a').format(meal.time),
                                          style: GoogleFonts.inknutAntiqua(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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
