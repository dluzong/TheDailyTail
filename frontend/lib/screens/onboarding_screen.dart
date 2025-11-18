import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/add_pet_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? selectedRole;

  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Welcome user!",
      "subtitle":
          "The Daily Tail helps you track your pet’s health and connect with fellow pet lovers.",
      "animation": "assets/lottie/cat_playing.json",
    },
    {
      "title": "Track Health with Ease",
      "subtitle":
          "Log your pet’s food, meds, and vaccinations all in one simple dashboard.",
      "animation": "assets/lottie/journaling.json",
    },
    {
      "title": "Connect with Pet Lovers",
      "subtitle":
          "Find sitters, fosters, and other owners nearby to share and connect.",
      "animation": "assets/lottie/connecting.json",
    },
    {
      "title": "Tell us who you are",
      "showPaw": true,
      "subtitle": "Choose the role that fits you best",
      "roles": ["Pet Owner", "Pet Sitter", "Adoption Organizer", "Foster"],
      "animation": "assets/lottie/dog_roles.json",
    },
    {
      "title": "Add your first pet?",
      "subtitle":
          "No worries if you're not ready — you can always add pets later from your profile.",
      "isAddPetPrompt": true,
      "animation": "assets/lottie/owner_n_dog.json",
    },
    {
      "title": "You’re all set!",
      "subtitle":
          "You’re ready to begin your pet care journey with The Daily Tail.\nThanks for joining us!",
      "animation": "assets/lottie/confetti.json",
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToAddPet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPetScreen()),
    );

    // After returning, go to the last slide (add-pet prompt)
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const topBottomBarColor = Color(0xFF7496B3);
    const headerBg = Color(0xFFBFD4E6);
    const headerTextColor = Color(0xFF7496B3);
    const titleColor = Color(0xFF5F7C94);
    const buttonBlue = Color(0xFF8DB6D9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(height: 30, color: topBottomBarColor),

          // 🔹 Header (removed paw icon)
          Container(
            width: double.infinity,
            color: headerBg,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                "The Daily Tail",
                style: GoogleFonts.inknutAntiqua(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: headerTextColor,
                ),
              ),
            ),
          ),

          // Sliding content
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: page["animation"]
                                      .toString()
                                      .contains("journaling.json")
                                  ? Transform.translate(
                                      offset: const Offset(30, 0),
                                      child: Lottie.asset(
                                        page["animation"],
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Lottie.asset(
                                      page["animation"],
                                      fit: BoxFit.contain,
                                    ),
                            ),
                            const SizedBox(height: 20),

                            // 🔹 Titles (paw only for roles screen)
                            page["showPaw"] == true
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        page["title"] ?? "",
                                        style: GoogleFonts.inknutAntiqua(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: titleColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.pets,
                                        size: 26,
                                        color: titleColor,
                                      ),
                                    ],
                                  )
                                : Text(
                                    page["title"] ?? "",
                                    style: GoogleFonts.inknutAntiqua(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                            const SizedBox(height: 10),
                            Text(
                              page["subtitle"] ?? "",
                              style: GoogleFonts.inknutAntiqua(
                                fontSize: 16,
                                height: 1.5,
                                color: titleColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 25),

                            // Role buttons (for role slide) — select/highlight only
                            if (page["roles"] != null)
                              Column(
                                children:
                                    (page["roles"] as List<String>).map((role) {
                                  final isSelected = selectedRole == role;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: SizedBox(
                                      width: 220,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isSelected ? titleColor : buttonBlue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                        ),
                                        onPressed: () {
                                          // only highlight — do not navigate here
                                          setState(() => selectedRole = role);
                                        },
                                        child: Text(
                                          role,
                                          style: const TextStyle(
                                            fontFamily: 'Georgia',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bottom controls
                  // Page indicator (shown on all pages)
                  Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: const WormEffect(
                        activeDotColor: Color(0xFF5F7C94),
                        dotColor: Colors.grey,
                        dotHeight: 8,
                        dotWidth: 8,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  if (_pages[_currentPage]["isAddPetPrompt"] == true)
                    // Show Skip -> move to "You're all set" page, and Add Pet
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            // go to the final "You're all set!" page
                            _pageController.animateToPage(
                              _pages.length - 1,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text("Skip for now"),
                        ),
                        ElevatedButton(
                          onPressed: () => _goToAddPet(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                          ),
                          child: const Text("Add Pet"),
                        ),
                      ],
                    )
                  else if (_currentPage == _pages.length - 1)
                    // Final page: Get Started
                    Center(
                      child: ElevatedButton(
                        onPressed: _finishOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14),
                        ),
                        child: const Text(
                          "Get Started",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    // Default controls: Skip, Page Indicator, Next
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _finishOnboarding,
                          child: const Text("Skip"),
                        ),
                        ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                          ),
                          child: const Text("Next"),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          Container(height: 30, color: topBottomBarColor),
        ],
      ),
    );
  }
}
