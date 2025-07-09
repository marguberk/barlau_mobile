class Trip {
  final int id;
  final String title;
  final String status;
  final bool requiresChecklist;
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleNumber;
  final String? trailerNumber;
  final String driverFirstName;
  final String driverLastName;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final String startAddress;
  final String endAddress;
  final String cargoDescription;
  final String cargoType;
  final double? cargoWeight;
  final double? freightAmount;
  final String freightPaymentType;
  final DateTime plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final String notes;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.title,
    required this.status,
    required this.requiresChecklist,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleNumber,
    this.trailerNumber,
    required this.driverFirstName,
    required this.driverLastName,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.startAddress,
    required this.endAddress,
    required this.cargoDescription,
    required this.cargoType,
    this.cargoWeight,
    this.freightAmount,
    required this.freightPaymentType,
    required this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    required this.notes,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'] ?? 'PLANNED',
      requiresChecklist: json['requires_checklist'] ?? true,
      vehicleBrand: json['vehicle']?['brand'] ?? '',
      vehicleModel: json['vehicle']?['model'] ?? '',
      vehicleNumber: json['vehicle']?['number'] ?? '',
      trailerNumber: json['trailer']?['number'],
      driverFirstName: json['driver']?['first_name'] ?? '',
      driverLastName: json['driver']?['last_name'] ?? '',
      startLatitude: (json['start_latitude'] ?? 0.0).toDouble(),
      startLongitude: (json['start_longitude'] ?? 0.0).toDouble(),
      endLatitude: (json['end_latitude'] ?? 0.0).toDouble(),
      endLongitude: (json['end_longitude'] ?? 0.0).toDouble(),
      startAddress: json['start_address'] ?? '',
      endAddress: json['end_address'] ?? '',
      cargoDescription: json['cargo_description'] ?? '',
      cargoType: json['cargo_type'] ?? 'OTHER',
      cargoWeight: json['cargo_weight']?.toDouble(),
      freightAmount: json['freight_amount']?.toDouble(),
      freightPaymentType: json['freight_payment_type'] ?? 'TRANSFER',
      plannedStartDate: json['planned_start_date'] != null 
          ? DateTime.parse(json['planned_start_date'])
          : DateTime.now(),
      plannedEndDate: json['planned_end_date'] != null 
          ? DateTime.parse(json['planned_end_date'])
          : null,
      actualStartDate: json['actual_start_date'] != null 
          ? DateTime.parse(json['actual_start_date'])
          : null,
      actualEndDate: json['actual_end_date'] != null 
          ? DateTime.parse(json['actual_end_date'])
          : null,
      notes: json['notes'] ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'requires_checklist': requiresChecklist,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'start_address': startAddress,
      'end_address': endAddress,
      'cargo_description': cargoDescription,
      'cargo_type': cargoType,
      'cargo_weight': cargoWeight,
      'freight_amount': freightAmount,
      'freight_payment_type': freightPaymentType,
      'planned_start_date': plannedStartDate.toIso8601String(),
      'planned_end_date': plannedEndDate?.toIso8601String(),
      'actual_start_date': actualStartDate?.toIso8601String(),
      'actual_end_date': actualEndDate?.toIso8601String(),
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'PLANNED':
        return 'Запланирована';
      case 'PENDING_CHECKLIST':
        return 'Ожидает чек-лист';
      case 'READY':
        return 'Готова к отправке';
      case 'ACTIVE':
        return 'В пути';
      case 'COMPLETED':
        return 'Завершена';
      case 'CANCELLED':
        return 'Отменена';
      default:
        return 'Неизвестно';
    }
  }

  String get route => '$startAddress → $endAddress';
  
  String get driverName => '$driverFirstName $driverLastName';
  
  String get vehicleInfo => '$vehicleBrand $vehicleModel ($vehicleNumber)';
  
  String get cargoTypeDisplay {
    switch (cargoType) {
      case 'CUSTOMS':
        return 'Растаможка';
      case 'DIRECT':
        return 'Прямой склад';
      case 'OTHER':
        return 'Прочее';
      default:
        return cargoType;
    }
  }
  
  String get freightPaymentTypeDisplay {
    switch (freightPaymentType) {
      case 'CASH':
        return 'Наличные';
      case 'TRANSFER':
        return 'Перечисление';
      default:
        return freightPaymentType;
    }
  }
} 
 
 
 
 