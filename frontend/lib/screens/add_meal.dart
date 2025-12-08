import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddMeal extends StatefulWidget {
  final List<Map<String, String>> recentMeals;
  final Function(String name, String amount) onSave;
  final Function(String name, String amount)? onSaveToFavorites;

  const AddMeal({super.key, required this.recentMeals, required this.onSave, required this.onSaveToFavorites});

  @override
  State<AddMeal> createState() => _AddMealState();
}

class _AddMealState extends State<AddMeal> {
  String selectedName = "";
  String selectedAmount = "";
  int? highlightedIndex;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 26, color: Colors.black54),
                ),
                Text(
                  "Add a meal",
                  style: GoogleFonts.inknutAntiqua(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 26),
              ],
            ),

            const SizedBox(height: 10),
            Divider(color: Colors.black.withValues(alpha: 0.2)),
            const SizedBox(height: 10),

            Text(
              "Saved meals",
              style: GoogleFonts.inknutAntiqua(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.recentMeals.length,
                itemBuilder: (context, i) {
                  final meal = widget.recentMeals[i];
                  final isSelected = highlightedIndex == i;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        highlightedIndex = i;
                        selectedName = meal["name"]!;
                        selectedAmount = meal["amount"]!;
                        nameController.text = selectedName;
                        amountController.text = selectedAmount;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                          ? const Color(0xFF7AA9C8).withValues(alpha: 0.28)
                          : const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected ? const Color(0xFF7AA9C8) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal["name"]!,
                            style: GoogleFonts.inknutAntiqua(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            meal["amount"]!,
                            style: GoogleFonts.inknutAntiqua(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
            const Divider(color: Colors.black26, thickness: 1),
            const SizedBox(height: 10),

            Text(
              "New Meal",
              style: GoogleFonts.inknutAntiqua(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: nameController,
                    onChanged: (v) {
                      setState(() {
                        selectedName = v;
                        if (v.isNotEmpty) highlightedIndex = null;
                      });
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Food Name",
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: amountController,
                    onChanged: (v) {
                      selectedAmount = v;
                      if (v.isNotEmpty) {
                        setState(() => highlightedIndex = null);
                      }
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Amount (Optional)",
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Buttons (Updated to Row) ---
            Row(
              children: [
                // Button 1: Save to Favorites
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (selectedName.trim().isEmpty) return;
                      // Call the new callback
                      if (widget.onSaveToFavorites != null) {
                        widget.onSaveToFavorites!(selectedName, selectedAmount);
                      }
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF7AA9C8), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.favorite_border,
                        color: Color(0xFF7AA9C8)),
                    label: Text(
                      "Save List",
                      style: GoogleFonts.inknutAntiqua(
                        fontSize: 16,
                        color: const Color(0xFF7AA9C8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Button 2: Log Meal (Existing)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedName.trim().isEmpty) return;
                      widget.onSave(selectedName, selectedAmount);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7AA9C8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Log Meal",
                      style: GoogleFonts.inknutAntiqua(fontSize: 16),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
