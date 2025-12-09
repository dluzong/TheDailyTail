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
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    const double baseTotalHeight = 70;
    const double baseInnerHeight = 65;
    const double floatingButtonSize = 80;

    final double adjustedTotalHeight = baseTotalHeight + bottomInset;
    final double adjustedInnerHeight = baseInnerHeight + (bottomInset / 2);

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(height: 50, color: outerBlue),

            // Top bar
            Container(
              height: 60,
              width: double.infinity,
              color: innerBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
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
                  Positioned(
                    right: 0,
                    child: Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        final photoUrl = userProvider.user?.photoUrl;
                        return GestureDetector(
                          onTap: _openProfile,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF7496B3),
                              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: widget.child,
              ),
            ),

            // Bottom navigation with floating button
            SizedBox(
              height: adjustedTotalHeight,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Bottom bar with U-shaped cutout
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, adjustedInnerHeight),
                      // Pass adjustedInnerHeight as the height to the painter
                      painter: _BottomNavPainter(innerBlue, floatingButtonSize, adjustedInnerHeight),
                      child: SizedBox(
                        height: adjustedInnerHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavIcon(icon: Icons.book, index: 0),
                            SizedBox(width: floatingButtonSize), // space for floating button
                            _buildNavIcon(icon: Icons.group, index: 2),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Floating Home Button
                  Positioned(
                    // Lower the position to sit properly in the deeper notch
                    bottom: (adjustedInnerHeight / 2) - 4, // Adjusted position
                    child: GestureDetector(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon({required IconData icon, required int index}) {
    final bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (currentIndex != index) {
          widget.onTabSelected(index);
          _navigateToIndex(index);
          setState(() => currentIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomNavPainter extends CustomPainter {
  final Color color;
  final double fabSize;
  final double barHeight; // New: Pass the actual bar height

  // Update constructor
  _BottomNavPainter(this.color, this.fabSize, this.barHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path();

    final double centerX = size.width / 2;
    // Notch radius is half the button size plus padding
    final double notchRadius = fabSize / 2 + 10; 
    // The depth of the curve down from the top edge
    final double notchDepth = 25; 

    path.moveTo(0, 0);
    // Line to the start of the curve
    path.lineTo(centerX - notchRadius - 15, 0); 

    // First part of the curve: down and into the notch
    path.quadraticBezierTo(
      centerX - notchRadius, 0, // Control point near the top-left of the notch
      centerX - notchRadius + 10, notchDepth, // End point for the down-curve
    );
    
    // Curved arc segment for the bottom of the notch
    path.arcToPoint(
      Offset(centerX + notchRadius - 10, notchDepth),
      radius: Radius.circular(notchRadius - 5),
      clockwise: false,
    );
    
    // Second part of the curve: out and back to the top edge
    path.quadraticBezierTo(
      centerX + notchRadius, 0, // Control point near the top-right of the notch
      centerX + notchRadius + 15, 0, // End point for the up-curve
    );

    path.lineTo(size.width, 0); // straight line after notch
    path.lineTo(size.width, barHeight); // Use barHeight for the bottom
    path.lineTo(0, barHeight);
    path.close();

    canvas.drawShadow(path, Colors.black26, 4, true); 
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}