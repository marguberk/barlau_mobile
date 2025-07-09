enum LocationType {
  vehicle,
  depot,
  warehouse,
  gas_station,
  client,
  service;

  String get name {
    switch (this) {
      case LocationType.vehicle:
        return 'vehicle';
      case LocationType.depot:
        return 'depot';
      case LocationType.warehouse:
        return 'warehouse';
      case LocationType.gas_station:
        return 'gas_station';
      case LocationType.client:
        return 'client';
      case LocationType.service:
        return 'service';
    }
  }

  String get displayName {
    switch (this) {
      case LocationType.vehicle:
        return 'Транспорт';
      case LocationType.depot:
        return 'База';
      case LocationType.warehouse:
        return 'Склад';
      case LocationType.gas_station:
        return 'АЗС';
      case LocationType.client:
        return 'Клиент';
      case LocationType.service:
        return 'Сервис';
    }
  }
}

class MapLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final LocationType type;
  final String? description;
  final String? vehicleId;

  MapLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.description,
    this.vehicleId,
  });

  factory MapLocation.fromJson(Map<String, dynamic> json) {
    return MapLocation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      type: _parseLocationType(json['type']?.toString()),
      description: json['description']?.toString(),
      vehicleId: json['vehicleId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'description': description,
      'vehicleId': vehicleId,
    };
  }

  static LocationType _parseLocationType(String? typeString) {
    switch (typeString?.toLowerCase()) {
      case 'vehicle':
      case 'транспорт':
        return LocationType.vehicle;
      case 'depot':
      case 'база':
        return LocationType.depot;
      case 'warehouse':
      case 'склад':
        return LocationType.warehouse;
      case 'gas_station':
      case 'азс':
        return LocationType.gas_station;
      case 'client':
      case 'клиент':
        return LocationType.client;
      case 'service':
      case 'сервис':
        return LocationType.service;
      default:
        return LocationType.vehicle;
    }
  }
}

extension LocationTypeExtension on LocationType {
  String get iconPath {
    switch (this) {
      case LocationType.warehouse:
        return 'assets/images/warehouse_marker.png';
      case LocationType.vehicle:
        return 'assets/images/truck_marker.png';
      case LocationType.depot:
        return 'assets/images/depot_marker.png';
      case LocationType.client:
        return 'assets/images/client_marker.png';
      case LocationType.gas_station:
        return 'assets/images/gas_marker.png';
      case LocationType.service:
        return 'assets/images/service_marker.png';
    }
  }
} 
 
 
 
 