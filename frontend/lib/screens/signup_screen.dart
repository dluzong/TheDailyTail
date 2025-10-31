import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/starting_widgets.dart';
import 'onboarding_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _supabase = Supabase.instance.client;

    Future<bool> _signUp() async {
    //setState(() => _isLoading = true); // <-- ensure loading state
    try {
      debugPrint('Attempting sign up with email=${_email.text}');
      final res = await _supabase.auth.signUp(
        email: _email.text,
        password: _password.text,
        data: {'username': _username.text, 'first_name': _firstName.text, 'last_name': _lastName.text},
      );

      //IMPORTANT ---> FIX ERR ????
      //check if email exists 
      final user = res.user;
      debugPrint('sign up response: $res');
      if (user == null) {
          // SDK doesn't expose `res.error` here — show a generic messages.
          debugPrint('User == null');
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Sign up failed')));
          return false;
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed up')));
        return true;

        // navigate or refresh UI as needed
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
        debugPrint('Sign up error');
        debugPrint(err.toString());
        return false;
      }
    //if (mounted) setState(() => _isLoading = false);
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
                    buildAppTextField(hint: "First Name", controller: _firstName),
                    const SizedBox(height: 15),
                    buildAppTextField(hint: "Last Name", controller: _lastName),
                    const SizedBox(height: 15),
                    buildAppTextField(hint: "Username", controller: _username),
                    const SizedBox(height: 15),
                    buildAppTextField(hint: "Email", controller:_email),
                    const SizedBox(height: 15),
                    buildAppTextField(
                      hint: "Password",
                      controller: _password,
                      obscure: _obscurePassword,
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
                      obscure: _obscureConfirmPassword,
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
                    buildAppButton(
                      text: "Sign Up",
                      onPressed: () {
                        _signUp();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                        );
                      },
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
