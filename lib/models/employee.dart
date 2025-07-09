class Employee {
  final int id;
  final String name;
  final String position;
  final String phone;
  final String email;
  final bool isActive;
  final DateTime? hireDate;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.phone,
    required this.email,
    required this.isActive,
    this.hireDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] ?? true,
      hireDate: json['hire_date'] != null 
          ? DateTime.tryParse(json['hire_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'phone': phone,
      'email': email,
      'is_active': isActive,
      'hire_date': hireDate?.toIso8601String(),
    };
  }
} 
 
 
 
 