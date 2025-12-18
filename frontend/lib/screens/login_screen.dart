// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/onboarding_screen.dart';
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

  bool _oauthInProgress = false;
  String? _lastUserId;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _oauthTimeout;

  @override
  void initState() {
    super.initState();
    _lastUserId = _supabase.auth.currentSession?.user.id;
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        final ctx = context;
        final messenger = ScaffoldMessenger.of(ctx);
        final navigator = Navigator.of(ctx);
        final currentId = _supabase.auth.currentSession?.user.id;
        final lateOauth = (_lastUserId != currentId);
        if (!_oauthInProgress && !lateOauth) {
          return;
        }
        _lastUserId = currentId;
        try {
          await context.read<UserProvider>().fetchUser();
        } catch (e) {
          // Ignore fetch error; navigation continues
        }
        if (!mounted || !context.mounted) return;
        // Determine profile existence via provider single source of truth
        // Use optimistic fallback on 403 (RLS) for returning users
        bool hasProfile = await context
            .read<UserProvider>()
            .hasProfile(assumeExistsOnForbidden: true);
        if (!mounted || !context.mounted) return;
        _oauthTimeout?.cancel();
        setState(() {
          _isLoading = false;
          _oauthInProgress = false;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Signed in with Google')),
        );
        if (hasProfile) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _oauthTimeout?.cancel();
    _authSubscription?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final ctx = context;
    final messenger = ScaffoldMessenger.of(ctx);
    final navigator = Navigator.of(ctx);
    setState(() => _isLoading = true);
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: _email.text,
        password: _password.text,
      );

      final user = res.user;
      if (user == null) {
        if (!mounted || !context.mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('Login failed')));
        return;
      }

      // If email isn't verified yet, block navigation and prompt verification.
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
        messenger.showSnackBar(const SnackBar(
            content: Text(
                'Please verify your email first. Check your inbox for the verification link.')));
        // Ensure we don't leave a partial session around.
        try {
          await _supabase.auth.signOut();
        } catch (_) {}
        return;
      }

      try {
        await context.read<UserProvider>().fetchUser();
      } catch (e) {
        if (!mounted || !context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to load user: $e')),
        );
      }

      if (!mounted || !context.mounted) return;

      // Determine profile existence via provider single source of truth
      // Use optimistic fallback on 403 (RLS) for returning users
      bool hasProfile = await context
          .read<UserProvider>()
          .hasProfile(forUserId: user.id, assumeExistsOnForbidden: true);
      if (!mounted || !context.mounted) return;

      messenger.showSnackBar(const SnackBar(content: Text('Logged in')));
      if (hasProfile) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (err) {
      final msg = err is AuthException ? err.message : err.toString();
      if (!mounted || !context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
    if (mounted) setState(() => _isLoading = false);
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
                          const SizedBox(
                              height: 20), // Adjusted spacing after logo
                          buildAppTextField(
                              hint: "Email",
                              controller: _email,
                              context: context,
                              forceLightMode: true),
                          const SizedBox(height: 24),
                          buildAppTextField(
                            hint: "Password",
                            obscure: _obscurePassword,
                            controller: _password,
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
                          const SizedBox(height: 25),
                          OutlinedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFF7496B3), width: 1.5),
                              foregroundColor: const Color(0xFF7496B3),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                            ),
                            child:
                                Text(_isLoading ? 'Logging in...' : 'Log In'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _isLoading = true;
                                      _oauthInProgress = true;
                                    });
                                    _oauthTimeout?.cancel();
                                    _oauthTimeout =
                                        Timer(const Duration(seconds: 30), () {
                                      if (!mounted || !context.mounted) return;
                                      if (_oauthInProgress) {
                                        setState(() {
                                          _oauthInProgress = false;
                                          _isLoading = false;
                                        });
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        messenger.showSnackBar(const SnackBar(
                                            content: Text(
                                                'Google sign-in not completed. Please try again.')));
                                      }
                                    });
                                    try {
                                      await context
                                          .read<UserProvider>()
                                          .signInWithGoogle();
                                      // Do not navigate here; wait for auth listener.
                                    } catch (e) {
                                      if (mounted) {
                                        _oauthInProgress = false;
                                        setState(() => _isLoading = false);
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        messenger.showSnackBar(SnackBar(
                                            content: Text(e.toString())));
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.login,
                                color: Color(0xFF7496B3)),
                            label: Text(
                              _isLoading
                                  ? 'Please wait...'
                                  : 'Login with Google',
                              style: const TextStyle(color: Color(0xFF7496B3)),
                            ),
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
