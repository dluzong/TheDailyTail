import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'screens/launch_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'pet_provider.dart';
import 'posts_provider.dart';
import 'organization_provider.dart';
import 'log_provider.dart';
import 'theme_provider.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => PetProvider()),
        ChangeNotifierProvider(create: (context) => LogProvider()),
        ChangeNotifierProvider(create: (context) => PostsProvider()),
        ChangeNotifierProvider(create: (context) => OrganizationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'The Daily Tail',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            primarySwatch: Colors.blue,
          ),
          themeMode: themeProvider.themeMode,
          home: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.isAuthenticated) {
                return const DashboardScreen();
              } else {
                return const LaunchScreen();
              }
            },
          ),
        );
      },
    );
  }
}
