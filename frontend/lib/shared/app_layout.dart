import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/dailylog_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/community_screen.dart';
import '../screens/profile_screen.dart';

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

  // ✅ Prevent duplicate ProfileScreen creation
  void _openProfile() {
    bool isAlreadyOnProfile = false;

    Navigator.popUntil(context, (route) {
      if (route.settings.name == 'profile') {
        isAlreadyOnProfile = true;
      }
      return true;
    });

    if (!isAlreadyOnProfile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: const RouteSettings(name: 'profile'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add safe area padding
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    // Use base height values to adjust for all devices
    const double baseTotalHeight = 120;
    const double baseOuterHeight = 50;
    const double baseInnerHeight = 70;
    const double floatingButtonSize = 85;

    final double adjustedTotalHeight = baseTotalHeight + bottomInset;
    final double adjustedInnerHeight = baseInnerHeight + (bottomInset / 2);

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(height: 50, color: outerBlue),

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

                  // ✅ Updated Profile Avatar Action
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: _openProfile,
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFF7496B3),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(child: widget.child),

            // Bottom navigation + floating button
            SizedBox(
              height: adjustedTotalHeight,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: baseOuterHeight,
                      color: outerBlue,
                    ),
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: baseOuterHeight),
                      child: Container(
                        height: adjustedInnerHeight,
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

                  // Floating Home Button
                  Positioned(
                    bottom: baseInnerHeight - 10 + (bottomInset / 2),
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
                            width: floatingButtonSize,
                            height: floatingButtonSize,
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
      ),
    );
  }
}
