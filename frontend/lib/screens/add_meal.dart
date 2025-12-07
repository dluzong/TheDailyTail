import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddMeal extends StatefulWidget {
  final List<Map<String, String>> recentMeals;
  final Function(String name, String amount) onSave;
  final Future<void> Function(int index)? onDeleteRecent;

  const AddMeal({
    super.key,
    required this.recentMeals,
    required this.onSave,
    this.onDeleteRecent,
  });

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
              "Recent meals",
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

                  return Dismissible(
                    key: Key('recent_meal_${i}_${meal["name"]}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      if (widget.onDeleteRecent == null) return false;
                      return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              title: const Text('Delete meal?'),
                              content: Text(
                                "Remove '${meal["name"]}' from recent meals?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (_) async {
                      if (widget.onDeleteRecent != null) {
                        await widget.onDeleteRecent!(i);
                        if (mounted) {
                          setState(() {
                            widget.recentMeals.removeAt(i);
                            if (highlightedIndex == i) {
                              highlightedIndex = null;
                              selectedName = '';
                              selectedAmount = '';
                              nameController.clear();
                              amountController.clear();
                            } else if (highlightedIndex != null && highlightedIndex! > i) {
                              highlightedIndex = highlightedIndex! - 1;
                            }
                          });
                        }
                      }
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: GestureDetector(
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
                        width: double.infinity,
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

            SizedBox(
              width: double.infinity,
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
                  "Save",
                  style: GoogleFonts.inknutAntiqua(fontSize: 18),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
