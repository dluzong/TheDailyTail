import 'package:flutter/material.dart';
import '../shared/app_layout.dart';
import '../shared/side_menu.dart';
import '../screens/add_vaccination.dart';
import '../screens/add_medication.dart';

class DailyLogHealthScreen extends StatefulWidget {
  const DailyLogHealthScreen({super.key});

  @override
  State<DailyLogHealthScreen> createState() => _DailyLogHealthScreenState();
}

class _DailyLogHealthScreenState extends State<DailyLogHealthScreen> {
  final List<Map<String, dynamic>> vaccinations = [];
  final List<Map<String, dynamic>> medications = [];

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 1, // Heart section
      onTabSelected: (index) {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SideMenu(selectedIndex: 1), // Sidebar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Vaccinations",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final newVaccination =
                                await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) =>
                                  const VaccinationFormDialog(),
                            );
                            if (newVaccination != null) {
                              setState(() => vaccinations.add(newVaccination));
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    vaccinations.isEmpty
                        ? const Text("No vaccinations added yet.")
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text("Name")),
                                DataColumn(label: Text("Date Given")),
                                DataColumn(label: Text("Next Due")),
                              ],
                              rows: vaccinations
                                  .map(
                                    (v) => DataRow(
                                      cells: [
                                        DataCell(Text(v['name'])),
                                        DataCell(Text(v['dateGiven'])),
                                        DataCell(Text(v['nextDue'] ?? '-')),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Medications",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final newMedication =
                                await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) =>
                                  const MedicationFormDialog(),
                            );
                            if (newMedication != null) {
                              setState(() => medications.add(newMedication));
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    medications.isEmpty
                        ? const Text("No medications added yet.")
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text("Name")),
                                DataColumn(label: Text("Dosage")),
                                DataColumn(label: Text("Frequency")),
                              ],
                              rows: medications
                                  .map(
                                    (m) => DataRow(
                                      cells: [
                                        DataCell(Text(m['name'])),
                                        DataCell(Text(m['dosage'])),
                                        DataCell(Text(m['frequency'])),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
