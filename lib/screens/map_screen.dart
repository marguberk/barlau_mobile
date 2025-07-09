import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../components/app_header.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String? _selectedTripId;
  List<Polyline> _tripPolylines = [];
  List<Marker> _tripMarkers = [];
  
  // OpenRouteService API Key (тот же что в веб-версии)
  static const String _orsApiKey = '5b3ce3597851110001cf624837a2d1abb30640ba92c5c16d57e75087';
  
  // Список поездок с реальными координатами из веб-версии
  final List<Map<String, dynamic>> _trips = [
    {
      'id': 'TRIP-001',
      'vehicle': 'VOLVO FH 460',
      'number': '484 ATL 01',
      'route': 'Жаркент — Хоргос',
      'driver': 'Асылбек Нурланов',
      'status': 'В пути',
      'statusColor': const Color(0xFF2679DB),
      'start_latitude': 44.1661,
      'start_longitude': 80.0058,
      'end_latitude': 44.2086,
      'end_longitude': 80.4264,
      'start_address': 'Жаркент, Казахстан',
      'end_address': 'Хоргос, Казахстан',
      'vehicle_details': {
        'brand': 'VOLVO',
        'model': 'FH 460',
        'number': '484 ATL 01',
      }
    },
    {
      'id': 'TRIP-002',
      'vehicle': 'Mercedes Actros 420',
      'number': 'А123БВ45',
      'route': 'Алматы — Шымкент',
      'driver': 'Максат Ержанов',
      'status': 'Ожидание',
      'statusColor': const Color(0xFFF59E0B),
      'start_latitude': 43.2220,
      'start_longitude': 76.8512,
      'end_latitude': 42.3000,
      'end_longitude': 69.6000,
      'start_address': 'Алматы, Казахстан',
      'end_address': 'Шымкент, Казахстан',
      'vehicle_details': {
        'brand': 'Mercedes',
        'model': 'Actros 420',
        'number': 'А123БВ45',
      }
    },
  ];

  // Список грузовиков для создания поездок
  final List<Map<String, dynamic>> _availableVehicles = [
    {'number': 'КАЗ 789 ABC 02', 'model': 'VOLVO FH 460'},
    {'number': 'КАЗ 456 DEF 02', 'model': 'Mercedes Actros 420'},
    {'number': 'КАЗ 123 GHI 02', 'model': 'SCANIA R 450'},
  ];

  @override
  void initState() {
    super.initState();
    // Инициализируем карту и загружаем маршруты
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  void _initializeMap() {
    // Центрируем карту на Алматы как в веб-версии
    _mapController.move(LatLng(43.2220, 76.8512), 11.0);
    // Загружаем и отображаем маршруты поездок
    _renderTripRoutes(_trips);
  }

  // Точная копия функции fetchRouteORS из веб-версии
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
      }
    } catch (e) {
      print('Ошибка получения маршрута: $e');
    }
    
    return null;
  }

  // Точная копия функции renderTripRoutes из веб-версии
  Future<void> _renderTripRoutes(List<Map<String, dynamic>> trips) async {
    // Очищаем старые маршруты
    setState(() {
      _tripPolylines.clear();
      _tripMarkers.clear();
    });

    LatLngBounds? routeBounds;

    for (final trip in trips) {
      if (trip['start_latitude'] != null && trip['end_latitude'] != null) {
        final start = LatLng(
          trip['start_latitude'].toDouble(),
          trip['start_longitude'].toDouble(),
        );
        final end = LatLng(
          trip['end_latitude'].toDouble(),
          trip['end_longitude'].toDouble(),
        );

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

          // Создаем полилинию маршрута (точно как в веб-версии)
          final polyline = Polyline(
            points: routePoints,
            color: const Color(0xFF2563EB), // Тот же цвет что в веб-версии
            strokeWidth: 6.0,
            borderColor: Colors.white,
            borderStrokeWidth: 1.0,
          );

          // Создаем маркеры начала и конца (точно как в веб-версии)
          final startMarker = Marker(
            point: start,
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
          );

          final endMarker = Marker(
            point: end,
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
          );

          setState(() {
            _tripPolylines.add(polyline);
            _tripMarkers.addAll([startMarker, endMarker]);
          });

          // Сохраняем границы маршрута для фокусировки
          if (trips.length == 1) {
            routeBounds = LatLngBounds.fromPoints(routePoints);
          }
        } else {
          // Fallback: прямая линия (как в веб-версии)
          final fallbackPolyline = Polyline(
            points: [start, end],
            color: const Color(0xFFF87171),
            strokeWidth: 5.0,
          );

          setState(() {
            _tripPolylines.add(fallbackPolyline);
          });

          if (trips.length == 1) {
            routeBounds = LatLngBounds.fromPoints([start, end]);
          }
        }
      }
    }

    // Автоматический фокус на маршруте если это единственная поездка
    if (trips.length == 1 && routeBounds != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: routeBounds!,
            padding: const EdgeInsets.only(
              top: 40,
              left: 40,
              right: 40,
              bottom: 200, // Больше отступ снизу чтобы маршрут не закрывался панелью
            ),
            maxZoom: 13,
          ),
        );
      });
    }
  }

  void _selectTrip(String tripId) {
    setState(() {
      _selectedTripId = tripId;
    });
    
    // Находим выбранную поездку и фокусируемся на ней
    final trip = _trips.firstWhere((t) => t['id'] == tripId);
    _renderTripRoutes([trip]); // Показываем только выбранную поездку
  }

  void _showCreateTripDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedVehicle;
        String? startCity;
        String? endCity;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Создать поездку',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Выберите грузовик',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: selectedVehicle,
                    items: _availableVehicles.map((vehicle) {
                      return DropdownMenuItem<String>(
                        value: vehicle['number'],
                        child: Text('${vehicle['number']} (${vehicle['model']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedVehicle = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Откуда',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: startCity,
                    items: const [
                      DropdownMenuItem<String>(value: 'Алматы', child: Text('Алматы')),
                      DropdownMenuItem<String>(value: 'Жаркент', child: Text('Жаркент')),
                      DropdownMenuItem<String>(value: 'Шымкент', child: Text('Шымкент')),
                      DropdownMenuItem<String>(value: 'Астана', child: Text('Астана')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        startCity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Куда',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: endCity,
                    items: const [
                      DropdownMenuItem<String>(value: 'Хоргос', child: Text('Хоргос')),
                      DropdownMenuItem<String>(value: 'Алматы', child: Text('Алматы')),
                      DropdownMenuItem<String>(value: 'Шымкент', child: Text('Шымкент')),
                      DropdownMenuItem<String>(value: 'Астана', child: Text('Астана')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        endCity = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedVehicle != null && startCity != null && endCity != null
                      ? () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Поездка создана!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2679DB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: 'Карта и поездки',
        isConnected: true, // Карта всегда подключена
      ),
      body: Stack(
        children: [
          // Полноэкранная карта с тем же стилем что в веб-версии
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(43.2220, 76.8512), // Алматы как в веб-версии
              initialZoom: 11.0,
              minZoom: 5.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Тот же тайл-слой что в веб-версии
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'kz.barlau.mobile',
                maxZoom: 19,
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              // Полилинии маршрутов
              PolylineLayer(polylines: _tripPolylines),
              // Маркеры начала и конца
              MarkerLayer(markers: _tripMarkers),
            ],
          ),
          
          // Элементы управления картой (как в веб-версии)
          Positioned(
            top: 60,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                    icon: const Icon(Icons.add),
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                    icon: const Icon(Icons.remove),
                    color: const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          
          // Нижняя панель с поездками (как в веб-версии)
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Индикатор перетаскивания
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Заголовок с кнопкой создания
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Поездки',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2679DB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_trips.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2679DB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _showCreateTripDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Создать'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2679DB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Список поездок
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _trips.length,
                        itemBuilder: (context, index) {
                          final trip = _trips[index];
                          final isSelected = trip['id'] == _selectedTripId;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF2679DB) 
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () => _selectTrip(trip['id']),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // SVG заглушка грузовика (как в веб-версии)
                                    Container(
                                      width: 90,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.local_shipping,
                                        color: Color(0xFF6B7280),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Информация о поездке
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            trip['vehicle_details']['brand'] + ' ' + trip['vehicle_details']['model'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            trip['vehicle_details']['number'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            trip['route'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Статус
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: trip['statusColor'].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        trip['status'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: trip['statusColor'],
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
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 
 
 