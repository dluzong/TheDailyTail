import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/starting_widgets.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'onboarding_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );

      // Handle SDK differences: some versions return bool, others return an object
      if (response == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Google sign-in failed or was cancelled')),
          );
        }
        return;
      }
      // response == true -> continue

      // Attempt to load user/profile after OAuth flow
      try {
        await context.read<UserProvider>().fetchUser();
      } catch (e) {
        debugPrint('fetchUser after Google sign-in failed: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed in with Google')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      debugPrint('Google sign-in error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _isUsernameTaken(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select('user_id')
          .eq('username', username)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking username: $e');
      // Default to true to prevent accidental overwrites on error
      return true;
    }
  }

  Future<void> _signUp() async {
    // Basic validation
    if (_password.text != _confirmPassword.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return; // Exit early
    }
    if (_email.text.isEmpty || !_email.text.contains('@')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return; // Exit early
    }

    // Username validation
    final username = _username.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    final invalidChars = RegExp(r'[!@#$%^&*()+=:;,?/<>\s-]');
    if (invalidChars.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Username contains invalid characters. Do not include special characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      debugPrint('Attempting sign up with email=${_email.text}');
      final res = await _supabase.auth.signUp(
        email: _email.text,
        password: _password.text,
        data: {
          'username': _username.text,
          'name': _fullName.text,
        },
      );
      debugPrint('Sign-Up Response: $res');

      // Safely try to get the created user
      dynamic user;
      try {
        user = (res as dynamic).user ?? (res as dynamic).data?['user'];
      } catch (_) {
        user = null;
      }

      if (user == null) {
        // Extract an error/message safely for user feedback
        String message =
            'Sign up did not complete. The email may already be registered.';
        try {
          final dynamic maybeErr = (res as dynamic).error ??
              (res as dynamic).message ??
              (res as dynamic).errorMessage;
          if (maybeErr != null) message = maybeErr.toString();
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        return; // Exit early
      }

      if (_supabase.auth.currentSession == null) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false, // User cannot click away
          builder: (BuildContext context) {
            return const AlertDialog(
              title: Text("Verification Required"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("A verification email has been sent. Please click the link in your email to continue."),
                  SizedBox(height: 20),
                  CircularProgressIndicator(), // Show they are waiting
                ],
              ),
            );
          },
        );

        // 2. Start a loop that tries to log in every 3 seconds
        bool loggedIn = false;
        int attempts = 0;

        // Try for 5 mins (120 attempts * 5 secs = 300 secs)
        while (!loggedIn && attempts < 60) {
          await Future.delayed(const Duration(seconds: 5));
          attempts++;

          try {
            // Attempt to sign in. This will succeed ONLY after they click the email link.
            await _supabase.auth.signInWithPassword(
              email: _email.text.trim(),
              password: _password.text,
            );

            // If we get here, no error was thrown -> We are logged in!
            loggedIn = true;
            if (mounted) Navigator.pop(context); // Close the dialog
          } catch (e) {
            // Still not verified, keep waiting...
            debugPrint("Waiting for verification... Attempt $attempts");
          }
        }

        // 3. Handle timeout (User didn't click link in 60 seconds)
        if (!loggedIn) {
          if (mounted) Navigator.pop(context); // Close dialog
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification timed out. Please try logging in manually.')),
            );
          }
          return;
        }
      }

      try {
        await context.read<UserProvider>().fetchUser();
      } catch (e) {
        debugPrint('fetchUser after signup failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Signup succeeded but failed to load profile: $e')),
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Signed up')));
      // Navigate to OnboardingScreen after successful signup
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    } catch (err) {
      final message = err is AuthException ? err.message : err.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      debugPrint('Sign up error: $err');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
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
                    buildAppTextField(hint: "Full Name", controller: _fullName, context: context),
                    const SizedBox(height: 15),
                    buildAppTextField(hint: "Username", controller: _username, context: context),
                    const SizedBox(height: 15),
                    buildAppTextField(hint: "Email", controller: _email, context: context),
                    const SizedBox(height: 15),
                    buildAppTextField(
                      hint: "Password",
                      controller: _password,
                      obscure: _obscurePassword,
                      context: context,
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
                    const SizedBox(height: 15),
                    buildAppTextField(
                      hint: "Confirm Password",
                      controller: _confirmPassword,
                      obscure: _obscureConfirmPassword,
                      context: context,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF7496B3),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 25),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _signUp();
                            },
                      child: Text(_isLoading ? 'Signing Up...' : 'Sign Up'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : signInWithGoogle,
                      icon: const Icon(Icons.login, color: Color(0xFF7496B3)),
                      label: Text(
                          _isLoading ? 'Please wait...' : 'Sign up with Google',
                          style: const TextStyle(color: Color(0xFF7496B3))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7496B3)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          buildBorderBar(),
        ],
      ),
      ),
    );
  }
}
