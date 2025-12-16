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

  String _formatBirthday(String birthday) {
    if (birthday.isEmpty) {
      return 'Unknown';
    }
    return birthday;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF404040)
                  : Colors.grey,
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
                      // ADD THIS SECTION:
                      image: widget.pet.imageUrl.isNotEmpty
                          ? DecorationImage(
                        image: widget.pet.imageUrl.startsWith('http')
                            ? NetworkImage(widget.pet.imageUrl)
                            : AssetImage(widget.pet.imageUrl) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    // Only show the icon if there is NO image
                    child: widget.pet.imageUrl.isEmpty
                        ? Icon(
                      Icons.pets,
                      size: size.width * 0.12,
                      color: Colors.white,
                    )
                        : null,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isExpanded
                        ? Container(
                            width: size.width * 0.5,
                            padding: EdgeInsets.only(left: size.width * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.pet.name,
                                  style: GoogleFonts.inknutAntiqua(
                                    fontSize: size.width * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : const Color(0xFF394957),
                                  ),
                                ),
                                SizedBox(height: size.height * 0.01),
                                _buildPetInfoRow('Breed', widget.pet.breed, size),
                                _buildPetInfoRow('Birthday', _formatBirthday(widget.pet.birthday), size),
                                _buildPetInfoRow('Weight', '${widget.pet.weight} lbs', size),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              if (!_isExpanded) ...[
                SizedBox(height: size.height * 0.01),
                Text(
                  widget.pet.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inknutAntiqua(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF394957),
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF7FA8C7)
                  : const Color(0xFF7496B3),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: size.width * 0.035,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF394957),
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
                    // FIX: Check if it's a network URL (DB) or an Asset
                    image: pet.imageUrl.startsWith('http')
                        ? NetworkImage(pet.imageUrl)
                        : AssetImage(pet.imageUrl) as ImageProvider,
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