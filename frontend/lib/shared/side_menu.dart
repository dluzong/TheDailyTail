import 'package:flutter/material.dart';

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

          // Food icon (index 0)
          _buildMenuItem(
            icon: Icons.restaurant_menu,
            isSelected: selectedIndex == 0,
          ),
          const SizedBox(height: 20),

          // Heart icon (index 1)
          _buildMenuItem(
            icon: Icons.favorite,
            isSelected: selectedIndex == 1,
          ),
          const SizedBox(height: 20),

          // Calendar icon (index 2)
          _buildMenuItem(
            icon: Icons.calendar_today,
            isSelected: selectedIndex == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required bool isSelected}) {
    return Container(
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
    );
  }
}
