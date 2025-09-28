import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(height: 50, color: const Color(0xFF7496B3)),
          Container(
            height: 60,
            width: double.infinity,
            color: const Color(0xFFBCD9EC),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    "The Daily Tail",
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF7496B3),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: const Color(0xFFBCD9EC),
                child: BottomNavigationBar(
                  backgroundColor: const Color(0xFFBCD9EC),
                  currentIndex: currentIndex,
                  selectedItemColor: Colors.black,
                  unselectedItemColor: Colors.grey,
                  onTap: onTabSelected,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: GoogleFonts.inknutAntiqua(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: GoogleFonts.inknutAntiqua(
                    fontSize: 12,
                  ),
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.note), label: "Logs"),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home), label: "Home"),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.group), label: "Community"),
                  ],
                ),
              ),
              Container(height: 50, color: const Color(0xFF7496B3)),
            ],
          ),
        ],
      ),
    );
  }
}
