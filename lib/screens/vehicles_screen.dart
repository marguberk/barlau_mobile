import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/app_header.dart';
import 'vehicle_detail_screen.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      const String url = 'https://barlau.org/api/vehicles/';
      print('Загружаем грузовики с: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Статус ответа: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> vehiclesData = data['results'] ?? [];
        
        setState(() {
          _vehicles = vehiclesData.map((vehicle) {
            // Определяем статус и цвет
            String status;
            Color statusColor;
            
            // Пока простая логика - позже добавим проверку активных заездов
            switch (vehicle['status']) {
              case 'ACTIVE':
                status = 'Активен';
                statusColor = const Color(0xFF10B981);
                break;
              default:
                status = 'Неактивен';
                statusColor = const Color(0xFF6B7280);
            }

            // Получаем главное фото
            String? mainPhotoUrl = vehicle['main_photo_url'];
            if (mainPhotoUrl != null && !mainPhotoUrl.startsWith('http')) {
              mainPhotoUrl = 'https://barlau.org$mainPhotoUrl';
            }

            return {
              'id': vehicle['id'],
              'number': vehicle['number'] ?? 'Не указан',
              'brand': vehicle['brand'] ?? '',
              'model': vehicle['model'] ?? '',
              'year': vehicle['year']?.toString() ?? '',
              'driver': vehicle['driver_details'] != null 
                  ? '${vehicle['driver_details']['first_name'] ?? ''} ${vehicle['driver_details']['last_name'] ?? ''}'.trim()
                  : null,
              'driverPhone': vehicle['driver_details']?['phone'],
              'status': status,
              'statusColor': statusColor,
              'main_photo_url': mainPhotoUrl,
              'cargo_capacity': vehicle['cargo_capacity']?.toString(),
              'fuel_type': vehicle['fuel_type'],
            };
          }).toList();
          _isLoading = false;
        });
        
        print('Загружено ${_vehicles.length} грузовиков');
      } else {
        print('Ошибка загрузки грузовиков: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке грузовиков: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showVehicleDetails(Map<String, dynamic> vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailScreen(vehicle: vehicle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Грузовики',
        isConnected: true,
        onNotificationTap: () {
          // Обработка нажатия на уведомления
        },
        onProfileTap: () {
          // Переход к профилю
        },
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2679DB),
              ),
            )
          : _vehicles.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 64,
                        color: Color(0xFF6B7280),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Нет грузовиков',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Грузовики не найдены',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000).withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _showVehicleDetails(vehicle),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Stack(
                            children: [
                              Row(
                                children: [
                                  // Изображение грузовика
                                  Container(
                                    width: 100,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: vehicle['main_photo_url'] != null && vehicle['main_photo_url'].isNotEmpty
                                          ? Image.network(
                                              vehicle['main_photo_url'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.local_shipping,
                                                  size: 32,
                                                  color: Color(0xFF2679DB),
                                                );
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF2679DB),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.local_shipping,
                                              size: 32,
                                              color: Color(0xFF2679DB),
                                            ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  // Информация о грузовике
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Номер грузовика
                                        Text(
                                          vehicle['number'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 4),
                                        
                                        // Модель грузовика
                                        Text(
                                          '${vehicle['brand']} ${vehicle['model']} ${vehicle['year'].isNotEmpty ? '(${vehicle['year']})' : ''}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        // Водитель
                                        if (vehicle['driver'] != null && vehicle['driver'].isNotEmpty) ...[
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person_outline,
                                                size: 16,
                                                color: Color(0xFF6B7280),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  vehicle['driver'],
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Статус в правом верхнем углу
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: vehicle['statusColor'].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: vehicle['statusColor'].withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    vehicle['status'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: vehicle['statusColor'],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 
 