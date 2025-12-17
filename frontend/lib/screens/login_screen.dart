import 'dart:async';
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

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Listen for successful auth state changes
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final event = data.event;
      debugPrint('LoginScreen: auth event=$event');

      if (event == AuthChangeEvent.signedIn) {
        setState(() => _isLoading = false);
        // Successful sign-in, navigate to dashboard
        context.read<UserProvider>().fetchUser().then((_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        });
      }
    });
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('LoginScreen: Starting Google OAuth');
        final response = await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.example.thedailytail://login-callback',
        );
      debugPrint('LoginScreen: OAuth response=$response');

      if (response == false) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Google sign-in failed or was cancelled')),
          );
        }
        return;
      }
      // Don't navigate here - let the auth state listener handle it
    } catch (e) {
      debugPrint('LoginScreen: Google OAuth error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in error: ${e.toString()}')));
      }
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('Attempting sign in with email=${_email.text}');
      final res = await _supabase.auth.signInWithPassword(
        email: _email.text,
        password: _password.text,
      );

      final user = res.user;
      debugPrint('signIn response: $res');
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Login failed')));
        return;
      }

      try {
        await context.read<UserProvider>().fetchUser();
      } catch (e) {
        debugPrint('fetchUser failed: $e');
        if (!mounted) return;
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
    } catch (err) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err.toString())));
      debugPrint('Log in error: $err');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Theme(
    data: ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
    ),
    child: Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main centered content
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      top: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        buildAppTitle(),
                        const SizedBox(height: 20), // Adjusted spacing after logo
                        buildAppTextField(hint: "Email", controller: _email, context: context, forceLightMode: true),
                        const SizedBox(height: 24),
                        buildAppTextField(
                          hint: "Password",
                          obscure: _obscurePassword,
                          controller: _password,
                          context: context,
                          forceLightMode: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                        OutlinedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7496B3), width: 1.5),
                            foregroundColor: const Color(0xFF7496B3),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                          child: Text(_isLoading ? 'Logging in...' : 'Log In'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : signInWithGoogle,
                          icon: const Icon(Icons.login, color: Color(0xFF7496B3)),
                          label: Text(
                            _isLoading ? 'Please wait...' : 'Login with Google',
                            style: const TextStyle(color: Color(0xFF7496B3)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7496B3)),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Back button at top-left
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF7496B3)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
