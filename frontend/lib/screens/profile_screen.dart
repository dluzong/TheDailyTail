import 'package:flutter/material.dart';
import 'pet_list.dart' as pet_list;
import '../shared/app_layout.dart';
import '../shared/starting_widgets.dart';
import 'all_pets_screen.dart' as all_pets;
import 'user_settings.dart' as user_settings;
import '../user_provider.dart';
import '../pet_provider.dart' as pet_provider;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PageController _pageController =
      PageController(initialPage: _kFakeMiddle);
  static const int _kFakeMiddle = 10000;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    // Providers load from cache on creation. Avoid network fetch here to keep profile lightweight.
  }

  // pet data is managed by PetProvider; no local fetch needed

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    final currentFake = _pageController.page?.round() ?? _kFakeMiddle;
    final targetFake = currentFake + (page - _currentPage);
    _pageController.animateToPage(
      targetFake,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textScale = MediaQuery.of(context).textScaleFactor;

    final appUser = context.watch<UserProvider>().user;
    final fullName = appUser != null
        ? '${appUser.firstName} ${appUser.lastName}'.trim()
        : 'Your Name';
    final username = appUser?.username ?? 'username';
    final role = appUser?.role ?? 'User';

    double avatarSize = size.width * 0.30;
    double carouselHeight = size.height * 0.22;
    double arrowSize = size.width * 0.08;

    return AppLayout(
      currentIndex: 0,
      onTabSelected: (_) {},
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFBFD4E6),
                        border: Border.all(
                          color: const Color(0xFF7496B3),
                          width: size.width * 0.01,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: avatarSize * 0.5,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: size.width * 0.03),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.inknutAntiqua(
                                fontSize: 20 * textScale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              username,
                              style: GoogleFonts.inknutAntiqua(
                                fontSize: 16 * textScale,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.05,
                                  vertical: size.height * 0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blue[100]!,
                                    width: size.width * 0.005,
                                  ),
                                ),
                                child: Text(
                                  role,
                                  style: GoogleFonts.inknutAntiqua(
                                    fontSize: 12 * textScale,
                                    color:
                                        const Color.fromARGB(255, 67, 145, 213),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.04),

                Padding(
                  padding: EdgeInsets.only(bottom: size.height * 0.015),
                  child: Text(
                    'My Pets',
                    style: GoogleFonts.inknutAntiqua(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7496B3),
                    ),
                  ),
                ),

                // Pet Carousel
                SizedBox(
                  height: carouselHeight,
                  child: Builder(builder: (context) {
                    final petProv =
                        Provider.of<pet_provider.PetProvider>(context);
                    final isLoading = petProv.isLoading;
                    final pets = petProv.pets
                        .map((p) => pet_list.Pet(name: p.name, imageUrl: ''))
                        .toList();

                    return isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : pets.isEmpty
                            ? Center(
                                child: Text(
                                  'No pets found.',
                                  style:
                                      GoogleFonts.inknutAntiqua(fontSize: 16),
                                ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  PageView.builder(
                                    controller: _pageController,
                                    itemCount: null,
                                    onPageChanged: (fakeIndex) {
                                      setState(() {
                                        final logical = fakeIndex % pets.length;
                                        _currentPage = logical < 0
                                            ? logical + pets.length
                                            : logical;
                                      });
                                    },
                                    itemBuilder: (context, fakeIndex) {
                                      final logical = fakeIndex % pets.length;
                                      final pet = pets[logical];

                                      return AnimatedBuilder(
                                        animation: _pageController,
                                        builder: (context, child) {
                                          double value = 1.0;
                                          if (_pageController
                                              .position.haveDimensions) {
                                            final page = (_pageController
                                                        .page ??
                                                    _pageController.initialPage)
                                                .toDouble();
                                            value = (1 -
                                                    ((page - fakeIndex).abs() *
                                                        0.15))
                                                .clamp(0.85, 1.0);
                                          }
                                          return Center(
                                            child: Transform.scale(
                                              scale: value,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: size.width * 0.02,
                                          ),
                                          child: pet_list.PetList(pet: pet),
                                        ),
                                      );
                                    },
                                  ),
                                  if (pets.length > 1) ...[
                                    Positioned(
                                      left: size.width * 0.01,
                                      child: IconButton(
                                        iconSize: arrowSize,
                                        onPressed: () =>
                                            _goToPage(_currentPage - 1),
                                        icon: const Icon(Icons.arrow_back_ios),
                                      ),
                                    ),
                                    Positioned(
                                      right: size.width * 0.01,
                                      child: IconButton(
                                        iconSize: arrowSize,
                                        onPressed: () =>
                                            _goToPage(_currentPage + 1),
                                        icon:
                                            const Icon(Icons.arrow_forward_ios),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                  }),
                ),
                SizedBox(height: size.height * 0.03),

                Center(
                  child: buildAppButton(
                    text: 'View All',
                    width: size.width * 0.45,
                    onPressed: () {
                      final petProv = Provider.of<pet_provider.PetProvider>(
                          context,
                          listen: false);
                      final pets = petProv.pets
                          .map((p) => pet_list.Pet(name: p.name, imageUrl: ''))
                          .toList();

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => all_pets.AllPetsScreen(pets: pets),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: size.height * 0.07),
              ],
            ),
          ),

          // Settings button
          Positioned(
            top: size.height * 0.025,
            right: size.width * 0.025,
            child: IconButton(
              icon: Icon(
                Icons.settings,
                size: size.width * 0.08,
                color: const Color(0xFF7496B3),
              ),
              tooltip: 'User Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const user_settings.UserSettingsPage(
                      currentIndex: 0,
                      onTabSelected: _noop,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Helper for onTabSelected placeholder
void _noop(int _) {}
