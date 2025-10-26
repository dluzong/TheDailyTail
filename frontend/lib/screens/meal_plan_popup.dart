import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealPlanPopup extends StatefulWidget {
  const MealPlanPopup({super.key});

  @override
  State<MealPlanPopup> createState() => _MealPlanPopupState();
}

class _MealPlanPopupState extends State<MealPlanPopup> {
  final List<Map<String, dynamic>> _meals = [];
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  late SharedPreferences _prefs;
  final String _prefsKey = 'meal_plan_data';

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_prefsKey);
    if (raw != null) {
      final decoded = json.decode(raw) as List<dynamic>;
      setState(() {
        _meals.clear();
        _meals.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      });
    } else {
      // No saved meals, start with an empty list
    }
  }

  Future<void> _saveMeals() async {
    final encoded = json.encode(_meals);
    await _prefs.setString(_prefsKey, encoded);
  }

  void _addMeal() {
    if (_foodController.text.trim().isEmpty ||
        _timeController.text.trim().isEmpty) return;

    setState(() {
      _meals.add({
        'food': _foodController.text.trim(),
        'time': _timeController.text.trim(),
        'eaten': false,
      });
      _foodController.clear();
      _timeController.clear();
    });
    _saveMeals();
  }

  void _toggleEaten(int index, bool val) {
    setState(() {
      _meals[index]['eaten'] = val;
    });
    _saveMeals();
  }

  void _removeMeal(int index) {
    setState(() {
      _meals.removeAt(index);
    });
    _saveMeals();
  }

  @override
  void dispose() {
    _foodController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _meals.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'No meals yet — add one below.',
                      style: GoogleFonts.inknutAntiqua(fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _meals.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final meal = _meals[index];
                      return ListTile(
                        dense: true,
                        title: Text(meal['food'],
                            style: GoogleFonts.inknutAntiqua(fontSize: 13)),
                        subtitle: Text('Time: ${meal['time']}',
                            style: GoogleFonts.inknutAntiqua(fontSize: 11)),
                        leading: Switch(
                          activeColor: const Color(0xFF7496B3),
                          value: meal['eaten'] ?? false,
                          onChanged: (val) => _toggleEaten(index, val),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeMeal(index),
                        ),
                      );
                    },
                  ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _inputField(_foodController, 'Food item'),
                _inputField(_timeController, 'Time (e.g. 8:00 AM)'),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7496B3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _addMeal,
                  child: Text(
                    'Add',
                    style: GoogleFonts.inknutAntiqua(
                        fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
