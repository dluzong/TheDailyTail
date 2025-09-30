import 'package:flutter/material.dart';
import '../shared/app_layout.dart';
import 'pet_list.dart';
import '../shared/starting_widgets.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final List<Pet> _pets = [
  Pet(
    name: 'Daisy',
    imageUrl: '',
  ),
  Pet(
    name: 'Pasty',
    imageUrl: '',
  ),
  Pet(
    name: 'Aries',
    imageUrl: '',
  ),
];

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

            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 16.0),
              child: Text(
                'My Pets',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: _pets.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  return PetList(
                    pet: _pets[index],
                  );
                },
              ),
            ),

            const SizedBox(height: 60), // Reduced from 100 to 30 to push button upwards

            Center( // Added Center widget to center the button
              child: buildAppButton(
                text: 'Modify Pets',
                onPressed: () {
                  // Handle button press
                },
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}