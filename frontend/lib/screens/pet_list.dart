import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Pet {
  final String name;
  final String imageUrl;

  Pet({
    required this.name,
    required this.imageUrl,
  });
}

class PetList extends StatelessWidget {
  final Pet pet;

  const PetList({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // responsive size for screen: consider both width and height available
        final double maxSide = min(160.0, constraints.maxWidth == double.infinity ? 160.0 : constraints.maxWidth);
        // reserve some vertical space for the pet name; if height is unconstrained, fall back to a reasonable value
        final double availableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 220.0;
        // image should take up to ~65% of available height but never exceed maxSide
        final double imageSize = min(maxSide, availableHeight * 0.65);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: imageSize,
                width: imageSize,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 138, 193, 219),
                  borderRadius: BorderRadius.circular(12),
                  image: pet.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: AssetImage(pet.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: pet.imageUrl.isEmpty
                    ? Icon(
                        Icons.pets,
                        size: max(36.0, imageSize * 0.3),
                        color: Colors.white,
                      )
                    : null,
              ),
              // spacer below the image; scales with image size but keeps a minimum
              SizedBox(height: max(8.0, imageSize * 0.08)),
              // Make the name flexible so it can wrap or ellipsize based on available space
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: imageSize),
                child: Text(
                  pet.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inknutAntiqua(
                    fontSize: max(14.0, min(22.0, imageSize * 0.12)),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}