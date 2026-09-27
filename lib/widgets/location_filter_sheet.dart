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
      useSafeArea: true,
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
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                    color: isDark ? const Color(0xFF3E4F41) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3520)
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.near_me,
                      color: isDark
                          ? const Color(0xFF86E875)
                          : theme.colorScheme.primary,
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
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Twoja lokalizacja: ${provider.currentCity}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
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
                      child: Text(
                        'Wyczyść',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF86E875)
                              : const Color(0xFF1E5128),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Scrollable body containing all sections
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Promień wyszukiwania
                      Text(
                        'Promień wyszukiwania od Ciebie:',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
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
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
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
                            selectedColor: isDark
                                ? const Color(0xFF2E6B32)
                                : const Color(0xFFD6E8D5),
                            labelStyle: TextStyle(
                              color: (provider.selectedCityFilter == null ||
                                      provider.selectedCityFilter == 'Wszystkie')
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade800),
                              fontWeight: (provider.selectedCityFilter == null ||
                                      provider.selectedCityFilter == 'Wszystkie')
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) provider.setCityFilter(null);
                            },
                          ),
                          ...DistanceService.popularCities.map((c) {
                            final isSelected =
                                provider.selectedCityFilter == c.name;
                            return ChoiceChip(
                              label: Text(c.name),
                              selected: isSelected,
                              selectedColor: isDark
                                  ? const Color(0xFF2E6B32)
                                  : const Color(0xFFD6E8D5),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade800),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                provider.setCityFilter(selected ? c.name : null);
                              },
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Divider(
                        color: isDark
                            ? const Color(0xFF28352A)
                            : Colors.grey.shade200,
                      ),

                      // Section 3: Zmień swoją bieżącą lokalizację (GPS / miasto)
                      Row(
                        children: [
                          Icon(Icons.my_location,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFF86E875)
                                  : Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Zmień Twoją bazową lokalizację GPS:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade300 : null,
                              ),
                            ),
                          ),
                          PopupMenuButton<CityLocation>(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E3520)
                                    : Colors.blueGrey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2E5E33)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    provider.currentCity,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down,
                                      size: 18,
                                      color: isDark
                                          ? const Color(0xFF86E875)
                                          : Colors.black87),
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
                            itemBuilder: (ctx) =>
                                DistanceService.popularCities.map((c) {
                              return PopupMenuItem(
                                value: c,
                                child: Text('${c.name} (${c.region})'),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Fixed bottom button - ALWAYS visible above the navigation bar / bottom insets
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF1E5128),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text(
                    'Zastosuj filtry',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
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
    final isDark = theme.brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor:
          isDark ? const Color(0xFF2E6B32) : const Color(0xFFD6E8D5),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
