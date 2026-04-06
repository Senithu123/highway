class TollGate {
  const TollGate({
    required this.id,
    required this.name,
    required this.highway,
    required this.kmMarker,
  });

  final String id;
  final String name;
  final String highway;
  final double kmMarker;

  String get displayLabel => '$name ($highway)';
  String get qrPayload => 'HTP_GATE::$id::$name::$highway';
  String get qrLink => 'https://highwaytoll.app/gate/$id';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'highway': highway,
      'kmMarker': kmMarker,
    };
  }

  TollGate copyWith({
    String? id,
    String? name,
    String? highway,
    double? kmMarker,
  }) {
    return TollGate(
      id: id ?? this.id,
      name: name ?? this.name,
      highway: highway ?? this.highway,
      kmMarker: kmMarker ?? this.kmMarker,
    );
  }

  factory TollGate.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return TollGate(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      highway: (data['highway'] as String? ?? '').trim(),
      kmMarker: (data['kmMarker'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TollPricingConfig {
  const TollPricingConfig({
    required this.baseFare,
    required this.pricePerKm,
    required this.minimumFare,
  });

  final double baseFare;
  final double pricePerKm;
  final double minimumFare;

  Map<String, dynamic> toMap() {
    return {
      'baseFare': baseFare,
      'pricePerKm': pricePerKm,
      'minimumFare': minimumFare,
    };
  }

  factory TollPricingConfig.fromMap(Map<String, dynamic> data) {
    return TollPricingConfig(
      baseFare: (data['baseFare'] as num?)?.toDouble() ?? 70,
      pricePerKm: (data['pricePerKm'] as num?)?.toDouble() ?? 6.5,
      minimumFare: (data['minimumFare'] as num?)?.toDouble() ?? 120,
    );
  }
}

class TollGateCatalog {
  TollGateCatalog._();

  static const List<TollGate> gates = [
    TollGate(id: 'E01-001', name: 'Kottawa', highway: 'E01', kmMarker: 0),
    TollGate(id: 'E01-002', name: 'Kahathuduwa', highway: 'E01', kmMarker: 6),
    TollGate(id: 'E01-003', name: 'Gelanigama', highway: 'E01', kmMarker: 20),
    TollGate(id: 'E01-004', name: 'Dodangoda', highway: 'E01', kmMarker: 32),
    TollGate(id: 'E01-005', name: 'Welipenna', highway: 'E01', kmMarker: 44),
    TollGate(
      id: 'E01-006',
      name: 'Kurundugahahetekma',
      highway: 'E01',
      kmMarker: 60,
    ),
    TollGate(id: 'E01-007', name: 'Baddegama', highway: 'E01', kmMarker: 74),
    TollGate(id: 'E01-008', name: 'Pinnaduwa', highway: 'E01', kmMarker: 86),
    TollGate(id: 'E01-009', name: 'Imaduwa', highway: 'E01', kmMarker: 95),
    TollGate(id: 'E01-010', name: 'Kokmaduwa', highway: 'E01', kmMarker: 108),
    TollGate(
      id: 'E01-011',
      name: 'Godagama',
      highway: 'E01',
      kmMarker: 118,
    ),
    TollGate(
      id: 'E01-012',
      name: 'Beliatta',
      highway: 'E01',
      kmMarker: 132,
    ),
    TollGate(
      id: 'E01-013',
      name: 'Bedigama',
      highway: 'E01',
      kmMarker: 141,
    ),
    TollGate(
      id: 'E01-014',
      name: 'Kasagala',
      highway: 'E01',
      kmMarker: 150,
    ),
    TollGate(
      id: 'E01-015',
      name: 'Hambantota',
      highway: 'E01',
      kmMarker: 158,
    ),
  ];

  static const TollPricingConfig defaultPricing = TollPricingConfig(
    baseFare: 70,
    pricePerKm: 6.5,
    minimumFare: 120,
  );

  static List<String> get gateNames =>
      gates.map((gate) => gate.name).toList(growable: false);

  static TollGate? byName(
    String name, {
    List<TollGate>? inList,
  }) {
    final trimmed = name.trim().toLowerCase();
    for (final gate in inList ?? gates) {
      if (gate.name.toLowerCase() == trimmed) {
        return gate;
      }
    }
    return null;
  }

  static TollGate? fromQrPayload(
    String rawValue, {
    List<TollGate>? inList,
  }) {
    final normalized = rawValue.trim().toLowerCase();
    for (final gate in inList ?? gates) {
      if (normalized == gate.name.toLowerCase() ||
          normalized == gate.qrPayload.toLowerCase() ||
          normalized.contains(gate.name.toLowerCase()) ||
          normalized.contains(gate.id.toLowerCase())) {
        return gate;
      }
    }
    return null;
  }
}
