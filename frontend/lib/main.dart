import 'package:flutter/material.dart';
import 'screens/launch_screen.dart';
import 'screens/user_settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Daily Tail',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 1; // Assuming settings is at index 1
  List<Pet> _pets = []; // Initialize with empty list or default pets

  // Sample initial pets data
  @override
  void initState() {
    super.initState();
    _pets = [
      Pet(
        id: '1',
        name: 'Buddy',
        type: 'Dog',
        breed: 'Golden Retriever',
        age: 3,
        imageUrl: '', // Add your image path if available
      ),
    ];
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      // You can add navigation logic here to switch between different pages
      // For now, we're only showing UserSettingsPage
    });
  }

  void _onPetsUpdated(List<Pet> updatedPets) {
    setState(() {
      _pets = updatedPets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return UserSettingsPage(
      currentIndex: _currentIndex,
      onTabSelected: _onTabSelected,
      initialPets: _pets,
      onPetsUpdated: _onPetsUpdated,
    );
  }
}
