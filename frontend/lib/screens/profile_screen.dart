import 'package:flutter/material.dart';
import '../shared/app_layout.dart';
import 'pet_list.dart';
import '../shared/starting_widgets.dart';
import 'all_pets_screen.dart';
import 'user_settings.dart' as user_settings;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<Pet> _pets = [
    Pet(
      name: 'Daisy',
      imageUrl: '',
    ),
    Pet(
      name: 'Patsy',
      imageUrl: '',
    ),
    Pet(
      name: 'Aries',
      imageUrl: '',
    ),
  ];

  late final PageController _pageController;
  // simulates a infinite scroll so the user can scroll in a loop on both ends
  static const int _kFakeMiddle = 10000;
  int _currentPage = 0; // logical index into _pets

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _kFakeMiddle,
    );

    // set initial logical page
    _currentPage = 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    // navigate relative to the current fake page so animation is smooth
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
    return AppLayout(
      currentIndex: 0,
      onTabSelected: (index) {},
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 125,
                  height: 125,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBFD4E6),
                    border: Border.all(color: const Color(0xFF7496B3), width: 4),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 60,
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 6,
                                ),
                        child: const Text(
                          'Your Name',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 6,
                                ),
                        child: const Text(
                          'username',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue[100]!,
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'Pet Owner',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 67, 145, 213),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue[100]!,
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'Pet Foster',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 67, 145, 213),
                              ),
                            ),
                          ),
                        ]
                      )
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 12.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Pets',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  buildAppButton(
                    text: 'View All',
                    width: 120,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AllPetsScreen(pets: _pets),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // pet view carousel
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: null, // this makes the carousel loop infinitely
                    onPageChanged: (fakeIndex) {
                      setState(() {
                        // logic to create loop
                        final logical = fakeIndex % _pets.length;
                        _currentPage = logical < 0 ? logical + _pets.length : logical;
                      });
                    },
                    itemBuilder: (context, fakeIndex) {
                      final logical = fakeIndex % _pets.length;
                      final pet = _pets[logical];
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            final page = (_pageController.page ?? _pageController.initialPage).toDouble();
                            value = (page - fakeIndex).toDouble();
                            value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                          }
                          return Center(
                            child: Transform.scale(
                              scale: value,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                          child: PetList(pet: pet),
                        ),
                      );
                    },
                  ),

                  // left arrow button
                  Positioned(
                    left: 4,
                    child: IconButton(
                      iconSize: 32,
                      color: Colors.black87,
                      onPressed: () => _goToPage(_currentPage - 1),
                      icon: const Icon(Icons.arrow_back_ios),
                    ),
                  ),

                  // right arrow button
                  Positioned(
                    right: 4,
                    child: IconButton(
                      iconSize: 32,
                      color: Colors.black87,
                      onPressed: () => _goToPage(_currentPage + 1),
                      icon: const Icon(Icons.arrow_forward_ios),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildAppButton(
                  text: 'Modify Pets',
                  onPressed: () {
                    // Map current simple Pet list to the more detailed UserSettings Pet
                    final initialForSettings = _pets.map((p) {
                      return user_settings.Pet(
                        id: '${p.name}-${DateTime.now().millisecondsSinceEpoch}',
                        name: p.name,
                        type: '',
                        breed: '',
                        age: 0,
                        imageUrl: p.imageUrl,
                      );
                    }).toList();

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => user_settings.UserSettingsPage(
                          currentIndex: 0,
                          onTabSelected: (i) {},
                          initialPets: initialForSettings,
                          onPetsUpdated: (updated) {
                            // Map back to the simple Pet model and update UI
                            setState(() {
                              _pets.clear();
                              _pets.addAll(updated.map((u) => Pet(name: u.name, imageUrl: u.imageUrl)).toList());
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}