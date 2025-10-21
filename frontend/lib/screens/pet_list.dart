import 'dart:math';
import 'package:flutter/material.dart';

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
    // Make size responsive so PetList fits inside GridView cells and the carousel
    return LayoutBuilder(
      builder: (context, constraints) {
        // choose a size that's at most 160 but no larger than the available width
        final double size = min(160.0, constraints.maxWidth == double.infinity ? 160.0 : constraints.maxWidth);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: size,
                width: size,
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
                        size: max(36.0, size * 0.3),
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: size,
                child: Text(
                  pet.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
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