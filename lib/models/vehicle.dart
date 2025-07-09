class VehiclePhoto {
  final int id;
  final String photo;
  final String? description;
  final bool isMain;
  final String uploadedAt;

  VehiclePhoto({
    required this.id,
    required this.photo,
    this.description,
    required this.isMain,
    required this.uploadedAt,
  });

  factory VehiclePhoto.fromJson(Map<String, dynamic> json) {
    return VehiclePhoto(
      id: json['id'] ?? 0,
      photo: json['photo'] ?? '',
      description: json['description'],
      isMain: json['is_main'] ?? false,
      uploadedAt: json['uploaded_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photo': photo,
      'description': description,
      'is_main': isMain,
      'uploaded_at': uploadedAt,
    };
  }
}

class VehicleDriver {
  final int id;
  final String name;
  final String? phone;
  final String? photo;

  VehicleDriver({
    required this.id,
    required this.name,
    this.phone,
    this.photo,
  });

  factory VehicleDriver.fromJson(Map<String, dynamic> json) {
    return VehicleDriver(
      id: json['id'] ?? 0,
      name: '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      phone: json['phone'],
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'photo': photo,
    };
  }
}

class Vehicle {
  final int id;
  final String number;
  final String model;
  final String brand;
  final int year;
  final String status;
  final String statusDisplay;
  final String statusColor;
  final VehicleDriver? driver;
  final String? photoUrl;
  final List<VehiclePhoto> photos;
  final String? color;
  
  // Дополнительные поля для детального просмотра
  final String? vinNumber;
  final String? engineNumber;
  final String? chassisNumber;
  final double? engineCapacity;
  final String? fuelType;
  final String? fuelTypeDisplay;
  final double? length;
  final double? width;
  final double? height;
  final double? maxWeight;
  final double? cargoCapacity;
  final String? vehicleType;
  final String? vehicleTypeDisplay;
  final String? description;

  Vehicle({
    required this.id,
    required this.number,
    required this.model,
    required this.brand,
    required this.year,
    required this.status,
    required this.statusDisplay,
    required this.statusColor,
    this.driver,
    this.photoUrl,
    this.photos = const [],
    this.color,
    this.vinNumber,
    this.engineNumber,
    this.chassisNumber,
    this.engineCapacity,
    this.fuelType,
    this.fuelTypeDisplay,
    this.length,
    this.width,
    this.height,
    this.maxWeight,
    this.cargoCapacity,
    this.vehicleType,
    this.vehicleTypeDisplay,
    this.description,
  });

  // Вспомогательный метод для безопасного парсинга double значений
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Геттер для отображения статуса
  String get statusDisplayText {
    switch (status) {
      case 'ACTIVE':
        return 'Активен';
      case 'INACTIVE':
        return 'Неактивен';
      case 'MAINTENANCE':
        return 'На обслуживании';
      case 'IN_TRANSIT':
        return 'В пути';
      default:
        return 'Неизвестно';
    }
  }

  // Геттер для цвета статуса
  String get statusColorHex {
    switch (status) {
      case 'ACTIVE':
        return '#10B981'; // зеленый
      case 'IN_TRANSIT':
        return '#2679DB'; // синий
      case 'MAINTENANCE':
        return '#F59E0B'; // желтый
      case 'INACTIVE':
        return '#EF4444'; // красный
      default:
        return '#6B7280'; // серый
    }
  }

  // Геттер для отображения типа транспорта
  String get vehicleTypeDisplayText {
    switch (vehicleType) {
      case 'TRUCK':
        return 'Грузовой';
      case 'CAR':
        return 'Легковой';
      case 'SPECIAL':
        return 'Спецтехника';
      default:
        return 'Не указан';
    }
  }

  // Геттер для отображения типа топлива
  String get fuelTypeDisplayText {
    switch (fuelType) {
      case 'DIESEL':
        return 'Дизель';
      case 'PETROL':
        return 'Бензин';
      case 'GAS':
        return 'Газ';
      case 'HYBRID':
        return 'Гибрид';
      case 'ELECTRIC':
        return 'Электро';
      default:
        return 'Не указан';
    }
  }

  // Геттер для имени водителя
  String get driverName {
    return driver?.name ?? 'Не назначен';
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      number: json['number'] ?? '',
      model: json['model'] ?? '',
      brand: json['brand'] ?? '',
      year: json['year'] ?? 2020,
      status: json['status'] ?? 'ACTIVE',
      statusDisplay: json['status_display'] ?? 'Активен',
      statusColor: json['status_color'] ?? '#10B981',
      driver: json['driver_details'] != null ? VehicleDriver.fromJson(json['driver_details']) : null,
      photoUrl: json['main_photo_url'],
      photos: json['photos'] != null 
          ? (json['photos'] as List).map((photo) => VehiclePhoto.fromJson(photo)).toList()
          : [],
      color: json['color'],
      vinNumber: json['vin_number'],
      engineNumber: json['engine_number'],
      chassisNumber: json['chassis_number'],
      engineCapacity: _parseDouble(json['engine_capacity']),
      fuelType: json['fuel_type'],
      fuelTypeDisplay: json['fuel_type_display'],
      length: _parseDouble(json['length']),
      width: _parseDouble(json['width']),
      height: _parseDouble(json['height']),
      maxWeight: _parseDouble(json['max_weight']),
      cargoCapacity: _parseDouble(json['cargo_capacity']),
      vehicleType: json['vehicle_type'],
      vehicleTypeDisplay: json['vehicle_type_display'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'model': model,
      'brand': brand,
      'year': year,
      'status': status,
      'status_display': statusDisplay,
      'status_color': statusColor,
      'driver': driver?.toJson(),
      'photo': photoUrl,
      'color': color,
      'vin_number': vinNumber,
      'engine_number': engineNumber,
      'chassis_number': chassisNumber,
      'engine_capacity': engineCapacity,
      'fuel_type': fuelType,
      'fuel_type_display': fuelTypeDisplay,
      'length': length,
      'width': width,
      'height': height,
      'max_weight': maxWeight,
      'cargo_capacity': cargoCapacity,
      'vehicle_type': vehicleType,
      'vehicle_type_display': vehicleTypeDisplay,
      'description': description,
    };
  }

  // Геттеры для удобства
  String get fullName => '$brand $model ($number)';
} 
 
 
 
 