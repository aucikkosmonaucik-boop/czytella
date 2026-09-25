import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/czytella_provider.dart';
import '../services/distance_service.dart';

class LocationFilterSheet extends StatelessWidget {
  const LocationFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const LocationFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CzytellaProvider>();
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.near_me,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtr lokalizacji i odległości',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Twoja lokalizacja: ${provider.currentCity}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.radiusFilterKm != null ||
                  provider.selectedCityFilter != null)
                TextButton(
                  onPressed: () {
                    provider.setRadiusFilter(null);
                    provider.setCityFilter(null);
                  },
                  child: const Text('Wyczyść'),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 1: Promień wyszukiwania (Explicit request: "w promieniu 5 km")
          Text(
            'Promień wyszukiwania od Ciebie:',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRadiusChip(
                context: context,
                label: '🎯 W promieniu 5 km',
                radius: 5.0,
                isSelected: provider.radiusFilterKm == 5.0,
                onSelected: () => provider.setRadiusFilter(5.0),
              ),
              _buildRadiusChip(
                context: context,
                label: '10 km',
                radius: 10.0,
                isSelected: provider.radiusFilterKm == 10.0,
                onSelected: () => provider.setRadiusFilter(10.0),
              ),
              _buildRadiusChip(
                context: context,
                label: '25 km',
                radius: 25.0,
                isSelected: provider.radiusFilterKm == 25.0,
                onSelected: () => provider.setRadiusFilter(25.0),
              ),
              _buildRadiusChip(
                context: context,
                label: 'Bez limitu km',
                radius: null,
                isSelected: provider.radiusFilterKm == null,
                onSelected: () => provider.setRadiusFilter(null),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Section 2: Filtrowanie po mieście
          Text(
            'Filtruj po mieście oferty:',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Wszystkie miasta'),
                selected: provider.selectedCityFilter == null ||
                    provider.selectedCityFilter == 'Wszystkie',
                onSelected: (selected) {
                  if (selected) provider.setCityFilter(null);
                },
              ),
              ...DistanceService.popularCities.map((c) {
                final isSelected = provider.selectedCityFilter == c.name;
                return ChoiceChip(
                  label: Text(c.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    provider.setCityFilter(selected ? c.name : null);
                  },
                );
              }),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),

          // Section 3: Zmień swoją bieżącą lokalizację (GPS / miasto)
          Row(
            children: [
              const Icon(Icons.my_location, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Zmień Twoją bazową lokalizację GPS:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<CityLocation>(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.currentCity,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
                onSelected: (city) {
                  provider.setUserLocation(
                    cityName: city.name,
                    latitude: city.latitude,
                    longitude: city.longitude,
                  );
                },
                itemBuilder: (ctx) => DistanceService.popularCities.map((c) {
                  return PopupMenuItem(
                    value: c,
                    child: Text('${c.name} (${c.region})'),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Zastosuj filtry'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusChip({
    required BuildContext context,
    required String label,
    required double? radius,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
