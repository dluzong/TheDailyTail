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
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 200,
            width: 200,
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
                ? const Icon(
                    Icons.pets,
                    size: 60,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            pet.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}