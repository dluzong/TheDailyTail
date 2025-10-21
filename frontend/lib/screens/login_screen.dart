import 'package:flutter/material.dart';
import '../shared/starting_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

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
                    buildAppTextField(hint: "Username or Email"),
                    const SizedBox(height: 15),
                    buildAppTextField(
                      hint: "Password",
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
                    const SizedBox(height: 25),
                    buildAppButton(
                      text: "Login",
                      onPressed: () {
                        // TODO: Add login logic
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