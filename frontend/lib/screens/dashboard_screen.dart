import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> pets = ['Daisy', 'Teddy', 'Aries'];
  String selectedPet = 'Daisy';

  // Example pet data
  final Map<String, Map<String, String>> petData = {
    'Daisy': {
      'Breed': 'Norfolk Terrier Mix',
      'Age': '4 years',
      'Sex': 'Female',
      'Weight': '20 lbs',
    },
    'Teddy': {
      'Breed': 'n/a',
      'Age': 'n/a',
      'Sex': 'n/a',
      'Weight': 'n/a',
    },
    'Aries': {
      'Breed': 'n/a',
      'Age': 'n/a',
      'Sex': 'n/a',
      'Weight': 'n/a',
    },
  };

  final Map<String, List<String>> activities = {
    'Daisy': [
      'Walked 30 mins',
      'Fed breakfast',
    ],
    'Teddy': [
      'Vaccination reminder',
      'Played fetch',
    ],
    'Aries': [
      'Vet visit at 2pm',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final details = petData[selectedPet]!;

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
                  value: selectedPet,
                  items: pets
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p, style: GoogleFonts.lato(fontSize: 24)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => selectedPet = v);
                  },
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
            Text('Recent activity',
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
                  subtitle: Text('Today', style: GoogleFonts.lato(fontSize: 12)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}