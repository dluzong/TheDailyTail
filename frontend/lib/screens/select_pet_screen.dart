import 'package:flutter/material.dart';
import 'profile_screen.dart';

class SelectPetScreen extends StatefulWidget {
  const SelectPetScreen({super.key});

  @override
  State<SelectPetScreen> createState() => _SelectPetScreenState();
}

class _SelectPetScreenState extends State<SelectPetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Daily Tail'),
        backgroundColor: const Color(0xFF7496B3),
      ),
      body: Container(
        color: Colors.blue[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Select A Pet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7496B3),
                      ),
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.person, size: 50),
                        Icon(Icons.person, size: 50),
                        Icon(Icons.person, size: 50),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7496B3),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}