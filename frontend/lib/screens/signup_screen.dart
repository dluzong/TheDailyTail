// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/starting_widgets.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'onboarding_screen.dart';
// import 'dashboard_screen.dart';

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
  // Track OAuth flow to handle browser return deterministically.
  bool _oauthInProgress = false;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastUserId;
  Timer? _oauthTimeout;

  @override
  void initState() {
    super.initState();
    _lastUserId = _supabase.auth.currentSession?.user.id;
    // Listen for auth changes to capture Google OAuth return and navigate once.
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        final ctx = context;
        final messenger = ScaffoldMessenger.of(ctx);
        final navigator = Navigator.of(ctx);
        final currentId = _supabase.auth.currentSession?.user.id;
        final lateOauth = (_lastUserId != currentId);
        // Only handle OAuth-completed flows here; ignore email sign-in polling results.
        if (!_oauthInProgress) {
          return;
        }
        // Update last seen user id
        _lastUserId = currentId;
        // We consider this as OAuth completion.
        try {
          await context.read<UserProvider>().fetchUser();
        } catch (_) {}

        if (!mounted || !context.mounted) return;
        // For SignUp flow, always proceed to Onboarding regardless of profile state

        _oauthTimeout?.cancel();
        setState(() {
          _isLoading = false;
          _oauthInProgress = false;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Signed in with Google')),
        );
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (route) => false,
        );
      }
    });
  }

  Future<bool> _isUsernameTaken(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select('username')
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
    final ctx = context;
    final messenger = ScaffoldMessenger.of(ctx);
    final navigator = Navigator.of(ctx);
    // Basic validation
    if (_password.text != _confirmPassword.text) {
      if (!mounted || !context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return; // Exit early
    }
    if (_email.text.isEmpty || !_email.text.contains('@')) {
      if (!mounted || !context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid email.')),
      );
      return; // Exit early
    }

    // Username validation
    final username = _username.text.trim();
    String usernameString = _username.text.toString();
    if (username.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Username cannot be empty.')),
      );
      return;
    }

    final isTaken = await _isUsernameTaken(usernameString);
    if (!mounted || !context.mounted) return;
    if (isTaken) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Username is already taken.')),
      );
      return;
    }

    final invalidChars = RegExp(r'[!@#$%^&*()+=:;,?/<>\s-]');
    if (invalidChars.hasMatch(username)) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text(
                'Username contains invalid characters. Do not include special characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _supabase.auth.signUp(
        email: _email.text,
        password: _password.text,
        data: {
          'username': _username.text,
          'name': _fullName.text,
        },
      );

      dynamic user;
      try {
        user = (res as dynamic).user ?? (res as dynamic).data?['user'];
      } catch (_) {
        user = null;
      }

      if (user == null) {
        String message =
            'Sign up did not complete. The email may already be registered.';
        try {
          final dynamic maybeErr = (res as dynamic).error ??
              (res as dynamic).message ??
              (res as dynamic).errorMessage;
          if (maybeErr != null) message = maybeErr.toString();
        } catch (_) {}
        if (!mounted || !context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      // If email verification is required (session is null or email not confirmed),
      // show a blocking dialog and poll login every 5s for up to 5 minutes.
      bool isEmailVerified = false;
      try {
        isEmailVerified = (user.emailConfirmedAt != null);
      } catch (_) {}
      dynamic session;
      try {
        session = (res as dynamic).session;
      } catch (_) {}
      if (session == null || !isEmailVerified) {
        if (!mounted || !context.mounted) return;
        showDialog(
          context: ctx,
          barrierDismissible: false,
          builder: (BuildContext dctx) {
            return const AlertDialog(
              title: Text('Verification Required'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'A verification email has been sent. Please click the link in your email to continue.'),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                ],
              ),
            );
          },
        );

        bool loggedIn = false;
        int attempts = 0;
        const maxAttempts = 60; // 5 minutes @ 5s
        while (!loggedIn && attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 5));
          attempts++;
          try {
            await _supabase.auth.signInWithPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
            loggedIn = true;
          } catch (_) {
            // Still not verified; continue polling
          }
        }

        if (!mounted || !context.mounted) return;
        Navigator.of(ctx).pop(); // close dialog

        if (!loggedIn) {
          messenger.showSnackBar(const SnackBar(
              content: Text(
                  'Verification timed out. Check your email for the link and try logging in.')));
          return;
        }
      }

      try {
        await context.read<UserProvider>().fetchUser();
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
                content:
                    Text('Signup succeeded but failed to load profile: $e')),
          );
        }
      }

      if (!mounted || !context.mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Signed up')));
      // Navigate to OnboardingScreen after successful signup
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    } catch (err) {
      final message = err is AuthException ? err.message : err.toString();
      if (!mounted || !context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _oauthTimeout?.cancel();
    _authSubscription?.cancel();
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
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 48), // Match login_screen
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF7496B3)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      buildAppTitle(),
                      const SizedBox(height: 20), // Adjusted spacing after logo
                      buildAppTextField(
                          hint: "Full Name",
                          controller: _fullName,
                          context: context,
                          forceLightMode: true),
                      const SizedBox(height: 24),
                      buildAppTextField(
                          hint: "Username",
                          controller: _username,
                          context: context,
                          forceLightMode: true),
                      const SizedBox(height: 24),
                      buildAppTextField(
                          hint: "Email",
                          controller: _email,
                          context: context,
                          forceLightMode: true),
                      const SizedBox(height: 24),
                      buildAppTextField(
                        hint: "Password",
                        controller: _password,
                        obscure: _obscurePassword,
                        context: context,
                        forceLightMode: true,
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
                      const SizedBox(height: 24),
                      buildAppTextField(
                        hint: "Confirm Password",
                        controller: _confirmPassword,
                        obscure: _obscureConfirmPassword,
                        context: context,
                        forceLightMode: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF7496B3),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      // const SizedBox(height: 25),
                      OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                _signUp();
                              },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF7496B3), width: 1.5),
                          foregroundColor: const Color(0xFF7496B3),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                        child: Text(_isLoading ? 'Signing Up...' : 'Sign Up'),
                      ),
                      const SizedBox(height: 15),
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                // Start OAuth flow; rely on auth listener to finish navigation.
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() {
                                  _isLoading = true;
                                  _oauthInProgress = true;
                                });
                                // Set a timeout to avoid getting stuck if deep link never returns.
                                _oauthTimeout?.cancel();
                                _oauthTimeout =
                                    Timer(const Duration(seconds: 30), () {
                                  if (!mounted || !context.mounted) return;
                                  if (_oauthInProgress) {
                                    setState(() {
                                      _oauthInProgress = false;
                                      _isLoading = false;
                                    });
                                    messenger.showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Google sign-in not completed. Please try again.')),
                                    );
                                  }
                                });
                                try {
                                  await context
                                      .read<UserProvider>()
                                      .signInWithGoogle();
                                  // Do not clear state here; wait for onAuthStateChange(signedIn).
                                } catch (e) {
                                  if (mounted) {
                                    _oauthInProgress = false;
                                    setState(() => _isLoading = false);
                                    messenger.showSnackBar(
                                        SnackBar(content: Text(e.toString())));
                                  }
                                }
                              },
                        icon: const Icon(Icons.login, color: Color(0xFF7496B3)),
                        label: Text(
                            _isLoading
                                ? 'Please wait...'
                                : 'Sign up with Google',
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
          ],
        ),
      ),
    );
  }
}
