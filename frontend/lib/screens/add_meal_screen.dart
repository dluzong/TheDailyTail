import 'package:flutter/material.dart';
import '../shared/app_layout.dart';

class AddMealScreen extends StatelessWidget {
  const AddMealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController caloriesCtrl = TextEditingController();
    final TextEditingController proteinCtrl = TextEditingController();
    final TextEditingController fatCtrl = TextEditingController();
    final TextEditingController carbsCtrl = TextEditingController();
    final TextEditingController timeCtrl = TextEditingController();

    return AppLayout(
      currentIndex: 0,
      onTabSelected: (index) {},
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Add Meal",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Food Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Nutrition",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: caloriesCtrl,
                    decoration: const InputDecoration(
                      labelText: "Calories (kcal)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: proteinCtrl,
                    decoration: const InputDecoration(
                      labelText: "Protein (g)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fatCtrl,
                    decoration: const InputDecoration(
                      labelText: "Fat (g)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: carbsCtrl,
                    decoration: const InputDecoration(
                      labelText: "Carbs (g)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: timeCtrl,
              decoration: const InputDecoration(
                labelText: "Time",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty &&
                    caloriesCtrl.text.isNotEmpty &&
                    proteinCtrl.text.isNotEmpty &&
                    fatCtrl.text.isNotEmpty &&
                    carbsCtrl.text.isNotEmpty &&
                    timeCtrl.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nameCtrl.text,
                    'calories': caloriesCtrl.text,
                    'protein': proteinCtrl.text,
                    'fat': fatCtrl.text,
                    'carbs': carbsCtrl.text,
                    'time': timeCtrl.text,
                    'active': false,
                  });
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }
}
