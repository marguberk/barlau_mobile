import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../components/app_header.dart';
import '../components/svg_icon.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final MapController _mapController = MapController();
  bool _isFullScreen = false;
  
  // OpenRouteService API Key (тот же что в веб-версии)
  static const String _orsApiKey = '5b3ce3597851110001cf624837a2d1abb30640ba92c5c16d57e75087';
  
  // Реальный маршрут по дорогам
  List<LatLng> _realRoutePoints = [];
  bool _isLoadingRoute = false;
  
  // Базовые точки маршрута
  List<LatLng> _routePoints = [];
  
  // Координаты для демо маршрута
  final Map<String, LatLng> _cityCoordinates = {
    'Алматы': const LatLng(43.2220, 76.8512),
    'Астана': const LatLng(51.1694, 71.4491),
    'Шымкент': const LatLng(42.3000, 69.5900),
    'Караганда': const LatLng(49.8047, 73.1094),
    'Тараз': const LatLng(42.9000, 71.3667),
  };

  @override
  void initState() {
    super.initState();
    
    // Инициализируем базовые точки маршрута
    _routePoints = _getRoutePoints();
    
    // Загружаем реальный маршрут при инициализации
    _loadRealRoute();
    
    // Центрируем карту на маршруте с небольшой задержкой
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToRoute();
    });
  }

  LatLng _getCoordinates(String cityName) {
    return _cityCoordinates[cityName] ?? const LatLng(43.2220, 76.8512);
  }

  List<LatLng> _getRoutePoints() {
    final startLocation = widget.trip['start_location'] as String;
    final endLocation = widget.trip['end_location'] as String;
    
    final startCoords = _getCoordinates(startLocation);
    final endCoords = _getCoordinates(endLocation);
    
    // Создаем простой маршрут из точки А в точку Б
    // В реальном приложении здесь будет API для построения маршрута
    return [startCoords, endCoords];
  }

  LatLng _getCurrentPosition() {
    final routePoints = _getRoutePoints();
    if (routePoints.length < 2) return routePoints.first;
    
    final progress = widget.trip['progress'] as double;
    final start = routePoints.first;
    final end = routePoints.last;
    
    // Интерполяция позиции на основе прогресса
    final lat = start.latitude + (end.latitude - start.latitude) * progress;
    final lng = start.longitude + (end.longitude - start.longitude) * progress;
    
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.trip['vehicle'] as Map<String, dynamic>;
    final driver = widget.trip['driver'] as Map<String, dynamic>;
    final status = widget.trip['status'] as String;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'ACTIVE':
        statusColor = const Color(0xFF10B981);
        statusText = 'В пути';
        statusIcon = Icons.local_shipping;
        break;
      case 'COMPLETED':
        statusColor = const Color(0xFF6B7280);
        statusText = 'Завершен';
        statusIcon = Icons.check_circle;
        break;
      case 'PLANNED':
        statusColor = const Color(0xFF2679DB);
        statusText = 'Запланирован';
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusText = 'Неизвестно';
        statusIcon = Icons.help;
    }

    final routePoints = _routePoints;
    final currentPosition = status == 'ACTIVE' ? _getCurrentPosition() : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Заезд #${widget.trip['id']}',
        isConnected: true,
        showBackButton: true,
        showNotificationIcon: false,
        showProfileIcon: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация
            Container(
              margin: const EdgeInsets.all(16),
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
                    color: const Color(0xFF000000).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок с статусом
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vehicle['number']} • ${vehicle['model']}',
                              style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Водитель: ${driver['name']}',
                              style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
    fontFamily: 'SF Pro Display',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Основная информация в едином стиле
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Маршрут', '${widget.trip['start_location']} → ${widget.trip['end_location']}'),
                        const SizedBox(height: 16),
                        _buildInfoRow('Время отправления', DateFormat('dd.MM.yyyy в HH:mm').format(DateTime.parse(widget.trip['start_date']))),
                        const SizedBox(height: 16),
                        _buildInfoRow('Груз', widget.trip['cargo_type']),
                        const SizedBox(height: 8),
                        _buildInfoSubtext('Объем: ${widget.trip['cargo_volume']} м³ • Вес: ${NumberFormat('#,###').format(widget.trip['cargo_weight'])} кг'),
                        const SizedBox(height: 16),
                        _buildInfoRow('Номер прицепа', widget.trip['trailer_number'] ?? 'Не указан'),
                        const SizedBox(height: 16),
                        _buildInfoRow('Пункт пропуска', widget.trip['border_crossing'] ?? 'Не указан'),
                      ],
                    ),
                  ),
                  
                  // Прогресс для активных заездов
                  if (status == 'ACTIVE') ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2679DB).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2679DB).withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Прогресс поездки',
                                style: TextStyle(
    fontFamily: 'SF Pro Display',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(widget.trip['progress'] * 100).round()}%',
                                style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2679DB),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: widget.trip['progress'],
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2679DB),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Карта с маршрутом
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF585C5F).withOpacity(0.10),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                    spreadRadius: -12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Карта
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: routePoints.isNotEmpty ? routePoints.first : const LatLng(43.2220, 76.8512),
                        initialZoom: 6.0,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        // Слой карты - тот же стиль что в старом экране карты
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'kz.barlau.mobile',
                          maxZoom: 19,
                          retinaMode: RetinaMode.isHighDensity(context),
                        ),
                        
                        // Маршрут - тот же стиль что в старом экране карты
                        if (_realRoutePoints.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _realRoutePoints,
                                color: const Color(0xFF2563EB), // Тот же цвет что в старом экране
                                strokeWidth: 6.0,
                                borderColor: Colors.white,
                                borderStrokeWidth: 1.0,
                              ),
                            ],
                          ),
                        
                        // Маркеры - тот же стиль что в старом экране карты
                        MarkerLayer(
                          markers: [
                            // Начальная точка - синий круг как в старом экране
                            if (routePoints.isNotEmpty)
                              Marker(
                                point: routePoints.first,
                                width: 20,
                                height: 20,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withOpacity(0.2),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Конечная точка - зеленый круг как в старом экране
                            if (routePoints.length >= 2)
                              Marker(
                                point: routePoints.last,
                                width: 20,
                                height: 20,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF34D399),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF34D399).withOpacity(0.2),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Текущая позиция для активных заездов - грузовик как раньше
                            if (currentPosition != null)
                              Marker(
                                point: currentPosition,
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
                    ),
                    
                    // Индикатор загрузки маршрута
                    if (_isLoadingRoute)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2679DB)),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Загрузка маршрута...',
                                style: TextStyle(
    fontFamily: 'SF Pro Display',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Кнопка полноэкранного просмотра
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => _showFullScreenMap(),
                          child: const Icon(
                            Icons.fullscreen,
                            size: 20,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                    
                    // Кнопка центрирования карты
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => _fitMapToRoute(),
                          child: const Icon(
                            Icons.center_focus_strong,
                            size: 20,
                            color: Color(0xFF2679DB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Контакты
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                    'Контакты',
                    style: TextStyle(
    fontFamily: 'SF Pro Display',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Водитель
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2679DB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person,
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
                              driver['name'],
                              style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              driver['phone'],
                              style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Звонок водителю
                        },
                        icon: const Icon(
                          Icons.phone,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _centerMap() {
    if (widget.trip['status'] == 'ACTIVE') {
      // Центрируем на текущей позиции
      final currentPos = _getCurrentPosition();
      _mapController.move(currentPos, 10.0);
    } else {
      // Центрируем на весь маршрут
      final routePoints = _getRoutePoints();
      if (routePoints.isNotEmpty) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(routePoints),
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    }
  }

  void _showFullScreenMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMapScreen(
          trip: widget.trip,
          routePoints: _routePoints,
          realRoutePoints: _realRoutePoints, // Передаем реальный маршрут
          currentPosition: widget.trip['status'] == 'ACTIVE' ? _getCurrentPosition() : null,
        ),
      ),
    );
  }

  // Точная копия функции fetchRouteORS из старого экрана карты
  Future<Map<String, dynamic>?> _fetchRouteORS(LatLng start, LatLng end) async {
    const url = 'https://api.openrouteservice.org/v2/directions/driving-car/geojson';
    
    final body = {
      'coordinates': [
        [start.longitude, start.latitude], // ORS использует [lng, lat]
        [end.longitude, end.latitude]
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': _orsApiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('ORS API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Ошибка получения маршрута: $e');
    }
    
    return null;
  }
  
  // Загружаем реальный маршрут по дорогам
  Future<void> _loadRealRoute() async {
    if (_routePoints.length < 2) return;
    
    setState(() {
      _isLoadingRoute = true;
    });
    
    final start = _routePoints.first;
    final end = _routePoints.last;
    
    // Получаем маршрут по дорогам через OpenRouteService
    final geojson = await _fetchRouteORS(start, end);
    
    if (geojson != null && 
        geojson['features'] != null && 
        geojson['features'].isNotEmpty &&
        geojson['features'][0]['geometry'] != null) {
      
      final coordinates = geojson['features'][0]['geometry']['coordinates'] as List;
      final routePoints = coordinates.map<LatLng>((coord) => 
        LatLng(coord[1].toDouble(), coord[0].toDouble())
      ).toList();

      setState(() {
        _realRoutePoints = routePoints;
        _isLoadingRoute = false;
      });
      
      // Центрируем карту на новом маршруте
      _fitMapToRoute();
    } else {
      // Fallback: используем прямую линию
      setState(() {
        _realRoutePoints = _routePoints;
        _isLoadingRoute = false;
      });
    }
  }

  void _fitMapToRoute() {
    if (_realRoutePoints.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_realRoutePoints),
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

     Widget _buildInfoRow(String title, String content) {
     return Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         SizedBox(
           width: 120,
           child: Text(
             title,
             style: const TextStyle(
    fontFamily: 'SF Pro Display',
               fontSize: 14,
               fontWeight: FontWeight.w500,
               color: Color(0xFF6B7280),
             ),
           ),
         ),
         Expanded(
           child: Text(
             content,
             style: const TextStyle(
    fontFamily: 'SF Pro Display',
               fontSize: 14,
               fontWeight: FontWeight.w600,
               color: Color(0xFF111827),
             ),
           ),
         ),
       ],
     );
   }
 
   Widget _buildInfoSubtext(String text) {
     return Padding(
       padding: const EdgeInsets.only(left: 120),
       child: Text(
         text,
         style: const TextStyle(
    fontFamily: 'SF Pro Display',
           fontSize: 13,
           color: Color(0xFF9CA3AF),
         ),
       ),
     );
   }
}

// Полноэкранная карта
class FullScreenMapScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  final List<LatLng> routePoints;
  final List<LatLng> realRoutePoints; // Добавляем реальный маршрут
  final LatLng? currentPosition;

  const FullScreenMapScreen({
    super.key,
    required this.trip,
    required this.routePoints,
    required this.realRoutePoints, // Добавляем реальный маршрут
    this.currentPosition,
  });

  @override
  State<FullScreenMapScreen> createState() => _FullScreenMapScreenState();
}

class _FullScreenMapScreenState extends State<FullScreenMapScreen> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Центрируем карту на маршруте с небольшой задержкой
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToRoute();
    });
  }
  
  void _fitMapToRoute() {
    final routeToFit = widget.realRoutePoints.isNotEmpty ? widget.realRoutePoints : widget.routePoints;
    if (routeToFit.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(routeToFit),
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeToShow = widget.realRoutePoints.isNotEmpty ? widget.realRoutePoints : widget.routePoints;
    
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: routeToShow.isNotEmpty ? routeToShow.first : const LatLng(43.2220, 76.8512),
              initialZoom: 8.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Слой карты - тот же стиль что в старом экране карты
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'kz.barlau.mobile',
                maxZoom: 19,
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              
              // Маршрут - тот же стиль что в старом экране карты
              if (routeToShow.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeToShow,
                      color: const Color(0xFF2563EB), // Тот же цвет что в старом экране
                      strokeWidth: 8.0, // Немного толще для полноэкранного режима
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
              
              // Маркеры - тот же стиль что в старом экране карты
              MarkerLayer(
                markers: [
                  // Начальная точка - синий круг как в старом экране
                  if (widget.routePoints.isNotEmpty)
                    Marker(
                      point: widget.routePoints.first,
                      width: 30, // Больше для полноэкранного режима
                      height: 30,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Конечная точка - зеленый круг как в старом экране
                  if (widget.routePoints.length >= 2)
                    Marker(
                      point: widget.routePoints.last,
                      width: 30, // Больше для полноэкранного режима
                      height: 30,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF34D399).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Текущая позиция для активных заездов - грузовик как раньше
                  if (widget.currentPosition != null)
                    Marker(
                      point: widget.currentPosition!,
                      width: 70,
                      height: 70,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2679DB),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: Colors.white, width: 5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Кнопка закрытия
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close,
                  size: 24,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          
          // Информация о заезде
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Заезд #${widget.trip['id']}',
                    style: const TextStyle(
    fontFamily: 'SF Pro Display',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.trip['start_location']} → ${widget.trip['end_location']}',
                    style: const TextStyle(
    fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2679DB),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.trip['vehicle']['number']} • ${widget.trip['driver']['name']}',
                    style: const TextStyle(
    fontFamily: 'SF Pro Display',
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
    );
  }
} 