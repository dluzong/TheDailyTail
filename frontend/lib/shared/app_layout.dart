import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../screens/dailylog_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/community_screen.dart';
import '../screens/profile_screen.dart';
import '../user_provider.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool showBackButton;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
    this.showBackButton = false,
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
      case 4:
        destination = const ProfileScreen();
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

  void _openProfile() {
    if (currentIndex != 4) {
      widget.onTabSelected(4);
      _navigateToIndex(4);
      setState(() => currentIndex = 4);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add safe area padding
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    // Use base height values to adjust for all devices
    const double baseTotalHeight = 55;
    // const double baseOuterHeight = 50;
    const double baseInnerHeight = 70;
    const double floatingButtonSize = 85;

    final double adjustedTotalHeight = baseTotalHeight + bottomInset;
    final double adjustedInnerHeight = baseInnerHeight + (bottomInset / 2);

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  // Back button (only shown when showBackButton is true)
                  if (widget.showBackButton)
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  
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

                  // Profile icon and button
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: _openProfile,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            final photoUrl = userProvider.user?.photoUrl;
                            return CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF7496B3),
                              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            );
                          },
                        ),
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
                  // Align(
                  //   alignment: Alignment.bottomCenter,
                  //   child: Container(
                  //     height: baseOuterHeight,
                  //     color: outerBlue,
                  //   ),
                  // ),

                  Align(
                    alignment: Alignment.bottomCenter,                 
                      child: Container(
                        height: adjustedInnerHeight,
                        color: innerBlue,
                        child: BottomNavigationBar(
                          backgroundColor: innerBlue,
                          currentIndex: currentIndex == 4 ? 0 : currentIndex,
                          selectedItemColor: Colors.white,
                          unselectedItemColor: Colors.white,
                          onTap: (index) {
                            final actualIndex = index == 1 ? 1 : (index == 0 ? 0 : 2);
                            if (actualIndex == currentIndex) return;
                            widget.onTabSelected(actualIndex);
                            setState(() => currentIndex = actualIndex);
                            _navigateToIndex(actualIndex);
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

                  // Floating Home Button
                  Positioned(
                    bottom: baseInnerHeight - 50 + (bottomInset / 2),
                    child: Column(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
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