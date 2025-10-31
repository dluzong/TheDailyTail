import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> pets = [];
  String selectedPet = '';
  bool _isLoading = false;

  // pet_name: {breed: '', age: '', weight: ''}
  final Map<String, Map<String, String>> petData = {};
  // pet_name: [activity1, activity2, ...]
  final Map<String, List<String>> activities = {};

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  // fetch pets belonging to the user from Supabase
  Future<void> _fetchPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseClient = Supabase.instance.client;
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        debugPrint("No user logged in. Failed to fetch pets.");
        return;
      }

      // query to fetch pet details
      // SELECT * FROM pets WHERE user_id = 'user.id' ORDER BY name ASC;
      final data = await supabaseClient
          .from('pets')
          .select()
          .eq('user_id', user.id)
          .order('name', ascending: true);

      setState(() {
        pets.clear();
        petData.clear();
        activities.clear();

        for (var pet in data) {
          final petName = pet['name'] as String? ?? 'Unknown';
          pets.add(petName);
          petData[petName] = {
            'Breed': pet['breed']?.toString() ?? 'Unknown',
            'Age': pet['age'] != null ? pet['age'].toString() : 'Unknown',
            'Weight':
                pet['weight'] != null ? '${pet['weight']} lbs' : 'Unknown',
          };
          activities[petName] = [];
        }

        if (pets.isNotEmpty &&
            (selectedPet.isEmpty || !pets.contains(selectedPet))) {
          selectedPet = pets[0];
        }
      });
    } catch (e) {
      debugPrint("Exception while fetching pets: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPets = pets.isNotEmpty &&
        selectedPet.isNotEmpty &&
        petData.containsKey(selectedPet);
    final details = hasPets ? petData[selectedPet]! : <String, String>{};

    return AppLayout(
      currentIndex: 1,
      onTabSelected: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown below the AppLayout title (AppLayout places this child under the header)
            Row(
              children: [
                const Text('Pet: ', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: hasPets ? selectedPet : null,
                  hint: const Text('Select a pet'),
                  items: pets
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child:
                                Text(p, style: GoogleFonts.lato(fontSize: 24)),
                          ))
                      .toList(),
                  onChanged: hasPets
                      ? (v) {
                          if (v == null) return;
                          setState(() => selectedPet = v);
                        }
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Dashboard title with divider
            Text('Dashboard',
                style: GoogleFonts.lato(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Divider(thickness: 2),

            const SizedBox(height: 16),

            // Pet image and details
            if (hasPets) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rounded rectangle image
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

                  // Details to the right
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
                                  child: Text(entry.value,
                                      style: GoogleFonts.lato())),
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
                  style: GoogleFonts.lato(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Divider(thickness: 2),

              ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities[selectedPet]?.length ?? 0,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final activity = activities[selectedPet]![index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(activity, style: GoogleFonts.lato()),
                    subtitle:
                        Text('Today', style: GoogleFonts.lato(fontSize: 12)),
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 32),
              Center(
                child: Text(
                  _isLoading
                      ? 'Loading pets...'
                      : 'No pets found. Add a pet to get started!',
                  style: GoogleFonts.lato(fontSize: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
