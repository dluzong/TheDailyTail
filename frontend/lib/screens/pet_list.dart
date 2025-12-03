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

class ExpandablePetCard extends StatefulWidget {
  final pet_provider.Pet pet;

  const ExpandablePetCard({
    super.key,
    required this.pet,
  });

  @override
  State<ExpandablePetCard> createState() => _ExpandablePetCardState();
}

class _ExpandablePetCardState extends State<ExpandablePetCard> {
  bool _isExpanded = false;
  bool _expandedDone = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final petNameLength = widget.pet.name.length;
    // Calculate font size based on name length
    double collapsedFontSize = size.width * 0.04;
    if (petNameLength > 15) {
      collapsedFontSize = size.width * 0.032;
    } else if (petNameLength > 10) {
      collapsedFontSize = size.width * 0.036;
    }
    
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
            // Reset completion flag when toggling
            _expandedDone = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          onEnd: () {
            // Mark completion after expand; clear after collapse
            setState(() {
              _expandedDone = _isExpanded;
            });
          },
          padding: EdgeInsets.all(size.width * 0.04),
          constraints: BoxConstraints(
            maxWidth: _isExpanded ? size.width * 0.85 : size.width * 0.35,
            minHeight: _isExpanded ? size.width * 0.25 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isExpanded
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: size.width * 0.25,
                      height: size.width * 0.35,
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
                    Flexible(
                      child: (_expandedDone)
                          ? AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                          padding: EdgeInsets.only(left: size.width * 0.04),
                          constraints: BoxConstraints(
                            maxHeight: size.width * 0.35,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.pet.name,
                                  style: GoogleFonts.inknutAntiqua(
                                    fontSize: size.width * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF394957),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: size.height * 0.01),
                                _buildPetInfoRow('Breed', widget.pet.breed, size),
                                _buildPetInfoRow('Age', '${widget.pet.age} years', size),
                                _buildPetInfoRow('Weight', '${widget.pet.weight} lbs', size),
                              ],
                            ),
                                  ),
                                ),
                              )
                          : const SizedBox.shrink(),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: size.width * 0.3,
                      height: size.width * 0.3,
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
                    SizedBox(height: size.height * 0.01),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                      child: Text(
                        widget.pet.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: collapsedFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF394957),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPetInfoRow(String label, String value, Size size) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.002),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.lato(
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7496B3),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: size.width * 0.04,
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