import 'package:flutter/material.dart';
import '../shared/app_layout.dart';
import '../shared/side_menu.dart';
import 'add_meal_screen.dart';

class DailyLogMealScreen extends StatefulWidget {
  const DailyLogMealScreen({super.key});

  @override
  State<DailyLogMealScreen> createState() => _DailyLogMealScreenState();
}

class _DailyLogMealScreenState extends State<DailyLogMealScreen> {
  final List<Map<String, dynamic>> meals = [];

  int get totalCalories =>
      meals.fold(0, (sum, m) => sum + int.parse(m['calories']));
  int get totalProtein =>
      meals.fold(0, (sum, m) => sum + int.parse(m['protein']));
  int get totalFat => meals.fold(0, (sum, m) => sum + int.parse(m['fat']));
  int get totalCarbs => meals.fold(0, (sum, m) => sum + int.parse(m['carbs']));

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 0,
      onTabSelected: (index) {},
      child: Row(
        children: [
          const SideMenu(selectedIndex: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Feeding Schedule",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final newMeal = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddMealScreen()),
                          );
                          if (newMeal != null) {
                            setState(() => meals.add(newMeal));
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  if (meals.isEmpty) const Text("No meals added yet."),
                  if (meals.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(meal['name']),
                            subtitle: Text(meal['time']),
                            trailing: Switch(
                              value: meal['active'],
                              onChanged: (val) {
                                setState(() => meal['active'] = val);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    "Nutritional Summary",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NutritionStat(
                          value: "$totalCalories kcal",
                          label: "Total Calories"),
                      _NutritionStat(
                          value: "$totalProtein g", label: "Protein"),
                      _NutritionStat(value: "$totalFat g", label: "Fat"),
                      _NutritionStat(value: "$totalCarbs g", label: "Carbs"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionStat extends StatelessWidget {
  final String value;
  final String label;

  const _NutritionStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
