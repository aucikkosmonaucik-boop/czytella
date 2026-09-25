import 'dart:math' as math;

class CityLocation {
  final String name;
  final String region;
  final double latitude;
  final double longitude;

  const CityLocation({
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
  });
}

class DistanceService {
  /// Preset Polish cities with central coordinates
  static const List<CityLocation> popularCities = [
    CityLocation(
      name: 'Warszawa',
      region: 'mazowieckie',
      latitude: 52.2297,
      longitude: 21.0122,
    ),
    CityLocation(
      name: 'Kraków',
      region: 'małopolskie',
      latitude: 50.0647,
      longitude: 19.9450,
    ),
    CityLocation(
      name: 'Wrocław',
      region: 'dolnośląskie',
      latitude: 51.1079,
      longitude: 17.0385,
    ),
    CityLocation(
      name: 'Poznań',
      region: 'wielkopolskie',
      latitude: 52.4064,
      longitude: 16.9252,
    ),
    CityLocation(
      name: 'Gdańsk',
      region: 'pomorskie',
      latitude: 54.3520,
      longitude: 18.6466,
    ),
    CityLocation(
      name: 'Łódź',
      region: 'łódzkie',
      latitude: 51.7592,
      longitude: 19.4560,
    ),
    CityLocation(
      name: 'Katowice',
      region: 'śląskie',
      latitude: 50.2649,
      longitude: 19.0238,
    ),
    CityLocation(
      name: 'Lublin',
      region: 'lubelskie',
      latitude: 51.2465,
      longitude: 22.5684,
    ),
    CityLocation(
      name: 'Szczecin',
      region: 'zachodniopomorskie',
      latitude: 53.4285,
      longitude: 14.5528,
    ),
    CityLocation(
      name: 'Toruń',
      region: 'kujawsko-pomorskie',
      latitude: 53.0138,
      longitude: 18.5984,
    ),
    CityLocation(
      name: 'Białystok',
      region: 'podlaskie',
      latitude: 53.1325,
      longitude: 23.1688,
    ),
    CityLocation(
      name: 'Rzeszów',
      region: 'podkarpackie',
      latitude: 50.0412,
      longitude: 21.9991,
    ),
    CityLocation(
      name: 'Kielce',
      region: 'świętokrzyskie',
      latitude: 50.8661,
      longitude: 20.6286,
    ),
    CityLocation(
      name: 'Olsztyn',
      region: 'warmińsko-mazurskie',
      latitude: 53.7784,
      longitude: 20.4801,
    ),
    CityLocation(
      name: 'Zielona Góra',
      region: 'lubuskie',
      latitude: 51.9356,
      longitude: 15.5062,
    ),
    CityLocation(
      name: 'Opole',
      region: 'opolskie',
      latitude: 50.6751,
      longitude: 17.9213,
    ),
    CityLocation(
      name: 'Bydgoszcz',
      region: 'kujawsko-pomorskie',
      latitude: 53.1235,
      longitude: 18.0084,
    ),
    CityLocation(
      name: 'Gorzów Wielkopolski',
      region: 'lubuskie',
      latitude: 52.7325,
      longitude: 15.2369,
    ),
  ];

  /// Calculates the great-circle distance between two points in kilometers
  /// using the Haversine formula.
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Formats distance into friendly Polish label
  static String formatDistance(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m stąd';
    } else if (km < 10.0) {
      return '${km.toStringAsFixed(1)} km stąd';
    } else {
      return '${km.round()} km stąd';
    }
  }

  /// Find nearest city from presets
  static CityLocation findCityByName(String name) {
    return popularCities.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => popularCities.first,
    );
  }
}
