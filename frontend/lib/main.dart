import 'package:flutter/material.dart';
import 'screens/launch_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl =
    String.fromEnvironment('SUPABASE_URL', defaultValue: 'default');
const supabaseAnonKey =
    String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'default');

void main() async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
        'Supabase URL and Anon Key must be provided at compile time.');
  }

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

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
      home: const LaunchScreen(),
    );
  }
}
