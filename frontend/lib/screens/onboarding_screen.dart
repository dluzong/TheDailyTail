import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/screens/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: 30,
            color: const Color(0xFF7496B3),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFBFD4E6),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                "The Daily Tail",
                style: GoogleFonts.inknutAntiqua(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7496B3),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, user!",
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5F7C94),
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "The Daily Tail is an all-in-one pet health tracker app that allows you to add logs for your pet’s daily food, medications, vaccinations, and track behavior. You can also connect with fellow pet owners and dog sitters. To begin, select between the following:",
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 16,
                      height: 1.5,
                      color: const Color(0xFF5F7C94),
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 30),

                  // Roles
                  _buildRoleButton("Pet Owner"),
                  const SizedBox(height: 12),
                  _buildRoleButton("Pet Sitter"),
                  const SizedBox(height: 12),
                  _buildRoleButton("Adoption Organizer"),
                  const SizedBox(height: 12),
                  _buildRoleButton("Foster"),
                ],
              ),
            ),
          ),
          Container(
            height: 30,
            color: const Color(0xFF7496B3),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String role) {
    final bool isSelected = selectedRole == role;
    return Center(
      child: SizedBox(
        width: 220,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? const Color(0xFF8DB6D9) : const Color(0xFF8DB6D9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            setState(() {
              selectedRole = role;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              ),
            );
          },
          child: Text(
            role,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
