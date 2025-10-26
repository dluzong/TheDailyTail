import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/dailylog_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/community_screen.dart';

class AppLayout extends StatefulWidget {
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
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;
  }

  void _navigateToIndex(int index) {
    Widget? destination;
    switch (index) {
      case 0:
        destination = const DailyLogScreen();
        break;
      case 1:
        destination = const DashboardScreen();
        break;
      case 2:
        destination = const CommunityBoardScreen();
        break;
    }

    if (destination != null) {
      // Replace current route so tabs don't stack
      Navigator.pushReplacement(
        context,
        // MaterialPageRoute(builder: (_) => destination!),
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination!,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

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
          Expanded(child: widget.child),
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
                  onTap: (index) {
                    if (index == currentIndex) return;
                    widget.onTabSelected(index);
                    setState(() {
                      currentIndex = index;
                    });
                    _navigateToIndex(index);
                  },
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
