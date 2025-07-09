import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';
import '../components/app_header.dart';
import '../components/svg_icon.dart';
import 'trip_details_screen.dart';
import 'photo_viewer_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  final MapController _mapController = MapController();
  int _currentPhotoIndex = 0;
  bool _isLoadingFullData = false;
  Map<String, dynamic>? _fullVehicleData;
  List<dynamic> _photos = [];
  List<dynamic> _documents = [];
  List<dynamic> _trips = [];
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFullVehicleData();
    _loadCurrentLocation();
    _loadVehicleTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFullVehicleData() async {
    setState(() {
      _isLoadingFullData = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://barlau.org/api/vehicles/${widget.vehicle['id']}/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Загрузка данных грузовика ${widget.vehicle['id']}: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Данные грузовика: ${data.keys}');
        print('Фотографии в API: ${data['photos']}');
        print('Документы в API: ${data['documents']}');
        
        setState(() {
          _fullVehicleData = data;
          _photos = data['photos'] ?? [];
          _documents = data['documents'] ?? [];
          
          // Убираем пустые фотографии
          _photos = _photos.where((photo) {
            String photoUrl = photo['photo'] ?? photo['file'] ?? photo['url'] ?? '';
            return photoUrl.isNotEmpty;
          }).toList();
        });
        
        print('Загружено фотографий: ${_photos.length}');
        print('Загружено документов: ${_documents.length}');
      }
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    } finally {
      setState(() {
        _isLoadingFullData = false;
      });
    }
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final Map<String, LatLng> demoLocations = {
        'Алматы': const LatLng(43.2220, 76.8512),
        'Астана': const LatLng(51.1694, 71.4491),
        'Шымкент': const LatLng(42.3000, 69.5900),
        'Караганда': const LatLng(49.8047, 73.1094),
        'Тараз': const LatLng(42.9000, 71.3667),
      };

      final locations = demoLocations.values.toList();
      final randomIndex = widget.vehicle['id'] % locations.length;
      
      setState(() {
        _currentLocation = locations[randomIndex];
      });
    } catch (e) {
      print('Ошибка загрузки локации: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadVehicleTrips() async {
    try {
      print('Загружаем заезды для грузовика ${widget.vehicle['number']}');
      
      // Демо данные заездов (как в trips_screen.dart)
      final List<Map<String, dynamic>> allTrips = [
        {
          'id': 1,
          'vehicle': {'number': '290 ATL 01', 'model': 'DAF XF 106'},
          'driver': {'name': 'Юнус Алиев', 'phone': '+7 (777) 159 03 06'},
          'status': 'ACTIVE',
          'start_location': 'Алматы',
          'end_location': 'Астана',
          'cargo_type': 'Продукты питания',
          'cargo_volume': 15.5,
          'cargo_weight': 12000,
          'trailer_number': 'П 125 ATL 01',
          'border_crossing': 'Нур Жолы',
          'start_date': '2025-01-07T08:00:00',
          'estimated_arrival': '2025-01-07T20:00:00',
          'progress': 0.6,
          'title': 'Алматы → Астана',
          'cargo_description': 'Продукты питания, 12т',
          'planned_start_date': '2025-01-07T08:00:00',
          'start_address': 'Алматы, ул. Сейфуллина 458',
          'end_address': 'Астана, ул. Кенесары 42',
        },
        {
          'id': 2,
          'vehicle': {'number': '484 ATL 01', 'model': 'Volvo FH'},
          'driver': {'name': 'Арман Вадиев', 'phone': '+7 (777) 123 45 67'},
          'status': 'ACTIVE',
          'start_location': 'Шымкент',
          'end_location': 'Алматы',
          'cargo_type': 'Строительные материалы',
          'cargo_volume': 22.0,
          'cargo_weight': 18000,
          'trailer_number': 'П 347 ATL 01',
          'border_crossing': 'Достык',
          'start_date': '2025-01-07T06:30:00',
          'estimated_arrival': '2025-01-07T14:30:00',
          'progress': 0.8,
          'title': 'Шымкент → Алматы',
          'cargo_description': 'Строительные материалы, 18т',
          'planned_start_date': '2025-01-07T06:30:00',
          'start_address': 'Шымкент, ул. Байтурсынова 15',
          'end_address': 'Алматы, ул. Толе би 123',
        },
        {
          'id': 3,
          'vehicle': {'number': '533 ATL 01', 'model': 'Mercedes Actros'},
          'driver': {'name': 'Габит Ахметов', 'phone': '+7 (701) 234 56 78'},
          'status': 'COMPLETED',
          'start_location': 'Астана',
          'end_location': 'Караганда',
          'cargo_type': 'Электроника',
          'cargo_volume': 8.5,
          'cargo_weight': 5000,
          'trailer_number': 'П 892 ATL 01',
          'border_crossing': 'Хоргос',
          'start_date': '2025-01-06T10:00:00',
          'estimated_arrival': '2025-01-06T16:00:00',
          'progress': 1.0,
          'title': 'Астана → Караганда',
          'cargo_description': 'Электроника, 5т',
          'planned_start_date': '2025-01-06T10:00:00',
          'start_address': 'Астана, пр. Республики 24',
          'end_address': 'Караганда, ул. Ерубаева 51',
        },
        {
          'id': 4,
          'vehicle': {'number': '290 ATL 02', 'model': 'DAF XF 106'},
          'driver': {'name': 'Тест Водитель', 'phone': '+7 (700) 123 45 67'},
          'status': 'PLANNED',
          'start_location': 'Алматы',
          'end_location': 'Тараз',
          'cargo_type': 'Текстиль',
          'cargo_volume': 12.0,
          'cargo_weight': 8000,
          'trailer_number': 'П 456 ATL 02',
          'border_crossing': 'Кордай',
          'start_date': '2025-01-08T09:00:00',
          'estimated_arrival': '2025-01-08T15:00:00',
          'progress': 0.0,
          'title': 'Алматы → Тараз',
          'cargo_description': 'Текстиль, 8т',
          'planned_start_date': '2025-01-08T09:00:00',
          'start_address': 'Алматы, ул. Макатаева 127',
          'end_address': 'Тараз, ул. Толе би 45',
        },
        {
          'id': 5,
          'vehicle': {'number': '533 ATL 01', 'model': 'Mercedes Actros'},
          'driver': {'name': 'Габит Ахметов', 'phone': '+7 (701) 234 56 78'},
          'status': 'COMPLETED',
          'start_location': 'Караганда',
          'end_location': 'Алматы',
          'cargo_type': 'Металлопрокат',
          'cargo_volume': 18.0,
          'cargo_weight': 15000,
          'trailer_number': 'П 892 ATL 01',
          'border_crossing': null,
          'start_date': '2025-01-05T07:00:00',
          'estimated_arrival': '2025-01-05T19:00:00',
          'progress': 1.0,
          'title': 'Караганда → Алматы',
          'cargo_description': 'Металлопрокат, 15т',
          'planned_start_date': '2025-01-05T07:00:00',
          'start_address': 'Караганда, ул. Промышленная 8',
          'end_address': 'Алматы, ул. Индустриальная 22',
        },
        {
          'id': 6,
          'vehicle': {'number': '290 ATL 01', 'model': 'DAF XF 106'},
          'driver': {'name': 'Юнус Алиев', 'phone': '+7 (777) 159 03 06'},
          'status': 'COMPLETED',
          'start_location': 'Астана',
          'end_location': 'Алматы',
          'cargo_type': 'Продукты питания',
          'cargo_volume': 20.0,
          'cargo_weight': 14000,
          'trailer_number': 'П 125 ATL 01',
          'border_crossing': null,
          'start_date': '2025-01-04T09:00:00',
          'estimated_arrival': '2025-01-04T21:00:00',
          'progress': 1.0,
          'title': 'Астана → Алматы',
          'cargo_description': 'Продукты питания, 14т',
          'planned_start_date': '2025-01-04T09:00:00',
          'start_address': 'Астана, ул. Сарыарка 15',
          'end_address': 'Алматы, ул. Райымбека 348',
        },
      ];
      
      // Фильтруем заезды по номеру грузовика
      final vehicleNumber = widget.vehicle['number'];
      final filteredTrips = allTrips.where((trip) => 
        trip['vehicle']['number'] == vehicleNumber
      ).toList();
      
      setState(() {
        _trips = filteredTrips;
      });
      
      print('Загружено заездов для $vehicleNumber: ${_trips.length}');
      for (var trip in _trips) {
        print('- ${trip['title']} (${trip['status']})');
      }
    } catch (e) {
      print('Ошибка загрузки заездов: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _fullVehicleData ?? widget.vehicle;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehicle['number'] ?? 'Не указан',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              '${vehicle['brand'] ?? 'Не указано'} ${vehicle['model'] ?? ''}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          _buildStatusBadge(vehicle['status']),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Основное'),
                Tab(text: 'Документы'),
                Tab(text: 'Заезды'),
              ],
            ),
          ),
          
          // Содержимое вкладок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMainTab(vehicle),
                _buildDocumentsTab(),
                _buildTripsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'ACTIVE':
        statusColor = const Color(0xFF10B981);
        statusText = 'Активен';
        break;
      case 'INACTIVE':
        statusColor = const Color(0xFF6B7280);
        statusText = 'Неактивен';
        break;
      case 'MAINTENANCE':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'На ТО';
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusText = 'Неизвестно';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildMainTab(Map<String, dynamic> vehicle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Основная информация
          _buildInfoCard(
            'Основная информация',
            [
              _buildInfoRow('Номер', vehicle['number'] ?? 'Не указан'),
              _buildInfoRow('Марка', vehicle['brand'] ?? 'Не указано'),
              _buildInfoRow('Модель', vehicle['model'] ?? 'Не указано'),
              _buildInfoRow('Год выпуска', vehicle['year']?.toString() ?? 'Не указан'),
              _buildInfoRow('Цвет', vehicle['color'] ?? 'Не указан'),
              _buildInfoRow('Водитель', vehicle['driver_name'] ?? 'Не назначен'),
              _buildInfoRow('Тип транспорта', vehicle['vehicle_type_display'] ?? 'Не указано'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Карта с GPS
          _buildMapCard(),
          
          const SizedBox(height: 16),
          
          // Технические характеристики
          _buildInfoCard(
            'Технические характеристики',
            [
              _buildInfoRow('VIN номер', vehicle['vin_number'] ?? 'Не указан'),
              _buildInfoRow('Номер двигателя', vehicle['engine_number'] ?? 'Не указан'),
              _buildInfoRow('Номер шасси', vehicle['chassis_number'] ?? 'Не указан'),
              _buildInfoRow('Объем двигателя', 
                vehicle['engine_capacity'] != null 
                    ? '${vehicle['engine_capacity']} л' 
                    : 'Не указан'),
              _buildInfoRow('Тип топлива', vehicle['fuel_type_display'] ?? 'Не указано'),
              _buildInfoRow('Расход топлива', 
                vehicle['fuel_consumption'] != null 
                    ? '${vehicle['fuel_consumption']} л/100км' 
                    : 'Не указан'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Габариты и масса
          _buildInfoCard(
            'Габариты и масса',
            [
              _buildInfoRow('Длина', 
                vehicle['length'] != null ? '${vehicle['length']} м' : 'Не указана'),
              _buildInfoRow('Ширина', 
                vehicle['width'] != null ? '${vehicle['width']} м' : 'Не указана'),
              _buildInfoRow('Высота', 
                vehicle['height'] != null ? '${vehicle['height']} м' : 'Не указана'),
              _buildInfoRow('Максимальная масса', 
                vehicle['max_weight'] != null 
                    ? '${vehicle['max_weight']} кг' 
                    : 'Не указана'),
              _buildInfoRow('Грузоподъемность', 
                vehicle['cargo_capacity'] != null 
                    ? '${vehicle['cargo_capacity']} кг' 
                    : 'Не указано'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_documents.isEmpty && _photos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 80,
                    color: Color(0xFFE5E7EB),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Документы и фотографии',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Документы и фотографии этого грузовика\nпока не загружены в систему',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (_documents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: Color(0xFFE5E7EB),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Документы не загружены',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._documents.map((doc) => _buildDocumentCard(doc)),
            
            // Галерея фотографий
            if (_photos.isNotEmpty) 
              _buildPhotosGallery()
            else if (_documents.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: Color(0xFFE5E7EB),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Фотографии не загружены',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripsTab() {
    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.route_outlined,
              size: 64,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(height: 16),
            const Text(
              'История заездов',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'У этого грузовика пока нет\nзаписей о поездках',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(_trips[index]);
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Текущее местоположение',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2679DB)),
                    ),
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: _currentLocation != null
                  ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation!,
                        initialZoom: 12.0,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'kz.barlau.mobile',
                          maxZoom: 19,
                          retinaMode: RetinaMode.isHighDensity(context),
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation!,
                              width: 50,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2679DB),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_shipping,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 32,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Местоположение недоступно',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF585C5F).withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2679DB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description,
              size: 24,
              color: Color(0xFF2679DB),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['document_type_display'] ?? 'Документ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (document['number'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '№${document['number']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                if (document['issue_date'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'от ${document['issue_date']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (document['file'] != null)
            GestureDetector(
              onTap: () => _openDocument(document['file']),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2679DB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.open_in_new,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotosGallery() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
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
          Text(
            'Галерея фотографий (${_photos.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final photo = _photos[index];
              String photoUrl = photo['photo'] ?? photo['file'] ?? photo['url'] ?? '';
              if (photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
                photoUrl = 'https://barlau.org$photoUrl';
              }
              
              return GestureDetector(
                onTap: () => _showPhotoViewer(photoUrl, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Color(0xFF9CA3AF),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(
                            Icons.image,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final vehicle = trip['vehicle'] as Map<String, dynamic>;
    final driver = trip['driver'] as Map<String, dynamic>;
    final status = trip['status'] as String;
    
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
      margin: const EdgeInsets.only(bottom: 16),
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
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              // Основная информация
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Номер грузовика - крупно
                  Text(
                    vehicle['number'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Модель и водитель в одну строку
                  Text(
                    '${vehicle['model']} • ${driver['name'].split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Маршрут
                  Text(
                    '${trip['start_location']} → ${trip['end_location']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
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
                  DateFormat('dd.MM.yyyy').format(DateTime.parse(trip['start_date'])),
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

  void _showPhotoViewer(String photoUrl, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          photos: _photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '—';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _openDocument(String documentUrl) async {
    String fullUrl = documentUrl;
    if (!fullUrl.startsWith('http')) {
      fullUrl = 'https://barlau.org$fullUrl';
    }
    
    // Определяем тип документа по расширению
    String extension = fullUrl.split('.').last.toLowerCase();
    
    if (extension == 'pdf') {
      // Открываем PDF в встроенном viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _DocumentViewerScreen(
            url: fullUrl,
            title: 'Документ PDF',
          ),
        ),
      );
    } else {
      // Для других типов файлов открываем в браузере
      try {
        final Uri uri = Uri.parse(fullUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удалось открыть документ'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Встроенный PDF viewer
class _DocumentViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const _DocumentViewerScreen({
    required this.url,
    required this.title,
  });

  @override
  State<_DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<_DocumentViewerScreen> {
  bool _isLoading = true;
  WebViewController? _controller;
  String? _viewerUrl;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() async {
    try {
      final encodedUrl = Uri.encodeComponent(widget.url);
      _viewerUrl = 'https://docs.google.com/viewer?url=$encodedUrl&embedded=true';
      
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (error) {
              print('Ошибка WebView: ${error.description}');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        );
      
      if (_viewerUrl != null) {
        await _controller!.loadRequest(Uri.parse(_viewerUrl!));
      }
    } catch (e) {
      print('Ошибка инициализации WebView: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Color(0xFF2679DB)),
            onPressed: () async {
              try {
                final Uri uri = Uri.parse(widget.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                print('Ошибка открытия в браузере: $e');
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: Stack(
        children: [
          // PDF через Google Docs Viewer
          if (_controller != null && _viewerUrl != null)
            Container(
              width: double.infinity,
              height: double.infinity,
              child: WebViewWidget(controller: _controller!),
            )
          else
            const Center(
              child: Text(
                'Не удалось загрузить документ',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          
          // Индикатор загрузки
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF2679DB),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Загрузка документа...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 
