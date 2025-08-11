import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/app_header.dart';
import '../components/svg_icon.dart';
import '../services/api_service.dart';
import 'trip_details_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Фильтры для третьей вкладки
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedDriver;
  String? _selectedVehicle;
  
  // Реальные данные заездов
  List<Map<String, dynamic>> _trips = [];
  List<String> _drivers = [];
  List<String> _vehicles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.getTrips();
      print('TRIPS API RAW RESULT:');
      print(result);

      if (result['success']) {
        final tripsData = result['data'] as List;
        print('TRIPS API DATA LIST:');
        print(tripsData);
        _trips = tripsData.cast<Map<String, dynamic>>();
        
        // Извлекаем уникальных водителей и грузовиков для фильтров
        final driversSet = <String>{};
        final vehiclesSet = <String>{};
        
        for (final trip in _trips) {
          if (trip['driver_details'] != null) {
            final driver = trip['driver_details'] as Map<String, dynamic>;
            final driverName = '${driver['first_name'] ?? ''} ${driver['last_name'] ?? ''}'.trim();
            if (driverName.isNotEmpty) {
              driversSet.add(driverName);
            }
          }
          
          if (trip['vehicle_details'] != null) {
            final vehicle = trip['vehicle_details'] as Map<String, dynamic>;
            final vehicleInfo = '${vehicle['number'] ?? ''} (${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''})'.trim();
            if (vehicleInfo.isNotEmpty) {
              vehiclesSet.add(vehicleInfo);
            }
          }
        }
        
        _drivers = driversSet.toList()..sort();
        _vehicles = vehiclesSet.toList()..sort();
      } else {
        _error = result['error'] ?? 'Ошибка загрузки данных';
      }
    } catch (e) {
      _error = 'Ошибка загрузки данных: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Методы для работы с фильтрами
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) {
    setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
        } else {
          _selectedEndDate = picked;
        }
      });
    }
  }

  void _showDriverSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите водителя',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.clear, color: Color(0xFF6B7280)),
              title: const Text('Все водители'),
              onTap: () {
                setState(() {
                  _selectedDriver = null;
                });
                Navigator.pop(context);
              },
            ),
            ..._drivers.map((driver) => ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF2679DB)),
              title: Text(driver),
              onTap: () {
                setState(() {
                  _selectedDriver = driver;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showVehicleSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите грузовик',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.clear, color: Color(0xFF6B7280)),
              title: const Text('Все грузовики'),
              onTap: () {
      setState(() {
                  _selectedVehicle = null;
                });
                Navigator.pop(context);
              },
            ),
            ..._vehicles.map((vehicle) => ListTile(
              leading: const Icon(Icons.local_shipping, color: Color(0xFF2679DB)),
              title: Text(vehicle),
              onTap: () {
                setState(() {
                  _selectedVehicle = vehicle;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
        setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedDriver = null;
      _selectedVehicle = null;
    });
  }

  List<Map<String, dynamic>> _getFilteredTrips() {
    List<Map<String, dynamic>> filtered = List.from(_trips);

    // Фильтр по дате начала
    if (_selectedStartDate != null) {
      filtered = filtered.where((trip) {
        final plannedStartDate = trip['planned_start_date'];
        if (plannedStartDate != null) {
          final tripDate = DateTime.parse(plannedStartDate);
          return tripDate.isAfter(_selectedStartDate!) || 
                 tripDate.isAtSameMomentAs(_selectedStartDate!);
        }
        return false;
      }).toList();
    }

    // Фильтр по дате окончания
    if (_selectedEndDate != null) {
      filtered = filtered.where((trip) {
        final plannedStartDate = trip['planned_start_date'];
        if (plannedStartDate != null) {
          final tripDate = DateTime.parse(plannedStartDate);
          return tripDate.isBefore(_selectedEndDate!) || 
                 tripDate.isAtSameMomentAs(_selectedEndDate!);
        }
        return false;
      }).toList();
    }

    // Фильтр по водителю
    if (_selectedDriver != null) {
      filtered = filtered.where((trip) {
        final driverDetails = trip['driver_details'];
        if (driverDetails != null) {
          final driver = driverDetails as Map<String, dynamic>;
          final driverName = '${driver['first_name'] ?? ''} ${driver['last_name'] ?? ''}'.trim();
          return driverName == _selectedDriver;
        }
        return false;
      }).toList();
    }

    // Фильтр по грузовику
    if (_selectedVehicle != null) {
      filtered = filtered.where((trip) {
        final vehicleDetails = trip['vehicle_details'];
        if (vehicleDetails != null) {
          final vehicle = vehicleDetails as Map<String, dynamic>;
          final vehicleInfo = '${vehicle['number'] ?? ''} (${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''})'.trim();
          return vehicleInfo == _selectedVehicle;
        }
        return false;
      }).toList();
    }

    return filtered;
  }

  List<Map<String, dynamic>> _getActiveTrips() {
    final active = _trips.where((trip) =>
      trip['status'] == 'ACTIVE' || trip['status'] == 'PLANNED'
    ).toList();
    print('FLUTTER ACTIVE TRIPS IDS: ' + active.map((t) => t['id'].toString()).join(', '));
    return active;
  }

  Widget _buildCompactTripCard(Map<String, dynamic> trip) {
    final vehicleDetails = trip['vehicle_details'] as Map<String, dynamic>?;
    final driverDetails = trip['driver_details'] as Map<String, dynamic>?;
    final status = trip['status'] as String? ?? 'PLANNED';
    
    Color statusColor;
    switch (status) {
      case 'ACTIVE':
        statusColor = const Color(0xFF10B981);
        break;
      case 'COMPLETED':
        statusColor = const Color(0xFF6B7280);
        break;
      case 'PLANNED':
        statusColor = const Color(0xFF2679DB);
        break;
      default:
        statusColor = const Color(0xFF6B7280);
    }
    
    return InkWell(
      onTap: () => _showTripDetails(trip),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicleDetails?['number'] ?? 'N/A'} • ${driverDetails?['first_name'] ?? ''} ${driverDetails?['last_name'] ?? ''}'.trim(),
                          style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trip['start_address'] ?? 'N/A'} → ${trip['end_address'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
                            Text(
              DateFormat('dd.MM').format(DateTime.parse(trip['planned_start_date'] ?? DateTime.now().toIso8601String())),
              style: const TextStyle(
                                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Заезды',
        isConnected: true,
      ),
      body: Column(
        children: [
          // Вкладки
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2679DB),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF2679DB),
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Активные'),
                Tab(text: 'Все заезды'),
                Tab(text: 'График'),
              ],
            ),
          ),
          
          // Содержимое вкладок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTripsTab(),
                _buildAllTripsTab(),
                _buildScheduleTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
    );
  }

  Widget _buildActiveTripsTab() {
    final activeTrips = _getActiveTrips();
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF6B7280)),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTrips,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    
    if (activeTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
              Icons.local_shipping_outlined,
              size: 64,
                        color: Color(0xFF6B7280),
            ),
            const SizedBox(height: 16),
            const Text(
              'Нет активных заездов',
              style: TextStyle(
                fontSize: 18,
                            fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Все грузовики на базе',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeTrips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(activeTrips[index], showProgress: true);
      },
    );
  }

  Widget _buildAllTripsTab() {
    final allTrips = _getFilteredTrips();
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF6B7280)),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTrips,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allTrips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(allTrips[index]);
      },
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фильтры
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF585C5F).withOpacity(0.10),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Фильтры',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Дата "с"
                  Row(
                    children: [
                      Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                              color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedStartDate != null
                                    ? DateFormat('dd.MM.yyyy').format(_selectedStartDate!)
                                    : 'Дата с',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedStartDate != null
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                            ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                      Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                              color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedEndDate != null
                                    ? DateFormat('dd.MM.yyyy').format(_selectedEndDate!)
                                    : 'Дата по',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedEndDate != null
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                            ),
                        ),
                        ),
                      ),
                    ],
                  ),
                
                  const SizedBox(height: 12),

                // Водитель
                GestureDetector(
                  onTap: () => _showDriverSelector(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                        child: Row(
                          children: [
                            const Icon(
                          Icons.person_outline,
                          size: 16,
                              color: Color(0xFF6B7280),
                            ),
                        const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                            _selectedDriver ?? 'Все водители',
                            style: TextStyle(
                                  fontSize: 14,
                              color: _selectedDriver != null
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Грузовик
                GestureDetector(
                  onTap: () => _showVehicleSelector(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                        child: Row(
                          children: [
                            const Icon(
                          Icons.local_shipping_outlined,
                          size: 16,
                              color: Color(0xFF6B7280),
                            ),
                        const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                            _selectedVehicle ?? 'Все грузовики',
                            style: TextStyle(
                                  fontSize: 14,
                              color: _selectedVehicle != null
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Кнопка сброса
                if (_selectedStartDate != null || _selectedEndDate != null || _selectedDriver != null || _selectedVehicle != null)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _clearFilters(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Сбросить фильтры',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Результаты
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF585C5F).withOpacity(0.10),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Row(
                      children: [
                        const Icon(
                      Icons.event_note_outlined,
                      size: 20,
                      color: Color(0xFF2679DB),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Заезды по фильтрам',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Список отфильтрованных заездов
                ..._getFilteredTrips().map((trip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCompactTripCard(trip),
                )),
                
                if (_getFilteredTrips().isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_outlined,
                            size: 48,
                            color: Color(0xFF6B7280),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Заезды не найдены',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Попробуйте изменить фильтры',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, {bool showProgress = false}) {
    final vehicleDetails = trip['vehicle_details'] as Map<String, dynamic>?;
    final driverDetails = trip['driver_details'] as Map<String, dynamic>?;
    final status = trip['status'] as String? ?? 'PLANNED';
    
    Color statusColor;
    Color statusBgColor;
    String statusText;
    
    switch (status) {
      case 'ACTIVE':
        statusColor = const Color(0xFF059669);
        statusBgColor = const Color(0xFFECFDF5);
        statusText = 'В пути';
        break;
      case 'COMPLETED':
        statusColor = const Color(0xFF6B7280);
        statusBgColor = const Color(0xFFF9FAFB);
        statusText = 'Завершен';
        break;
      case 'PLANNED':
        statusColor = const Color(0xFF2563EB);
        statusBgColor = const Color(0xFFEFF6FF);
        statusText = 'Запланирован';
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusBgColor = const Color(0xFFF9FAFB);
        statusText = 'Неизвестно';
    }
          
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
        onTap: () => _showTripDetails(trip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // Основная информация
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Номер грузовика - крупно
                  Text(
                    vehicleDetails?['number'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Модель и водитель в одну строку
                              Text(
                    '${vehicleDetails?['brand'] ?? ''} ${vehicleDetails?['model'] ?? ''} • ${driverDetails?['first_name'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                  
                  const SizedBox(height: 8),
                  
                  // Маршрут
                              Text(
                    '${trip['start_address'] ?? 'N/A'} → ${trip['end_address'] ?? 'N/A'}',
                    style: const TextStyle(
                                  fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Пункт пропуска
                  Text(
                    trip['border_crossing'] ?? 'Пункт пропуска не указан',
                    style: const TextStyle(
                      fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
              
              // Статус в правом верхнем углу
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Дата в правом нижнем углу
              Positioned(
                bottom: 0,
                right: 0,
                child: Text(
                  DateFormat('dd.MM.yyyy').format(DateTime.parse(trip['planned_start_date'] ?? DateTime.now().toIso8601String())),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsScreen(trip: trip),
      ),
    );
  }
}