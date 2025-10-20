import 'package:flutter/material.dart';
import 'screens/launch_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  // read values from dotenv (runtime, not compile-time)
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
        'Supabase URL and Anon Key must be provided at compile time.');
  }

  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  debugPrint('Supabase initialized');
  debugPrint('supabaseUrl: $supabaseUrl');
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
