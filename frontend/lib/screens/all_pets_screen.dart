import 'package:flutter/material.dart';
import 'pet_list.dart';
import '../shared/app_layout.dart';
import '../shared/starting_widgets.dart';

class AllPetsScreen extends StatelessWidget {
  final List<Pet> pets;

  const AllPetsScreen({super.key, required this.pets});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 0,
      onTabSelected: (index) {},
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 5.0),
              child: Text(
                'All Pets',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // taller cards so name has more room
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: PetList(pet: pets[index])),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: buildAppButton(
                text: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
