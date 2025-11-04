import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/starting_widgets.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _supabase = Supabase.instance.client;

  Future<void> _signIn() async {
    setState(() => _isLoading = true); // <-- ensure loading state
    try {
      debugPrint('Attempting sign in with email=${_email.text}');
      final res = await _supabase.auth.signInWithPassword(
        email: _email.text,
        password: _password.text,
      );

      final user = res.user;
      debugPrint('signIn response: $res');
      if (user == null) {
        // SDK doesn't expose `res.error` here — show a generic messages.
        debugPrint('User == null');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Login failed')));
        return;
      }

      try {
        await context.read<UserProvider>().fetchUser();
      } catch (e) {
        debugPrint('fetchUser failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user: $e')),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Logged in')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (Route<dynamic> route) => false,
      );
      // navigate or refresh UI as needed
    } catch (err) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err.toString())));
      debugPrint('Log in error');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          buildBorderBar(),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF7496B3)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    buildAppTitle(),
                    const SizedBox(height: 25),
                    buildDogIcon(),
                    const SizedBox(height: 35),
                    buildAppTextField(hint: "Email", controller: _email),
                    const SizedBox(height: 15),
                    buildAppTextField(
                      hint: "Password",
                      obscure: _obscurePassword,
                      controller: _password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF7496B3),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _signIn();
                            },
                      child: Text(_isLoading ? 'Logging in...' : 'Log In'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          buildBorderBar(),
        ],
      ),
    );
  }
}