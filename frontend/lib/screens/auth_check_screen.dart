import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'loading_screen.dart';
import '../user_provider.dart';

class AuthCheckScreen extends StatefulWidget {
  final bool isNewSignup;

  const AuthCheckScreen({super.key, this.isNewSignup = false});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.isNewSignup) {
      // Show loading screen for 3 seconds, then navigate to dashboard
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      });
    } else {
      // If not new signup, go straight to dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isNewSignup
        ? LoadingScreen(
            gifAsset: 'assets/lottie/dog_roles.json',
            loadingText: 'Setting up your profile...',
          )
        : const DashboardScreen();
  }
}
