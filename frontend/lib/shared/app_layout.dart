import 'package:flutter/material.dart';
import 'package:frontend/screens/user_settings.dart';
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
  final bool isProfilePage;
  final bool isOwnProfilePage;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
    this.showBackButton = false,
    this.isProfilePage = false,
    this.isOwnProfilePage = false,
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
    // Precache logo images to prevent loading delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/dailytail-logotype-white.png'),
        context,
      );
      precacheImage(
        const AssetImage('assets/dailytail-logotype-blue.png'),
        context,
      );
    });
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
      case 5:
        destination = const UserSettingsScreen();
        break;
    }

    if (destination != null) {
      if (index == 4 && widget.isProfilePage && widget.isOwnProfilePage) {
        // Already on own profile; no-op to avoid duplicate rebuilds
        return;
      }
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
    // If already on own profile, avoid pushing another instance
    if (currentIndex == 4 && widget.isProfilePage && widget.isOwnProfilePage) {
      return;
    }

    widget.onTabSelected(4);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ProfileScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    setState(() => currentIndex = 4);
  }

  // Removed unused _openSettings to satisfy analyzer

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    const double baseTotalHeight = 70;
    const double baseInnerHeight = 65;
    const double floatingButtonSize = 80;

    final double adjustedTotalHeight = baseTotalHeight + bottomInset;
    final double adjustedInnerHeight = baseInnerHeight + (bottomInset / 2);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 50,
              // color: Theme.of(context).brightness == Brightness.dark
              //     ? const Color(0xFF3A5A75)
              //     : outerBlue,
            ),

            // Top bar
            // Container(
            //   height: 100,
            //   width: double.infinity,
            //   color: Theme.of(context).brightness == Brightness.dark
            //       ? const Color(0xFF4A6B85)
            //       : innerBlue,
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                if (widget.showBackButton)
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        size: 28,
                      ),
                      onPressed: () async {
                        final didPop = await Navigator.of(context).maybePop();
                        if (!didPop) {
                          // If nothing to pop, go to Dashboard
                          widget.onTabSelected(1);
                          _navigateToIndex(1);
                        }
                      },
                    ),
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15), // Add top padding
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter, // Crop from bottom
                        heightFactor:
                            0.8, // Show only top 70% of image (adjust 0.5-1.0)
                        child: Image.asset(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'assets/dailytail-logotype-white.png'
                              : 'assets/dailytail-logotype-blue.png',
                          height: 80,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                          cacheHeight: 160,
                        ),
                      ),
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
                        child: Padding(
                          padding: const EdgeInsets.all(
                              15.0), // Add padding around avatar
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[700]!,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF7496B3),
                              backgroundImage:
                                  (photoUrl != null && photoUrl.isNotEmpty)
                                      ? NetworkImage(photoUrl)
                                      : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // ),

            Expanded(
              child: Container(
                color: Colors.white,
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
                  // Bottom bar painter
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width,
                          adjustedInnerHeight),
                      painter: _BottomNavPainter(
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A5A75)
                            : innerBlue,
                        floatingButtonSize,
                        adjustedInnerHeight,
                      ),
                      child: SizedBox(
                        height: adjustedInnerHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavIcon(icon: Icons.book, index: 0),
                            const SizedBox(width: floatingButtonSize),
                            _buildNavIcon(icon: Icons.group, index: 2),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Floating Home Button
                  Positioned(
                    bottom: (adjustedInnerHeight / 2) - 4,
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
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF3A5A75)
                                    : outerBlue,
                            width: 4,
                          ),
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3A5A75)
                              : outerBlue,
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
          Icon(
            icon,
            color: Theme.of(context).scaffoldBackgroundColor,
            size: 28,
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
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
  final double barHeight;

  _BottomNavPainter(this.color, this.fabSize, this.barHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path();

    const double topOffset = 6.0;

    final double centerX = size.width / 2;
    final double notchRadius = fabSize / 2 + 10;
    final double notchDepth = 18;

    path.moveTo(0, topOffset);
    path.lineTo(centerX - notchRadius - 15, topOffset);

    path.quadraticBezierTo(
      centerX - notchRadius,
      topOffset,
      centerX - notchRadius + 10,
      topOffset + notchDepth,
    );

    path.arcToPoint(
      Offset(centerX + notchRadius - 10, topOffset + notchDepth),
      radius: Radius.circular(notchRadius - 5),
      clockwise: false,
    );

    path.quadraticBezierTo(
      centerX + notchRadius,
      topOffset,
      centerX + notchRadius + 15,
      topOffset,
    );

    path.lineTo(size.width, topOffset);
    path.lineTo(size.width, barHeight);
    path.lineTo(0, barHeight);
    path.close();

    canvas.drawShadow(path, Colors.black26, 4, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
