import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../pet_provider.dart';
import '../user_provider.dart';
import '../shared/app_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedPetId;
  List<PetActivity> _currentActivities = [];
  bool _isActivitiesLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
    });
  }

  Future<void> _initialLoad() async {
    final userProvider = context.read<UserProvider>();
    final petProvider = context.read<PetProvider>();

    // Get User and User Pets
    await userProvider.fetchUser();
    debugPrint('User authenticated: ${userProvider.isAuthenticated}');


    if (userProvider.isAuthenticated && mounted) {
      await petProvider.fetchPets();

      if (petProvider.pets.isNotEmpty && mounted) {
        _selectPet(petProvider.pets.first);
      }
    }
  }

  Future<void> _selectPet(Pet pet) async {
    setState(() {
      _selectedPetId = pet.petId;
      _isActivitiesLoading = true;
      _currentActivities = [];
    });

    final provider = context.read<PetProvider>();
    final activities = await provider.fetchPetActivities(pet.petId);

    if (mounted) {
      setState(() {
        _currentActivities = activities;
        _isActivitiesLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final userProvider = context.watch<UserProvider>();

    final List<Pet> pets = petProvider.pets;
    Pet? selectedPet;
    if (_selectedPetId != null) {
      try {
        selectedPet = pets.firstWhere((p) => p.petId == _selectedPetId);
      } catch (e) {
        _selectedPetId = null;
      }
    }

    final bool hasPets = selectedPet != null;
    final details = hasPets
        ? {
            'Breed': selectedPet.breed,
            'Age': '${selectedPet.age} y/o',
            'Weight': '${selectedPet.weight} lbs',
          }
        : <String, String>{};

    return AppLayout(
      currentIndex: 1,
      onTabSelected: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown
            Row(
              children: [
                const Text('Pet: ', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedPetId,
                  hint: Text(
                    petProvider.isLoading ? 'Loading...' : 'Select a pet',
                  ),
                  items: pets
                      .map((p) => DropdownMenuItem(
                            value: p.petId,
                            child: Text(p.name,
                                style: GoogleFonts.lato(fontSize: 24)),
                          ))
                      .toList(),
                  onChanged: (newPetId) {
                    if (newPetId == null) return;

                    final petToSelect =
                        pets.firstWhere((p) => p.petId == newPetId);

                    _selectPet(petToSelect);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Dashboard title
            Text('Dashboard',
                style: GoogleFonts.lato(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            // main content logic
            _buildContent(
              context,
              userProvider,
              petProvider,
              hasPets,
              selectedPet,
              details,
            ),
          ],
        ),
      ),
    );
  }

  // helper to build main content area
  Widget _buildContent(
    BuildContext context,
    UserProvider userProvider,
    PetProvider petProvider,
    bool hasPets,
    Pet? selectedPet,
    Map<String, String> details,
  ) {
    // 1. Check for authentication
    if (!userProvider.isAuthenticated) {
      return const Center(
        child: Text(
          'Please log in to see your dashboard.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    // 2. Check if pets are loading
    if (petProvider.isLoading) {
      return const Center(
        child: Column(
          children: [
            SizedBox(height: 32),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your pets...'),
          ],
        ),
      );
    }

    // 3. Check for errors
    if (petProvider.errorMessage != null) {
      return Center(
        child: Text(
          'Error: ${petProvider.errorMessage}',
          style: const TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }

    // 4. Check if user has pets
    if (!hasPets) {
      return Center(
        child: Text(
          'No pets found. Add a pet to get started!',
          style: GoogleFonts.lato(fontSize: 18),
        ),
      );
    }

    // 5. User has pets, show the data
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pet image and details
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet Image Container
            Container(
              width: 120,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/dog.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.pets)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 80,
                            child: Text('${entry.key}:',
                                style: GoogleFonts.lato(
                                    fontWeight: FontWeight.w600))),
                        const SizedBox(width: 8),
                        Expanded(
                            child:
                                Text(entry.value, style: GoogleFonts.lato())),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Recent activity
        Text('Recent Activity',
            style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Divider(thickness: 2),

        // loader for activities section
        if (_isActivitiesLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ))
        else if (_currentActivities.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No recent activity for this pet.'),
          ))
        else
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentActivities.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final activity = _currentActivities[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(activity.description, style: GoogleFonts.lato()),
                subtitle: Text(
                  // MM/DD/YYYY format
                  '${activity.logDate.month}/${activity.logDate.day}/${activity.logDate.year}',
                  style: GoogleFonts.lato(fontSize: 12),
                ),
              );
            },
          ),
      ],
    );
  }
}
