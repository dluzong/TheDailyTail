import 'package:flutter/material.dart';
import '../shared/starting_widgets.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          buildBorderBar(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildAppTitle(),
                  const SizedBox(height: 25),
                  buildDogIcon(),
                  const SizedBox(height: 35),
                  buildAppButton(
                    text: "Login",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  buildAppButton(
                    text: "Sign Up",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          buildBorderBar(),
        ],
      ),
    );
  }
}
