import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/wialon_service.dart';
import '../components/app_header.dart';

class TrackersScreen extends StatefulWidget {
  const TrackersScreen({super.key});

  @override
  State<TrackersScreen> createState() => _TrackersScreenState();
}

class _TrackersScreenState extends State<TrackersScreen> {
  final WialonService _wialonService = WialonService();
  List<WialonTracker> _trackers = [];
  bool _isLoading = false;
  String? _errorMessage;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadTrackers();
  }

  Future<void> _loadTrackers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📡 Загружаем GPS трекеры...');
      
      // Получаем токен авторизации
      final token = await _wialonService.getAuthToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Не удалось получить доступ к GPS трекерам';
          _isLoading = false;
        });
        return;
      }

      // Получаем список трекеров
      final trackersData = await _wialonService.getAllTrackersWithStatus();
      if (trackersData != null) {
        final trackers = trackersData.map((data) => WialonTracker.fromJson(data)).toList();
        
        setState(() {
          _trackers = trackers;
          _isLoading = false;
        });
        
        print('✅ Загружено трекеров: ${trackers.length}');
      } else {
        setState(() {
          _errorMessage = 'Не удалось загрузить данные трекеров';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Ошибка загрузки трекеров: $e');
      setState(() {
        _errorMessage = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  void _showTrackerDetails(WialonTracker tracker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: tracker.isOnline ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tracker.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tracker.isOnline ? 'Онлайн' : 'Оффлайн',
                          style: TextStyle(
                            color: tracker.isOnline ? Colors.green : Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Детали трекера
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(
                      title: 'Местоположение',
                      content: tracker.latitude != null && tracker.longitude != null
                          ? '${tracker.latitude!.toStringAsFixed(6)}, ${tracker.longitude!.toStringAsFixed(6)}'
                          : 'Не определено',
                      icon: Icons.location_on,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoCard(
                      title: 'Скорость',
                      content: tracker.speed != null
                          ? '${tracker.speed!.toStringAsFixed(1)} км/ч'
                          : 'Не определена',
                      icon: Icons.speed,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoCard(
                      title: 'Последнее сообщение',
                      content: tracker.lastMessageTime != null
                          ? _formatDateTime(tracker.lastMessageTime!)
                          : 'Нет данных',
                      icon: Icons.access_time,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Кнопки действий
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: tracker.latitude != null && tracker.longitude != null
                                ? () => _showOnMap(tracker)
                                : null,
                            icon: const Icon(Icons.map),
                            label: const Text('Показать на карте'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2679DB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showRouteHistory(tracker),
                            icon: const Icon(Icons.history),
                            label: const Text('История'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2679DB), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOnMap(WialonTracker tracker) {
    Navigator.pop(context); // Закрываем модальное окно
    
    if (tracker.latitude != null && tracker.longitude != null) {
      _mapController.move(
        LatLng(tracker.latitude!, tracker.longitude!),
        15.0,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Карта перемещена к трекеру ${tracker.name}'),
          backgroundColor: const Color(0xFF2679DB),
        ),
      );
    }
  }

  void _showRouteHistory(WialonTracker tracker) {
    // TODO: Реализовать показ истории маршрута
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('История маршрута для ${tracker.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} дн назад';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'GPS Трекеры'),
      body: Column(
        children: [
          // Карта
          Expanded(
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(43.238949, 76.889709), // Алматы
                initialZoom: 10.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.barlau.app',
                ),
                // Маркеры трекеров
                MarkerLayer(
                  markers: _trackers
                      .where((tracker) => tracker.latitude != null && tracker.longitude != null)
                      .map((tracker) => Marker(
                            point: LatLng(tracker.latitude!, tracker.longitude!),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showTrackerDetails(tracker),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: tracker.isOnline ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          
          // Список трекеров
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Заголовок списка
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text(
                          'Трекеры',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _loadTrackers,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                  
                  // Список
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadTrackers,
                                      child: const Text('Повторить'),
                                    ),
                                  ],
                                ),
                              )
                            : _trackers.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.gps_off,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Трекеры не найдены',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: _trackers.length,
                                    itemBuilder: (context, index) {
                                      final tracker = _trackers[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: ListTile(
                                          leading: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: tracker.isOnline ? Colors.green : Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          title: Text(
                                            tracker.name,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            tracker.isOnline ? 'Онлайн' : 'Оффлайн',
                                            style: TextStyle(
                                              color: tracker.isOnline ? Colors.green : Colors.red,
                                            ),
                                          ),
                                          trailing: tracker.lastMessageTime != null
                                              ? Text(
                                                  _formatDateTime(tracker.lastMessageTime!),
                                                  style: const TextStyle(fontSize: 12),
                                                )
                                              : null,
                                          onTap: () => _showTrackerDetails(tracker),
                                        ),
                                      );
                                    },
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
