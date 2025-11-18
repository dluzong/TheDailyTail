import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pet_provider.dart' as pet_provider;

class Pet {
  final String name;
  final String imageUrl;

  Pet({
    required this.name,
    required this.imageUrl,
  });
}

class ExpandablePetCard extends StatelessWidget {
  final pet_provider.Pet pet;
  final bool isExpanded;
  final VoidCallback onTap;

  const ExpandablePetCard({
    super.key,
    required this.pet,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: size.width * 0.25,
                    height: size.width * 0.25,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 138, 193, 219),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pets,
                      size: size.width * 0.12,
                      color: Colors.white,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutSine,
                    child: isExpanded
                        ? Container(
                            width: size.width * 0.5,
                            padding: EdgeInsets.only(left: size.width * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  pet.name,
                                  style: GoogleFonts.inknutAntiqua(
                                    fontSize: size.width * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF394957),
                                  ),
                                ),
                                SizedBox(height: size.height * 0.01),
                                _buildPetInfoRow('Breed', pet.breed, size),
                                _buildPetInfoRow('Age', '${pet.age} years', size),
                                _buildPetInfoRow('Weight', '${pet.weight} lbs', size),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              if (!isExpanded) ...[
                SizedBox(height: size.height * 0.01),
                Text(
                  pet.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inknutAntiqua(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF394957),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetInfoRow(String label, String value, Size size) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.005),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.lato(
              fontSize: size.width * 0.035,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7496B3),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: size.width * 0.035,
                color: const Color(0xFF394957),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PetList extends StatelessWidget {
  final Pet pet;

  const PetList({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxSide = min(160.0, constraints.maxWidth == double.infinity ? 160.0 : constraints.maxWidth);
        final double availableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 220.0;
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
              SizedBox(height: max(8.0, imageSize * 0.08)),
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