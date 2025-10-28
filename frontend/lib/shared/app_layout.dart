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

  final Color outerBlue = const Color(0xFF7496B3);
  final Color innerBlue = const Color(0xFF5F7C94);

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
      Navigator.pushReplacement(
        context,
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
          // Top light blue border
          Container(height: 50, color: outerBlue),

          // Inner top bar (darker blue)
          Container(
            height: 60,
            width: double.infinity,
            color: innerBlue,
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
                      color: Colors.white,
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

          // Main content
          Expanded(child: widget.child),

          // Bottom navigation + floating button
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // OUTER bottom light blue border
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 50,
                    color: outerBlue,
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Container(
                      height: 70,
                      color: innerBlue,
                      child: BottomNavigationBar(
                        backgroundColor: innerBlue,
                        currentIndex: currentIndex,
                        selectedItemColor: Colors.white,
                        unselectedItemColor: Colors.white,
                        onTap: (index) {
                          if (index == currentIndex) return;
                          widget.onTabSelected(index);
                          setState(() => currentIndex = index);
                          _navigateToIndex(index);
                        },
                        elevation: 0,
                        type: BottomNavigationBarType.fixed,
                        selectedLabelStyle: GoogleFonts.inknutAntiqua(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        unselectedLabelStyle: GoogleFonts.inknutAntiqua(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        items: const [
                          BottomNavigationBarItem(
                            icon: Icon(Icons.note, color: Colors.white),
                            label: "Logs",
                          ),
                          BottomNavigationBarItem(
                            icon: SizedBox.shrink(),
                            label: "",
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.group, color: Colors.white),
                            label: "Community",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating home button with label
                Positioned(
                  bottom: 70,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (currentIndex != 1) {
                            widget.onTabSelected(1);
                            _navigateToIndex(1);
                            setState(() => currentIndex = 1);
                          }
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            shape: BoxShape.circle,
                            border: Border.all(color: outerBlue, width: 4),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.home,
                            color: outerBlue,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Home",
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
