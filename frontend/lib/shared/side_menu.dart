import 'package:flutter/material.dart';
import '../screens/dailylog_meal.dart';
import '../screens/dailylog_health.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex; // which menu item is active
  const SideMenu({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: const Color(0xFFEFEFEF),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFF7496B3),
            child: Icon(Icons.person, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 30),

          // 🍴 Food icon (index 0)
          _buildMenuItem(
            context: context,
            icon: Icons.restaurant_menu,
            index: 0,
            isSelected: selectedIndex == 0,
          ),
          const SizedBox(height: 20),

          // ❤️ Heart icon (index 1)
          _buildMenuItem(
            context: context,
            icon: Icons.favorite,
            index: 1,
            isSelected: selectedIndex == 1,
          ),

          const SizedBox(height: 20),

          // 📅 Calendar icon (optional future section)
          _buildMenuItem(
            context: context,
            icon: Icons.calendar_today,
            index: 2,
            isSelected: selectedIndex == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (index == selectedIndex) return;

        // Navigate based on icon pressed
        Widget? destination;
        if (index == 0) {
          destination = const DailyLogMealScreen();
        } else if (index == 1) {
          destination = const DailyLogHealthScreen();
        } else {
          // Future: calendar or other page
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination!),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7496B3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? Colors.white : Colors.black54,
        ),
      ),
    );
  }
}
