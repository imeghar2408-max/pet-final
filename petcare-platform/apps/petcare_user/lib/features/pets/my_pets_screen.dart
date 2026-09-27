import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/petcare_card.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  List<Pet> _pets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await UserApiService().getPets();
      if (mounted) {
        setState(() {
          _pets = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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
        title: const Text('My Pets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: PetColors.primary),
            tooltip: 'Add Pet',
            onPressed: () async {
              final added = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddPetScreen()),
              );
              if (added == true) _loadPets();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(PetColors.primary),
        ),
      );
    }

    if (_error != null) {
      return EmptyStateView(
        icon: Icons.error_outline_rounded,
        iconColor: PetColors.error,
        title: 'Could not load pets',
        description: _error!,
        buttonLabel: 'Try Again',
        onButtonPressed: _loadPets,
      );
    }

    if (_pets.isEmpty) {
      return EmptyStateView(
        icon: Icons.pets_rounded,
        iconColor: PetColors.primary,
        title: 'No pets added yet',
        description: 'Add your pets so verified caretakers know their breed, age, and special instructions.',
        buttonLabel: 'Add Your First Pet',
        onButtonPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddPetScreen()),
          );
          if (added == true) _loadPets();
        },
      );
    }

    return RefreshIndicator(
      color: PetColors.primary,
      onRefresh: _loadPets,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: _pets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final pet = _pets[i];
          return PetCareCard(
            hasShadow: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: PetColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getEmoji(pet.species),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PetColors.dark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pet.breed != null && pet.breed!.isNotEmpty
                            ? '${pet.breed} • ${pet.species}'
                            : pet.species,
                        style: const TextStyle(
                          fontSize: 13,
                          color: PetColors.darkMuted,
                        ),
                      ),
                      if (pet.age != null || pet.weightKg != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (pet.age != null) '${pet.age} yrs old',
                            if (pet.weightKg != null) '${pet.weightKg} kg',
                          ].join(' • '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: PetColors.darkLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: PetColors.darkLight,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
