import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_layout.dart';

class CommunityBoardScreen extends StatefulWidget {
  const CommunityBoardScreen({super.key});

  @override
  State<CommunityBoardScreen> createState() => _CommunityBoardScreenState();
}

class _CommunityBoardScreenState extends State<CommunityBoardScreen> {
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 2,
      onTabSelected: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Community Board Under Construction',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
          ] 
        ),
      ),
    );
  }
}