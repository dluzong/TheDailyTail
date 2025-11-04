import 'package:flutter/material.dart';
import '../shared/app_layout.dart';
// import 'pet_list.dart';
import '../shared/starting_widgets.dart';
import 'all_pets_screen.dart';
import 'user_settings.dart' as user_settings;
import '../user_provider.dart';
import '../pet_provider.dart' as pet_provider;
import 'pet_list.dart' as pet_list;
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final PageController _pageController;
  static const int _kFakeMiddle = 10000;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _kFakeMiddle);
    _currentPage = 0;
    
    // Fetch pets if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petProvider =
          Provider.of<pet_provider.PetProvider>(context, listen: false);
      if (petProvider.pets.isEmpty && !petProvider.isLoading) {
        petProvider.fetchPets();
      }
    });
  }

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
    return Consumer2<UserProvider, pet_provider.PetProvider>(
      builder: (context, userProvider, petProvider, child) {
        final user = userProvider.user;
        final pets = petProvider.pets;
        final isLoading = petProvider.isLoading;
        final fullName = user != null
            ? '${user.firstName} ${user.lastName}'.trim()
            : 'Your Name';
        final username = user?.username ?? 'username';
        final role = user?.role ?? 'User';

        // Map pet_provider.Pet to pet_list.Pet for UI
        List<pet_list.Pet> petListForUI = pets
            .map((p) => pet_list.Pet(
                  name: p.name,
                  imageUrl:
                      '', // No imageUrl in pet_provider.Pet, set as needed
                ))
            .toList();

        return AppLayout(
          currentIndex: 0,
          onTabSelected: (index) {},
          child: Stack(
            children: [
              Padding(
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
                            border: Border.all(
                                color: const Color(0xFF7496B3), width: 4),
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
                                child: Text(
                                  fullName,
                                  style: const TextStyle(
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
                                child: Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                    child: Text(
                                      role,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            Color.fromARGB(255, 67, 145, 213),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50),

                    const Padding(
                      padding:
                          EdgeInsets.only(left: 16.0, right: 8.0, bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'My Pets',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // pet view carousel
                    SizedBox(
                      height: 200,
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : petListForUI.isEmpty
                              ? const Center(child: Text('No pets found.'))
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PageView.builder(
                                      controller: _pageController,
                                      itemCount: null, // infinite loop
                                      onPageChanged: (fakeIndex) {
                                        setState(() {
                                          final logical =
                                              fakeIndex % petListForUI.length;
                                          _currentPage = logical < 0
                                              ? logical + petListForUI.length
                                              : logical;
                                        });
                                      },
                                      itemBuilder: (context, fakeIndex) {
                                        final logical =
                                            fakeIndex % petListForUI.length;
                                        final pet = petListForUI[logical];
                                        return AnimatedBuilder(
                                          animation: _pageController,
                                          builder: (context, child) {
                                            double value = 1.0;
                                            if (_pageController
                                                .position.haveDimensions) {
                                              final page =
                                                  (_pageController.page ??
                                                          _pageController
                                                              .initialPage)
                                                      .toDouble();
                                              value =
                                                  (page - fakeIndex).toDouble();
                                              value = (1 - (value.abs() * 0.15))
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0, vertical: 0.0),
                                            child: pet_list.PetList(pet: pet),
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
                                        onPressed: () =>
                                            _goToPage(_currentPage - 1),
                                        icon: const Icon(Icons.arrow_back_ios),
                                      ),
                                    ),
                                    // right arrow button
                                    Positioned(
                                      right: 4,
                                      child: IconButton(
                                        iconSize: 32,
                                        color: Colors.black87,
                                        onPressed: () =>
                                            _goToPage(_currentPage + 1),
                                        icon:
                                            const Icon(Icons.arrow_forward_ios),
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
                          text: 'View All',
                          width: 160,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AllPetsScreen(pets: petListForUI),
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
              // settings button
              Positioned(
                top: 14,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.settings,
                      size: 32, color: Color(0xFF7496B3)),
                  tooltip: 'User Settings',
                  onPressed: () {
                    final initialForSettings = petListForUI.map((p) {
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
                            // No direct update to provider, just refresh UI if needed
                            setState(() {});
                          },
                          onProfileUpdated: (map) {
                            // No direct update to provider, just refresh UI if needed
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
