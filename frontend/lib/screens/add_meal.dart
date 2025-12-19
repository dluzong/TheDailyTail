import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddMeal extends StatefulWidget {
  final List<Map<String, String>> recentMeals;
  final Function(String name, String amount) onSave;
  final Function(String name, String amount)? onSaveToFavorites;
  final Future<void> Function(int index)? onDeleteRecent;

  const AddMeal({
    super.key,
    required this.recentMeals,
    required this.onSave,
    this.onSaveToFavorites,
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


  // THEME & COLOR CONSTANTS
  static const Color darkBg = Color(0xFF2A2A2A);
  static const Color darkInput = Color(0xFF3A3A3A);
  static const Color darkButton = Color(0xFF3A5A75);
  static const Color lightBg = Color(0xFFDCDCDC);
  static const Color accentColor = Color(0xFF7AA9C8);

  // HELPER METHODS

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  BoxDecoration _getInputDecoration() {
    return BoxDecoration(
      color: _isDark ? darkInput : lightBg,
      borderRadius: BorderRadius.circular(10),
    );
  }

  TextStyle? _getTextStyle() {
    return _isDark ? const TextStyle(color: Colors.white) : null;
  }

  TextStyle get _hintStyle => const TextStyle(color: Colors.grey);

  Widget _buildDivider() {
    return Divider(
      color: _isDark
          ? Colors.grey.shade700
          : Colors.black.withValues(alpha: 0.2),
      thickness: 1,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inknutAntiqua(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: _getInputDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        style: _getTextStyle(),
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: _hintStyle,
        ),
      ),
    );
  }

  Widget _buildMealItem(int index, Map<String, String> meal) {
    final isSelected = highlightedIndex == index;

    return Dismissible(
      key: Key('recent_meal_${index}_${meal["name"]}'),
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
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) async {
        if (widget.onDeleteRecent != null) {
          await widget.onDeleteRecent!(index);
          if (mounted) {
            setState(() {
              widget.recentMeals.removeAt(index);
              if (highlightedIndex == index) {
                highlightedIndex = null;
                selectedName = '';
                selectedAmount = '';
                nameController.clear();
                amountController.clear();
              } else if (highlightedIndex != null &&
                  highlightedIndex! > index) {
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
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            highlightedIndex = index;
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
                ? accentColor.withValues(alpha: 0.28)
                : (_isDark ? darkBg : lightBg),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : Colors.transparent,
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
                  color: _isDark ? Colors.white : null,
                ),
              ),
              Text(
                meal["amount"]!,
                style: GoogleFonts.inknutAntiqua(
                  fontSize: 14,
                  color: _isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, // pushes view above keyboard
      child: SingleChildScrollView(
        child: SizedBox(
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
                      child: Icon(
                        Icons.close,
                        size: 26,
                        color: _isDark ? Colors.white : Colors.black54,
                      ),
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
                _buildDivider(),
                const SizedBox(height: 10),

                _buildSectionTitle("Saved meals"),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: widget.recentMeals.length,
                    itemBuilder: (context, i) {
                      return _buildMealItem(i, widget.recentMeals[i]);
                    },
                  ),
                ),

                const SizedBox(height: 10),
                _buildDivider(),
                const SizedBox(height: 10),

                _buildSectionTitle("New Meal"),
                const SizedBox(height: 10),

                Column(
                  children: [
                    _buildTextField(
                      controller: nameController,
                      hintText: "Food Name",
                      onChanged: (v) {
                        setState(() {
                          selectedName = v;
                          if (v.isNotEmpty) highlightedIndex = null;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: amountController,
                      hintText: "Amount (Optional)",
                      onChanged: (v) {
                        selectedAmount = v;
                        if (v.isNotEmpty) {
                          setState(() => highlightedIndex = null);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (selectedName.trim().isEmpty) return;
                          if (widget.onSaveToFavorites != null) {
                            widget.onSaveToFavorites!(
                                selectedName, selectedAmount);
                          }
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: _isDark ? darkButton : accentColor,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.favorite_border,
                          color: _isDark ? darkButton : accentColor,
                        ),
                        label: Text(
                          "Save List",
                          style: GoogleFonts.inknutAntiqua(
                            fontSize: 16,
                            color: _isDark ? darkButton : accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedName.trim().isEmpty) return;
                          widget.onSave(selectedName, selectedAmount);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isDark ? darkButton : accentColor,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}