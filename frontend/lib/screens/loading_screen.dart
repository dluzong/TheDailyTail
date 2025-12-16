import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingScreen extends StatelessWidget {
  final String gifAsset;
  final String loadingText;

  const LoadingScreen({
    super.key,
    this.gifAsset = 'assets/dog-running.gif',
    this.loadingText = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GIF Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 320,
                height: 260,
                child: Image.asset(
                  gifAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Loading Text
            Text(
              loadingText,
              style: GoogleFonts.inknutAntiqua(
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
