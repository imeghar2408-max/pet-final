import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';
import '../../widgets/petcare_card.dart';

class PetDetailScreen extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onUpdated;

  const PetDetailScreen({super.key, required this.pet, this.onUpdated});

  String _getEmoji(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return '🐶';
      case 'cat':
        return '🐱';
      case 'rabbit':
        return '🐰';
      case 'bird':
        return '🦜';
      default:
        return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: Text(pet.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Pet Card
            PetCareCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: PetColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getEmoji(pet.species),
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: PetColors.dark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet.breed != null && pet.breed!.isNotEmpty
                        ? '${pet.breed} • ${pet.species}'
                        : pet.species,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: PetColors.darkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: PetCareCard(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Column(
                      children: [
                        const Icon(Icons.cake_rounded, color: PetColors.primary, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          pet.age != null ? '${pet.age} yrs' : 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PetColors.dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Age',
                          style: TextStyle(fontSize: 12, color: PetColors.darkLight),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PetCareCard(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Column(
                      children: [
                        const Icon(Icons.monitor_weight_rounded, color: PetColors.sage, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          pet.weightKg != null ? '${pet.weightKg} kg' : 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PetColors.dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Weight',
                          style: TextStyle(fontSize: 12, color: PetColors.darkLight),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PetCareCard(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Column(
                      children: [
                        const Icon(Icons.pets_rounded, color: PetColors.sky, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          pet.species,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PetColors.dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Species',
                          style: TextStyle(fontSize: 12, color: PetColors.darkLight),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Care Notes Section
            PetCareCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notes_rounded, color: PetColors.dark, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Care Instructions & Medical Notes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PetColors.dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pet.notes != null && pet.notes!.isNotEmpty
                        ? pet.notes!
                        : 'No special care instructions specified yet. You can update this to mention allergies, behavior, or favorite treats.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: pet.notes != null && pet.notes!.isNotEmpty
                          ? PetColors.dark
                          : PetColors.darkMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Medical & Vaccination Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PetColors.borderSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PetColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.health_and_safety_outlined, color: PetColors.sage, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vaccination & Health Passports',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PetColors.dark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Digital veterinary records and vaccination reminders are scheduled for a future platform update.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: PetColors.darkMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
