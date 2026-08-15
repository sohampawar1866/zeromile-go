// lib/utils/nagpur_poi_registry.dart

/// Model representing a pre-indexed Nagpur Point of Interest (POI).
class NagpurPoi {
  final String name;
  final double latitude;
  final double longitude;
  final List<String> tags;
  final String category; // 'COLLEGE', 'LANDMARK', 'AREA', 'TRANSIT'

  const NagpurPoi({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.tags,
    this.category = 'LANDMARK',
  });
}

/// Comprehensive Pre-indexed Nagpur College, Area & Landmark Registry
/// Derived from official Nagpur city survey and map-ui-idea specification.
class NagpurPoiRegistry {
  static const List<NagpurPoi> registry = [
    // Major Engineering & Medical Colleges
    NagpurPoi(
      name: 'VNIT Campus Main Gate, South Ambazari Rd',
      latitude: 21.1280,
      longitude: 79.0520,
      tags: ['vnit', 'college', 'vnit campus', 'vnit gate', 'engineering', 'ambazari'],
      category: 'COLLEGE',
    ),
    NagpurPoi(
      name: 'YCCE Engineering College Campus, Hingna Rd',
      latitude: 21.1020,
      longitude: 78.9780,
      tags: ['ycce', 'ycce college', 'hingna', 'engineering', 'wanadongri'],
      category: 'COLLEGE',
    ),
    NagpurPoi(
      name: 'Shri Ramdeobaba College of Engg (RCOEM), Katol Rd',
      latitude: 21.1760,
      longitude: 79.0620,
      tags: ['ramdeobaba', 'rcoem', 'katol road', 'college', 'engineering', 'gitikhadan'],
      category: 'COLLEGE',
    ),
    NagpurPoi(
      name: 'GMC Government Medical College & Hospital, Ajni',
      latitude: 21.1350,
      longitude: 79.0920,
      tags: ['gmc', 'medical college', 'hospital', 'ajni', 'medical square'],
      category: 'COLLEGE',
    ),
    NagpurPoi(
      name: 'GCOEN Government College of Engineering, Sector 27',
      latitude: 21.0950,
      longitude: 79.0550,
      tags: ['gcoen', 'government engineering', 'college', 'mihan', 'khapri'],
      category: 'COLLEGE',
    ),
    NagpurPoi(
      name: 'Law College Square Junction, Amravati Rd',
      latitude: 21.1390,
      longitude: 79.0680,
      tags: ['law college', 'law college sq', 'square', 'amravati road'],
      category: 'COLLEGE',
    ),
    NagpurPoi(
      name: 'Hislop College Campus, Civil Lines',
      latitude: 21.1490,
      longitude: 79.0720,
      tags: ['hislop', 'hislop college', 'civil lines', 'temple bazaar'],
      category: 'COLLEGE',
    ),
    NagpurPoi(
      name: 'CP & Berar College, Tulsibagh Mahal',
      latitude: 21.1410,
      longitude: 79.1050,
      tags: ['cp and berar', 'cp berar', 'college', 'mahal', 'tulsibagh'],
      category: 'COLLEGE',
    ),

    // Famous Landmarks & Attractions
    NagpurPoi(
      name: 'Zero Mile Freedom Park, Wardha Rd',
      latitude: 21.1458,
      longitude: 79.0882,
      tags: ['zero mile', 'freedom park', 'heritage', 'monument', 'flag off', 'start point'],
      category: 'LANDMARK',
    ),
    NagpurPoi(
      name: 'Futala Lake Waterfront Promenade',
      latitude: 21.1550,
      longitude: 79.0450,
      tags: ['futala', 'futala lake', 'lake', 'waterfront', 'fountain'],
      category: 'LANDMARK',
    ),
    NagpurPoi(
      name: 'Ambazari Lake Garden Main Gate',
      latitude: 21.1250,
      longitude: 79.0480,
      tags: ['ambazari', 'ambazari lake', 'garden', 'boating'],
      category: 'LANDMARK',
    ),
    NagpurPoi(
      name: 'Deekshabhoomi Stupa Monument',
      latitude: 21.1290,
      longitude: 79.0670,
      tags: ['deekshabhoomi', 'stupa', 'monument', 'finish line', 'ramdas peth'],
      category: 'LANDMARK',
    ),
    NagpurPoi(
      name: 'Sitabuldi Fort & Metro Interchange',
      latitude: 21.1460,
      longitude: 79.0820,
      tags: ['sitabuldi', 'fort', 'metro', 'market', 'interchange'],
      category: 'LANDMARK',
    ),
    NagpurPoi(
      name: 'Seminary Hills Botanic Garden Gate',
      latitude: 21.1620,
      longitude: 79.0620,
      tags: ['seminary hills', 'garden', 'air force', 'hill'],
      category: 'LANDMARK',
    ),

    // Prominent Areas & Junctions
    NagpurPoi(
      name: 'Dharampeth Main Commercial Market',
      latitude: 21.1380,
      longitude: 79.0620,
      tags: ['dharampeth', 'market', 'area', 'coffee house', 'zenda chowk'],
      category: 'AREA',
    ),
    NagpurPoi(
      name: 'Sadar Residency Road Bazaar',
      latitude: 21.1590,
      longitude: 79.0800,
      tags: ['sadar', 'sadar bazaar', 'residency road', 'area'],
      category: 'AREA',
    ),
    NagpurPoi(
      name: 'Manewada Ring Road Square',
      latitude: 21.1080,
      longitude: 79.0980,
      tags: ['manewada', 'square', 'ring road', 'area'],
      category: 'AREA',
    ),
    NagpurPoi(
      name: 'Medical Square Junction, Ajni Rd',
      latitude: 21.1320,
      longitude: 79.0950,
      tags: ['medical square', 'medical sq', 'junction', 'ajni'],
      category: 'AREA',
    ),
    NagpurPoi(
      name: 'Shankar Nagar Square Metro Station',
      latitude: 21.1310,
      longitude: 79.0600,
      tags: ['shankar nagar', 'square', 'metro', 'water point'],
      category: 'TRANSIT',
    ),
    NagpurPoi(
      name: 'Nagpur Railway Station West Gate',
      latitude: 21.1520,
      longitude: 79.0880,
      tags: ['railway station', 'station', 'central railway', 'west gate'],
      category: 'TRANSIT',
    ),
  ];

  /// Searches the pre-indexed registry for matches against [query].
  static List<NagpurPoi> search(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    return registry.where((poi) {
      if (poi.name.toLowerCase().contains(clean)) return true;
      return poi.tags.any((tag) => tag.contains(clean));
    }).toList();
  }

  /// Finds the closest landmark within threshold meters.
  static NagpurPoi? findClosest(double latitude, double longitude, {double maxDistanceKm = 1.0}) {
    NagpurPoi? closest;
    double minDistance = double.infinity;

    for (final poi in registry) {
      final dist = _calculateDistanceKm(latitude, longitude, poi.latitude, poi.longitude);
      if (dist < minDistance && dist <= maxDistanceKm) {
        minDistance = dist;
        closest = poi;
      }
    }

    return closest;
  }

  static double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    final dLat = (lat2 - lat1) * 111.0;
    final dLon = (lon2 - lon1) * 111.0 * 0.93;
    return (dLat * dLat + dLon * dLon);
  }
}
